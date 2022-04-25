# Validation routines
import pandas as pd
import logging
from py_mimic_fhir import db
from py_mimic_fhir.bundle import Bundle, Bundler, get_n_resources

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
    for patient_id in patient_ids:
        bundler = Bundler(patient_id, db_conn)
        bundler.generate_all_bundles()
        response_list = bundler.post_all_bundles(
            args.fhir_server, split_flag, args.err_path
        )

        if False in response_list:
            result = False
    return result


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
        init_data_bundle(resources, fhir_server, err_path)


def init_data_bundle(resources, fhir_server, err_path):
    split_flag = True  # Divide up bundles into smaller chunks
    bundle = Bundle()
    bundle.add_entry(resources)
    response = bundle.request(fhir_server, split_flag, err_path)