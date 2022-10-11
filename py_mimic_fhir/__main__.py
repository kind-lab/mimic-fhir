import argparse
import os
import sys
from datetime import datetime
import logging
import pandas as pd
from pathlib import Path

from py_mimic_fhir.validate import validate_n_patients, multiprocess_validate, revalidate_bad_bundles
from py_mimic_fhir.io import export_all_resources
from py_mimic_fhir.terminology import generate_all_terminology, post_terminology
from py_mimic_fhir.config import MimicArgs, GoogleArgs, PatientEverythingArgs
from py_mimic_fhir.db import MFDatabaseConnection

logger = logging.getLogger(__name__)


class EnvDefault(argparse.Action):
    """Argument parser class which inherits from environment and has a default value."""
    def __init__(self, envvar, required=True, default=None, **kwargs):
        if not default and envvar:
            if envvar in os.environ:
                default = os.environ[envvar]
        if required and default:
            required = False
        super(EnvDefault,
              self).__init__(default=default, required=required, **kwargs)

    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, values)


def dir_path(string):
    return Path(string)


def parse_arguments(arguments=None):
    """Parse input arguments for entry points."""
    parser = argparse.ArgumentParser(
        description="py-mimic-fhir command line interface"
    )

    # Pull in environment variables
    parser.add_argument(
        '--sqluser',
        action=EnvDefault,
        envvar='SQLUSER',
        help='SQL username',
        required=True
    )
    parser.add_argument(
        '--sqlpass',
        action=EnvDefault,
        envvar='SQLPASS',
        help='SQL password',
        required=True
    )
    parser.add_argument(
        '--dbname_mimic',
        action=EnvDefault,
        envvar='DBNAME_MIMIC',
        help='MIMIC Database Name',
        required=True
    )
    parser.add_argument(
        '--host',
        action=EnvDefault,
        envvar='DBHOST',
        help='Database Host',
        required=True
    )
    parser.add_argument(
        '--port',
        action=EnvDefault,
        envvar='PGPORT',
        help='Database Port',
        required=True
    )

    parser.add_argument(
        '--fhir_server',
        action=EnvDefault,
        envvar='FHIR_SERVER',
        help='FHIR Server',
        required=True
    )
    parser.add_argument(
        '--output_path',
        action=EnvDefault,
        envvar='MIMIC_JSON_PATH',
        help='Export Resources',
        required=True
    )
    parser.add_argument(
        '--log_path',
        action=EnvDefault,
        envvar='MIMIC_FHIR_LOG_PATH',
        help='Export Resources',
        required=True
    )
    parser.add_argument(
        '--err_path',
        action=EnvDefault,
        envvar='FHIR_BUNDLE_ERROR_PATH',
        help='Error log file path for bundles',
        required=True
    )

    parser.add_argument(
        '--gcp_project',
        action=EnvDefault,
        envvar='GCP_PROJECT',
        help='Google Cloud project name',
        required=True
    )

    parser.add_argument(
        '--gcp_topic',
        action=EnvDefault,
        envvar='GCP_TOPIC',
        help='Google Cloud topic name to submit bundles to',
        required=True
    )

    parser.add_argument(
        '--gcp_location',
        action=EnvDefault,
        envvar='GCP_LOCATION',
        help='Google Cloud location of services',
        required=True
    )

    parser.add_argument(
        '--gcp_bucket',
        action=EnvDefault,
        envvar='GCP_BUCKET',
        help='Google Storage bucket where bundles errors can be logged',
        required=True
    )

    parser.add_argument(
        '--gcp_dataset',
        action=EnvDefault,
        envvar='GCP_DATASET',
        help='Google Healthcare API dataset',
        required=True
    )

    parser.add_argument(
        '--gcp_fhirstore',
        action=EnvDefault,
        envvar='GCP_FHIRSTORE',
        help='Google Healthcare API FHIR store',
        required=True
    )

    parser.add_argument(
        '--gcp_export_folder',
        action=EnvDefault,
        envvar='GCP_EXPORT_FOLDER',
        help='Google Cloud Storage folder to export resources to',
        required=True
    )

    parser.add_argument(
        '--validator',
        action=EnvDefault,
        envvar='FHIR_VALIDATOR',
        help='FHIR Validator being used. One of HAPI, GCP, or JAVA',
        required=True
    )

    parser.add_argument(
        '--db_mode',
        action=EnvDefault,
        envvar='DB_MODE',
        help='Database mode, either Postgres or BigQuery',
        required=True
    )

    # Create subparsers for validation, export, and terminology
    subparsers = parser.add_subparsers(dest="actions", title="actions")
    subparsers.required = True

    # Validation
    arg_validate = subparsers.add_parser(
        "validate", help=("Validation options for mimic-fhir data")
    )
    arg_validate.add_argument(
        '--dbname_hapi',
        required=True,
        action=EnvDefault,
        envvar='DBNAME_HAPI',
        help='HAPI Database Name'
    )

    # Allow exporting right after validation
    arg_validate.add_argument(
        '--export',
        required=False,
        action='store_true',
        help='Export Resources'
    )
    arg_validate.add_argument(
        '--export_limit',
        required=False,
        type=float,
        default=10000,
        help='Export Limit, 1 is ~ 1000 resources'
    )
    arg_validate.add_argument(
        '--num_patients',
        required=False,
        type=float,
        default=1,
        help='Number of patients'
    )
    arg_validate.add_argument(
        '--init',
        required=False,
        action='store_true',
        help='Initialize hapi fhir with data bundles'
    )

    arg_validate.add_argument(
        '--cores',
        type=int,
        default=1,
        help='Number of cores to use when validating'
    )

    # Validation
    arg_revalidate = subparsers.add_parser(
        "revalidate", help=("Revalidation options for failed bundles")
    )

    arg_revalidate.add_argument(
        '--bundle_run',
        type=str,
        default='latest',
        help='The bundle run that had failed bundles'
    )

    # Export - can be run separate from validation
    arg_export = subparsers.add_parser(
        "export", help=("Export options for mimic-fhir data")
    )
    arg_export.add_argument(
        '--export_limit',
        required=False,
        type=float,
        default=10000,
        help='Export Limit, 1 is ~ 1000 resources'
    )

    arg_export.add_argument(
        '--patient_everything',
        required=False,
        action='store_true',
        help='Flag to export patient-everything bundles'
    )

    arg_export.add_argument(
        '--num_patients',
        required=False,
        type=int,
        default=1,
        help='Number of patients to export patient-everything bundles'
    )

    arg_export.add_argument(
        '--count',
        required=False,
        type=int,
        default=100,
        help='Number of resources allowed per page, max 1000'
    )

    arg_export.add_argument(
        '--resource_types',
        required=False,
        type=str,
        default='Patient,Encounter,Condition,Procedure',
        help='Resource types to be included in patient-everything bundles'
    )

    arg_export.add_argument(
        '--pe_topic',
        required=True,
        action=EnvDefault,
        envvar='GCP_TOPIC_PATIENT_EVERYTHING',
        help='Google PubSub Topic for patient-everything'
    )

    arg_export.add_argument(
        '--ndjson_by_patient',
        required=False,
        action='store_true',
        help='Flag to export ndjson by patient from postgres'
    )

    # Terminology
    arg_terminology = subparsers.add_parser(
        "terminology",
        help=("Terminology generation option for mimic-fhir data")
    )

    arg_terminology.add_argument(
        '--terminology_path',
        required=True,
        action=EnvDefault,
        envvar='MIMIC_TERMINOLOGY_PATH',
        help='MIMIC Terminology Path to output complete CodeSystems/ValueSets'
    )

    arg_terminology.add_argument(
        '--version',
        required=False,
        type=str,
        default='2.0',
        help='Version for MIMIC terminology'
    )

    arg_terminology.add_argument(
        '--status',
        required=False,
        type=str,
        default='draft',
        help='Content maturity level'
    )

    arg_terminology.add_argument(
        '--generate_and_post',
        required=False,
        action='store_true',
        help=
        'Generate terminology and then post to HAPI server to expand valuesets'
    )

    arg_terminology.add_argument(
        '--post',
        required=False,
        action='store_true',
        help=
        'Post terminology to server, needed to fully expand valuesets with HAPI'
    )

    return parser.parse_args(arguments)


