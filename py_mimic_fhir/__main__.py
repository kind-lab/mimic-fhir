import argparse
import os
import sys
from datetime import datetime
import logging
import pandas as pd
from pathlib import Path

from py_mimic_fhir.validate import validate_n_patients
from py_mimic_fhir.io import export_all_resources
from py_mimic_fhir.terminology import generate_all_terminology

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
    # More for debugging, output to console
    parser.add_argument(
        '--stdout',
        action='store_true',
        help='Log to standard console',
        required=False
    )

    # Create subparsers for validation and export
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
        default='0.4',
        help='Version for MIMIC terminology'
    )

    arg_terminology.add_argument(
        '--status',
        required=False,
        type=str,
        default='draft',
        help='Content maturity level'
    )

    return parser.parse_args(arguments)


# Validate all resources for user specified number of patients
def validate(args):
    validation_result = validate_n_patients(args)
    if validation_result == True:
        logger.info('Validation successful')
    else:
        logger.error('Validation failed')

    # Only export if validation is successful
    if validation_result == True and args.export == True:
        export_all_resources(
            args.fhir_server, args.output_path, args.export_limit
        )


# Export all resources from FHIR Server and write to NDJSON
def export(args):
    export_all_resources(args.fhir_server, args.output_path, args.export_limit)


# Generate mimic-fhir terminology systems and write out to file
def terminology(args):
    generate_all_terminology(args)


# Logger can be written out to file or stdout, user chooses
def set_logger(log_path, stdout=False):
    if stdout:
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(name)s -   %(message)s',
            datefmt='%m/%d/%Y %H:%M:%S',
            force=True
        )
    else:
        # create log folder if it does not exist
        if not os.path.isdir(log_path):
            os.mkdir(log_path)

        day_of_week = datetime.now().strftime('%A').lower()
        logging.basicConfig(
            filename=f'{log_path}log_mimic_fhir_{day_of_week}.log',
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(name)s -   %(message)s',
            datefmt='%m/%d/%Y %H:%M:%S',
            force=True
        )


def main(argv=sys.argv):
    """Entry point for package."""

    args = parse_arguments(argv[1:])
    set_logger(args.log_path, args.stdout)
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