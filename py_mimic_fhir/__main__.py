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
from py_mimic_fhir.config import MimicArgs

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
        '--rerun',
        required=False,
        action='store_true',
        help='Rerun any failed bundles'
    )

    arg_validate.add_argument(
        '--cores',
        type=int,
        default=1,
        help='Number of cores to use when validating'
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
def validate(args):
    margs = MimicArgs(args.fhir_server, args.err_path)
    if args.rerun:
        validation_result = revalidate_bad_bundles(args, margs)
    elif args.cores > 1:
        validation_result = multiprocess_validate(args, margs)
    else:
        validation_result = validate_n_patients(args, margs)

    if validation_result == True:
        logger.info('Validation successful')
    else:
        logger.error('Validation failed')

    # Only export if validation is successful
    if args.export == True:
        export_all_resources(
            args.fhir_server, args.output_path, args.export_limit
        )


# Export all resources from FHIR Server and write to NDJSON
def export(args):
    export_all_resources(args.fhir_server, args.output_path, args.export_limit)


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
    set_logger(args.log_path)
    if args.actions == 'validate':
        validate(args)
    elif args.actions == 'export':
        export(args)
    elif args.actions == 'terminology':
        terminology(args)
    else:
        logger.warn('Unrecongnized command')


if __name__ == '__main__':
    main()