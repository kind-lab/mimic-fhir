# Validation routines
import pandas as pd
import logging
from py_mimic_fhir import db
from py_mimic_fhir.bundle import Bundler

logger = logging.getLogger(__name__)


def get_n_patient_id(db_conn, n_patient):
    q_resource = f"SELECT * FROM mimic_fhir.patient LIMIT {n_patient}"
    resource = pd.read_sql_query(q_resource, db_conn)
    patient_ids = [fhir['id'] for fhir in resource.fhir]
    return patient_ids


# Validate n patients and all their associated resources
def validate_n_patients(args):
    # Get n patient ids to then bundle and post
    logger.info('Validating patients')
    logger.info(
        f'USER: {args.sqluser}, PASS: {args.sqlpass}, DBNAME: {args.dbname_mimic}, HOST: {args.host}'
    )
    db_conn = db.db_conn(
        args.sqluser, args.sqlpass, args.dbname_mimic, args.host
    )
    logger.info(f'Database connection: {db_conn}')
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