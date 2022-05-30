# Validation routines
import pandas as pd
import logging
import shutil
import os
import json
import multiprocessing as mp
from datetime import datetime
from py_mimic_fhir.db import connect_db, get_n_patient_id, get_resource_by_id
from py_mimic_fhir.bundle import Bundle, get_n_resources
from py_mimic_fhir.lookup import MIMIC_BUNDLE_TABLE_LIST, MIMIC_DATA_BUNDLE_LIST
from py_mimic_fhir.config import ResultList

logger = logging.getLogger(__name__)
output_list = []


def multiprocess_validate(args, margs):
    num_workers = args.cores
    max_workers = mp.cpu_count()
    if num_workers > max_workers:
        num_workers = max_workers

    pool = mp.Pool(num_workers)
    logger.info('in multiproces validate!')
    logger.info(f'num workers: {num_workers}')

    db_conn = connect_db(
        args.sqluser, args.sqlpass, args.dbname_mimic, args.host
    )

    if args.init:
        init_data_bundles(db_conn, margs.fhir_server, margs.err_path)

    patient_ids = get_n_patient_id(db_conn, args.num_patients)
    logger.info(f'Patient ids: {patient_ids}')
    result_list = ResultList()
    for patient_id in patient_ids:
        pool.apply_async(
            validation_worker,
            args=(patient_id, args, margs),
            callback=result_list.update
        )

    pool.close()
    pool.join()

    logger.info(f'Result List: {result_list.get()}')
    result = True
    if (False in result_list.get()) or (None in result_list.get()):
        result = False

    return result


def validation_worker(patient_id, args, margs):
    try:
        response_list = [False]
        db_conn = connect_db(
            args.sqluser, args.sqlpass, args.dbname_mimic, args.host
        )
        response_list = validate_all_bundles(patient_id, db_conn, margs)
        result = True
        if False in response_list:
            result = False
        return result
    except Exception as e:
        logger.error(e)
        return False


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
        # Create bundle and post it
        bundle_response = validate_bundle(name, patient_id, db_conn, margs)
        response_list.append(bundle_response)
    return response_list


def validate_bundle(name, patient_id, db_conn, margs):
    logger.info(f'{name} bundle')
    bundle = Bundle(name, MIMIC_BUNDLE_TABLE_LIST[name])
    bundle.generate(patient_id, db_conn)
    response = bundle.request(margs.fhir_server, margs.err_path)
    return response


# Post data bundles before patient bundles. This includes Organization and Medication
def init_data_bundles(db_conn, fhir_server, err_path):
    data_tables = MIMIC_DATA_BUNDLE_LIST
    logger.info('----------- Initializing Data Tables ------------')
    for table in data_tables:
        logger.info(f'{table} data being uploaded to HAPI')
        resources = get_n_resources(db_conn, table)
        init_data_bundle(table, resources, fhir_server, err_path)


def init_data_bundle(table, resources, fhir_server, err_path):
    bundle = Bundle(f'init_{table}')
    bundle.add_entry(resources)
    response = bundle.request(fhir_server, err_path)


#----------------- Revalidate bad bundles ----------------------------
def revalidate_bad_bundles(args, margs):
    day_of_week = datetime.now().strftime('%A').lower()
    err_filename = f'err-bundles-{day_of_week}.json'
    db_conn = connect_db(
        args.sqluser, args.sqlpass, args.dbname_mimic, args.host
    )

    response_list = revalidate_bundle_from_file(err_filename, db_conn, margs)
    if False in response_list:
        validation_result = False
    else:
        validation_result = True
    return validation_result


# After changes have been made to correct bundle errors, the bundle can be rerurn from file
def revalidate_bundle_from_file(err_filename, db_conn, margs):
    bundle_result = []

    #make copy of file, since new errors will be written to the same file
    old_err_filename = f'{margs.err_path}{err_filename}'
    logger.info(f'Error filename: {old_err_filename}')
    new_err_filename = f'{margs.err_path}rerun-{err_filename}'
    shutil.copy(old_err_filename, new_err_filename)
    os.remove(old_err_filename)

    with open(new_err_filename, 'r') as err_file:
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
        #os.remove(new_err_filename) # delete rerun file after done, leave for debugging right now
    return bundle_result
