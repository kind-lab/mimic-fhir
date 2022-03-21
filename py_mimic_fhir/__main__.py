import argparse
import os
import sys
import logging
import pandas as pd
import logging
from pathlib import Path

from py_mimic_fhir.validate import validate_n_patients

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

    subparsers = parser.add_subparsers(dest="actions", title="actions")
    subparsers.required = True

    # Downloading
    arg_validate = subparsers.add_parser(
        "validate", help=("Validation options for mimic-fhir data")
    )
    arg_validate.add_argument(
        '--fhir_server',
        action=EnvDefault,
        envvar='FHIR_SERVER',
        required=True,
        help='FHIR Server'
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
        help='HAPI Database Name'
    )
    arg_validate.add_argument(
        '--export',
        required=False,
        type=bool,
        default=False,
        help='Export Resources'
    )
    arg_validate.add_argument(
        '--num_patients',
        required=False,
        type=float,
        default=1,
        help='Number of patients'
    )

    return parser.parse_args(arguments)


def validate(args):
    result = validate_n_patients(args)
    if result == True:
        logger.info('Validation successful')
    else:
        logger.error('Validation failed')


def main(argv=sys.argv):
    """Entry point for package."""

    args = parse_arguments(argv[1:])

    if args.actions == 'validate':
        validate(args)
    else:
        logger.warn('Unrecongnized command')


if __name__ == '__main__':
    main()