# Validate all resources for user specified number of patients
def validate(args, gcp_args):
    margs = MimicArgs(args.fhir_server, args.err_path, args.validator)
    if args.cores > 1:
        validation_result = multiprocess_validate(args, margs, gcp_args)
    else:
        validation_result = validate_n_patients(args, margs, gcp_args)

    if validation_result == True:
        logger.info('Validation successful')
    else:
        logger.error('Validation failed')

    # Only export if validation is successful
    ## DEPRECATED, NEED TO THINK IF THIS SHOULD BE ALLOWED ANYMORE
    # if args.export == True:
    #     export_all_resources(
    #         args.fhir_server, args.output_path, args.export_limit
    #     )


def revalidate(args, gcp_args):
    margs = MimicArgs(args.fhir_server, args.err_path, args.validator)
    validation_result = revalidate_bad_bundles(args, margs, gcp_args)


# Export all resources from FHIR Server and write to NDJSON
def export(args, gcp_args):
    db_conn = MFDatabaseConnection(
        args.sqluser, args.sqlpass, args.dbname_mimic, args.host, args.db_mode,
        args.port
    )
    pe_args = PatientEverythingArgs(
        args.patient_everything, args.num_patients, args.resource_types,
        args.pe_topic, args.count
    )
    export_all_resources(
        args.fhir_server, args.output_path, gcp_args, pe_args, args.validator,
        db_conn, args.ndjson_by_patient, args.export_limit
    )


# Generate mimic-fhir terminology systems and write out to file
def terminology(args):
    if args.post:
        post_terminology(args)
    elif args.generate_and_post:
        generate_all_terminology(args)
        post_terminology(args)
    else:
        generate_all_terminology(args)


# Logger will be written out to file and stdout
def set_logger(log_path):
    if not os.path.isdir(log_path):
        os.mkdir(log_path)

    day_of_week = datetime.now().strftime('%A').lower()
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(name)s -   %(message)s',
        datefmt='%m/%d/%Y %H:%M:%S',
        force=True,
        handlers=[
            logging.FileHandler(f'{log_path}log_mimic_fhir_{day_of_week}.log'),
            logging.StreamHandler()
        ]
    )


def main(argv=sys.argv):
    """Entry point for package."""

    args = parse_arguments(argv[1:])
    print(args)
    gcp_args = GoogleArgs(
        args.gcp_project, args.gcp_topic, args.gcp_location, args.gcp_bucket,
        args.gcp_dataset, args.gcp_fhirstore, args.gcp_export_folder
    )
    set_logger(args.log_path)
    if args.actions == 'validate':
        validate(args, gcp_args)
    elif args.actions == 'revalidate':
        revalidate(args, gcp_args)
    elif args.actions == 'export':
        export(args, gcp_args)
    elif args.actions == 'terminology':
        terminology(args)
    else:
        logger.warn('Unrecongnized command')


if __name__ == '__main__':
    main()