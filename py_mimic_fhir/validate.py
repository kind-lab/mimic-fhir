# Validation routines
import pandas as pd
import logging
from py_mimic_fhir.db import connect_db, get_n_patient_id
from py_mimic_fhir.bundle import Bundle, get_n_resources
from py_mimic_fhir.lookup import MIMIC_BUNDLE_TABLE_LIST

logger = logging.getLogger(__name__)

# Get N patient ids from mimic_fhir


# Validate n patients and all their associated resources
def validate_n_patients(args):
    # initialize db connection
    db_conn = connect_db(
        args.sqluser, args.sqlpass, args.dbname_mimic, args.host
    )

    margs = MimicArgs(args.fhir_server, args.err_path)
    if args.init:
        init_data_bundles(db_conn, args.fhir_server, args.err_path)

    logger.info('---------- Validating patients -----------------')
    logger.info(f'patient num: {args.num_patients}')
    patient_ids = get_n_patient_id(db_conn, args.num_patients)
    logger.info(f'Patient ids: {patient_ids}')
    split_flag = True  # Flag to subdivide bundles to speed up posting

    # Create bundle and post it
    result = True
    response_list = []
    for patient_id in patient_ids:
        validate_all_bundles(patient_id, db_conn, margs)
        if False in response_list:
            result = False

    return result


def validate_all_bundles(patient_id, db_conn, margs):
    response_list = []
    for name, table_list in MIMIC_BUNDLE_TABLE_LIST.items():
        logger.info(f'{name} bundle')
        # Create bundle and post it
        bundle_response = validate_bundle(name, patient_id, db_conn, margs)
        response_list.append(bundle_response)
        # bundle = Bundle(name, table_list)
        # bundle.generate(patient_id, db_conn)
        # response_list.append(bundle.request(fhir_server, err_path))
    return response_list


def validate_bundle(name, patient_id, db_conn, margs):
    bundle = Bundle(name, MIMIC_BUNDLE_TABLE_LIST[name])
    bundle.generate(patient_id, db_conn)
    response = bundle.request(margs.fhir_server, margs.err_path)
    return response


# Post data bundles before patient bundles. This includes Organization and Medication
def init_data_bundles(db_conn, fhir_server, err_path):
    data_tables = ['medication', 'medication_mix', 'organization']
    logger.info('----------- Initializing Data Tables ------------')
    for table in data_tables:
        logger.info(f'{table} data being uploaded to HAPI')
        resources = get_n_resources(db_conn, table)
        init_data_bundle(table, resources, fhir_server, err_path)


def init_data_bundle(table, resources, fhir_server, err_path):
    bundle = Bundle(f'init_{table}')
    bundle.add_entry(resources)
    response = bundle.request(fhir_server, err_path)


class MimicArgs():
    def __init__(self, fhir_server, err_path):
        self.fhir_server = fhir_server
        self.err_path = err_path
