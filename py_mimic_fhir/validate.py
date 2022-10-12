# Validation routines
import pandas as pd
import logging
import shutil
import os
import json
import multiprocessing as mp
from datetime import datetime
from google.cloud import pubsub_v1

from py_mimic_fhir.db import MFDatabaseConnection
from py_mimic_fhir.bundle import Bundle
from py_mimic_fhir.lookup import MIMIC_BUNDLE_TABLE_LIST, MIMIC_DATA_BUNDLE_LIST
from py_mimic_fhir.config import ResultList, GoogleArgs

logger = logging.getLogger(__name__)
output_list = []


def multiprocess_validate(args, margs, gcp_args):
    num_workers = args.cores
    max_workers = mp.cpu_count()
    if num_workers > max_workers:
        num_workers = max_workers

    pool = mp.Pool(num_workers)
    logger.info('in multiproces validate!')
    logger.info(f'num workers: {num_workers}')

    if args.init:
        init_data_bundles(
            db_conn, margs.fhir_server, margs.err_path, gcp_args,
            margs.validator
        )

    db_conn = MFDatabaseConnection(
        args.sqluser, args.sqlpass, args.dbname_mimic, args.host, args.db_mode,
        args.port
    )
    patient_ids = db_conn.get_n_patient_id(args.num_patients)
    logger.info(f'Patient ids: {patient_ids}')
    result_list = ResultList()
    for patient_id in patient_ids:
        pool.apply_async(
            validation_worker,
            args=(patient_id, args, margs),
            callback=result_list.update
        )

    logger.info(f'Result List: {result_list.get()}')
    pool.close()
    pool.join()

    logger.info(f'Result List: {result_list.get()}')
    result = True
    if (False in result_list.get()) or (None in result_list.get()):
        result = False

    return result


def validation_worker(patient_id, args, margs):
    gcp_args = GoogleArgs(
        args.gcp_project, args.gcp_topic, args.gcp_location, args.gcp_bucket,
        args.gcp_dataset, args.gcp_fhirstore, args.gcp_export_folder
    )
    try:
        response_list = [False]

        db_conn = MFDatabaseConnection(
            args.sqluser, args.sqlpass, args.dbname_mimic, args.host,
            args.db_mode, args.port
        )
        response_list = validate_all_bundles(
            patient_id, db_conn, margs, gcp_args
        )
        result = True
        if False in response_list:
            result = False
        logger.info(f'{patient_id} DONE VALIDATION, ABOUT TO RETURN {result}')
        return result
    except Exception as e:
        logger.error(e)
        return e


# Validate n patients and all their associated resources
def validate_n_patients(args, margs, gcp_args):
    # initialize db connection
    db_conn = MFDatabaseConnection(
        args.sqluser, args.sqlpass, args.dbname_mimic, args.host, args.db_mode,
        args.port
    )

    if args.init:
        init_data_bundles(
            db_conn, margs.fhir_server, margs.err_path, gcp_args,
            margs.validator
        )

    logger.info('---------- Validating patients -----------------')
    logger.info(f'patient num: {args.num_patients}')
    patient_ids = db_conn.get_n_patient_id(args.num_patients)
    logger.info(f'Patient ids: {patient_ids}')
    split_flag = True  # Flag to subdivide bundles to speed up posting

    # Create bundle and post it
    result = True
    for patient_id in patient_ids:
        response_list = validate_all_bundles(
            patient_id, db_conn, margs, gcp_args
        )
        if False in response_list:
            result = False

    return result


def validate_all_bundles(patient_id, db_conn, margs, gcp_args):
    response_list = []
    logger.info(f'---------- patient_id: {patient_id}')
    for name, table_list in MIMIC_BUNDLE_TABLE_LIST.items():
        # Create bundle and post it
        bundle_response = validate_bundle(
            name, patient_id, db_conn, margs, gcp_args
        )
        response_list.append(bundle_response)
    db_conn.close()
    return response_list


def validate_bundle(name, patient_id, db_conn, margs, gcp_args):
    logger.info(f'{name} bundle for patient: {patient_id}')
    bundle = Bundle(name, MIMIC_BUNDLE_TABLE_LIST[name], patient_id=patient_id)
    bundle.generate(patient_id, db_conn)
    if margs.validator == 'HAPI':
        response = bundle.request(margs.fhir_server, margs.err_path)
    elif margs.validator == 'GCP':
        response = bundle.publish(gcp_args)
    return response


# Post data bundles before patient bundles. This includes Organization and Medication
def init_data_bundles(db_conn, fhir_server, err_path, gcp_args, validator):
    data_tables = MIMIC_DATA_BUNDLE_LIST
    logger.info('----------- Initializing Data Tables ------------')

    for table in data_tables:
        logger.info(f'{table} data being uploaded to {validator}')
        resources = db_conn.get_n_resources(table)
        init_data_bundle(
            table, resources, fhir_server, err_path, gcp_args, validator
        )


def init_data_bundle(
    table, resources, fhir_server, err_path, gcp_args, validator
):
    bundle = Bundle(f"init-{table.replace('_','-')}")
    bundle.add_entry(resources)
    if validator == 'HAPI':
        response = bundle.request(fhir_server, err_path)
    elif validator == 'GCP':
        response = bundle.publish(gcp_args)


#----------------- Revalidate bad bundles ----------------------------
def revalidate_bad_bundles(args, margs, gcp_args):

    db_conn = MFDatabaseConnection(
        args.sqluser, args.sqlpass, args.dbname_mimic, args.host, args.db_mode,
        args.port
    )
    if args.validator == 'GCP':
        validation_result = revalidate_from_gcp(
            db_conn, gcp_args, margs, args.bundle_run
        )
    else:
        day_of_week = datetime.now().strftime('%A').lower()
        err_filename = f'err-bundles-{day_of_week}.json'
        response_list = revalidate_bundle_from_file(
            err_filename, db_conn, margs
        )
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
                    resource = db_conn.get_resource_by_id(profile, fhir_id)
                    resources.append(resource)
                bundle = Bundle(bundle_name)
                bundle.add_entry(resources)
                response = bundle.request(margs.fhir_server, margs.err_path)
            bundle_result.append(response)
        #os.remove(new_err_filename) # delete rerun file after done, leave for debugging right now
    return bundle_result


def revalidate_from_gcp(db_conn_pg, gcp_args, margs, bundle_run):
    db_conn_bq = MFDatabaseConnection('', '', '', '', 'BIGQUERY')

    if bundle_run == 'latest':
        query_latest = 'SELECT bundle_run FROM mimic_fhir_log.bundle_error GROUP BY bundle_run ORDER BY MAX(logtime) DESC;'
        df = db_conn_bq.read_query(query_latest)
        bundle_run = df.iloc[0]['bundle_run']

    query = f"SELECT * FROM mimic_fhir_log.bundle_error WHERE bundle_run = '{bundle_run}'"
    df = db_conn_bq.read_query(query)
    response_list = []
    for row in df.itertuples():
        logger.info(f"Patient: {row.patient_id}, Bundle: {row.bundle_group}")
        table_list = MIMIC_BUNDLE_TABLE_LIST[row.bundle_group]
        bundle_response = validate_bundle(
            name=row.bundle_group,
            patient_id=row.patient_id,
            db_conn=db_conn_pg,
            margs=margs,
            gcp_args=gcp_args
        )
        response_list.append(bundle_response)

    result = 'False' not in response_list
    return result

    # access gcp to get all the patient_ids and bundle groups to rerun
