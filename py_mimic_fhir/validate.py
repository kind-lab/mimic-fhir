# Validation routines
import pandas as pd
import logging
import json
from py_mimic_fhir.db import connect_db, get_n_patient_id, get_resource_by_id
from py_mimic_fhir.bundle import Bundle, get_n_resources
from py_mimic_fhir.lookup import MIMIC_BUNDLE_TABLE_LIST

logger = logging.getLogger(__name__)


# Validate n patients and all their associated resources
def validate_n_patients(args, margs):
    # initialize db connection
    db_conn = connect_db(
        args.sqluser, args.sqlpass, args.dbname_mimic, args.host
    )

    if args.init:
        init_data_bundles(db_conn, margs.fhir_server, margs.err_path)

    logger.info('---------- Validating patients -----------------')
    logger.info(f'patient num: {args.num_patients}')
    patient_ids = get_n_patient_id(db_conn, args.num_patients)
    logger.info(f'Patient ids: {patient_ids}')
    split_flag = True  # Flag to subdivide bundles to speed up posting

    # Create bundle and post it
    result = True
    for patient_id in patient_ids:
        response_list = validate_all_bundles(patient_id, db_conn, margs)
        if False in response_list:
            result = False

    return result


def validate_all_bundles(patient_id, db_conn, margs):
    response_list = []
    logger.info(f'---------- patient_id: {patient_id}')
    for name, table_list in MIMIC_BUNDLE_TABLE_LIST.items():
        logger.info(f'{name} bundle')
        # Create bundle and post it
        bundle_response = validate_bundle(name, patient_id, db_conn, margs)
        response_list.append(bundle_response)
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


# After changes have been made to correct bundle errors, the bundle can be rerurn from file
def revalidate_bundle_from_file(err_filename, db_conn, margs):
    bundle_result = []

    with open(err_filename, 'r') as err_file:
        for err in err_file:
            bundle_error = json.loads(err)
            patient_id = bundle_error['patient_id']
            bundle_name = bundle_error['bundle_name']
            bundle_list = bundle_error['bundle_list']
            if patient_id is not None:
                response = validate_bundle(
                    bundle_name, patient_id, db_conn, margs
                )
            else:
                for entry in bundle_list:
                    resources = []

                    #drop mimic prefix from profile to get mimic table name
                    profile = entry['fhir_profile'].replace('-', '_')[6:]
                    fhir_id = entry['id']
                    resource = get_resource_by_id(db_conn, profile, fhir_id)
                    resources.append(resource)
                bundle = Bundle(bundle_name)
                bundle.add_entry(resources)
                response = bundle.request(margs.fhir_server, margs.err_path)
            bundle_result.append(response)

    return bundle_result
