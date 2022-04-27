# Validation routines
import pandas as pd
import logging
from py_mimic_fhir import db
from py_mimic_fhir.bundle import Bundle, get_n_resources
from py_mimic_fhir.lookup import MIMIC_BUNDLE_TABLE_LIST

logger = logging.getLogger(__name__)


# Get N patient ids from mimic_fhir
def get_n_patient_id(db_conn, n_patient):
    q_resource = f"SELECT * FROM mimic_fhir.patient LIMIT {n_patient}"
    resource = pd.read_sql_query(q_resource, db_conn)
    patient_ids = [fhir['id'] for fhir in resource.fhir]
    return patient_ids


# Validate n patients and all their associated resources
def validate_n_patients(args):
    # initialize db connection
    db_conn = db.db_conn(
        args.sqluser, args.sqlpass, args.dbname_mimic, args.host
    )

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
        validate_all_bundles(
            patient_id, db_conn, args.fhir_server, args.err_path
        )
        if False in response_list:
            result = False

    return result


def validate_all_bundles(patient_id, db_conn, fhir_server, err_path):
    response_list = []
    for name, table_list in MIMIC_BUNDLE_TABLE_LIST.items():
        logger.info(f'{name} bundle')
        # Create bundle and post it
        bundle = Bundle(name, table_list)
        bundle.generate(patient_id, db_conn)
        response_list.append(bundle.request(fhir_server, err_path))
    return response_list


# Post data bundles before patient bundles. This includes Organization and Medication
def init_data_bundles(db_conn, fhir_server, err_path):
    data_tables = ['medication', 'medication_mix', 'organization']
    table_limit = [
        50000, 10000, 1
    ]  #can manually set number of resources, but use all for now
    logger.info('----------- Initializing Data Tables ------------')
    for table in data_tables:
        logger.info(f'{table} data being uploaded to HAPI')
        resources = get_n_resources(db_conn, table)
        init_data_bundle(table, resources, fhir_server, err_path)


def init_data_bundle(table, resources, fhir_server, err_path):
    bundle = Bundle(f'init_{table}')
    bundle.add_entry(resources)
    response = bundle.request(fhir_server, err_path)
