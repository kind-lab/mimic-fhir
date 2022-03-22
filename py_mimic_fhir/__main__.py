import argparse
import os
import sys
import logging
import pandas as pd
import logging
from pathlib import Path

from py_mimic_fhir.validate import validate_n_patients
from py_mimic_fhir.io import export_all_resources

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(name)s -   %(message)s',
    datefmt='%m/%d/%Y %H:%M:%S',
    force=True
)
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
    parser.add_argument(
        '--sqluser',
        required=True,
        action=EnvDefault,
        envvar='SQLUSER',
        help='SQL username'
    )
    parser.add_argument(
        '--sqlpass',
        required=True,
        action=EnvDefault,
        envvar='SQLPASS',
        help='SQL password'
    )
    parser.add_argument(
        '--dbname_mimic',
        required=True,
        action=EnvDefault,
        envvar='DBNAME_MIMIC',
        help='MIMIC Database Name'
    )
    parser.add_argument(
        '--host',
        required=True,
        action=EnvDefault,
        envvar='HOST',
        help='Database Host'
    )
    parser.add_argument(
        '--fhir_server',
        action=EnvDefault,
        envvar='FHIR_SERVER',
        required=True,
        help='FHIR Server'
    )
    parser.add_argument(
        '--output_path',
        required=False,
        action=EnvDefault,
        envvar='MIMIC_JSON_PATH',
        help='Export Resources'
    )

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
    arg_validate.add_argument(
        '--err_path',
        required=True,
        action=EnvDefault,
        envvar='FHIR_BUNDLE_ERROR_PATH',
        help='Bundling error file path'
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

    return parser.parse_args(arguments)


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


def export(args):
    export_all_resources(args.fhir_server, args.output_path, args.export_limit)


def main(argv=sys.argv):
    """Entry point for package."""

    args = parse_arguments(argv[1:])

    if args.actions == 'validate':
        validate(args)
    elif args.actions == 'export':
        export(args)
    else:
        logger.warn('Unrecongnized command')


if __name__ == '__main__':
    main()