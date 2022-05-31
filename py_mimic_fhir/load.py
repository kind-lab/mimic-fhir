import pandas as pd
import logging
import shutil
import os
import json
import ndjson
import multiprocessing as mp
from py_mimic_fhir.db import connect_db, get_n_patient_id, get_resource_by_id
from py_mimic_fhir.bundle import Bundle, get_n_resources
from py_mimic_fhir.lookup import MIMIC_FHIR_PROFILE_NAMES
from py_mimic_fhir.config import ResultList

logger = logging.getLogger(__name__)


def multiprocess_load(cores, margs):
    num_workers = cores
    max_workers = mp.cpu_count()
    if num_workers > max_workers:
        num_workers = max_workers

    pool = mp.Pool(num_workers)
    logger.info('in multiprocess load!')
    logger.info(f'num workers: {num_workers}')

    result_list = ResultList()
    for profile in MIMIC_FHIR_PROFILE_NAMES:
        if profile not in ['ObservationChartevents', 'ObservationLabevents']:
            pool.apply_async(
                load_worker, args=(profile, margs), callback=result_list.update
            )

    pool.close()
    pool.join()

    logger.info(f'Result List: {result_list.get()}')
    result = True
    if (False in result_list.get()) or (None in result_list.get()):
        result = False

    return result


def load_worker(profile, margs):
    try:
        logger.info(f'-------- Loading profile: {profile}')
        resources = load_ndjson_from_file(margs.json_path, profile)
        response = load_resources_to_server(resources, profile, margs)
        return response
    except Exception as e:
        logger.error(e)
        return False


def load_resources_to_server(resources, bundle_name, margs, bundle_size=50):
    bundle = Bundle(bundle_name)
    bundle.add_entry(resources)
    response = bundle.request(
        margs.fhir_server, margs.err_path, bundle_size=bundle_size
    )
    return response


def load_ndjson_from_file(json_path, profile):
    infilename = f'{json_path}/{profile}.ndjson'
    with open(infilename, 'r') as infile:
        resources = ndjson.load(infile)

    return resources
