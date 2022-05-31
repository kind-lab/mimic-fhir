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
    #leave one core for hapi or we get freezing
    max_workers = mp.cpu_count() - 1
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
        response = load_ndjson_from_file_chunks(margs, profile)
        # resources = load_ndjson_from_file(margs.json_path, profile)
        # response = load_resources_to_server(resources, profile, margs)
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


def load_ndjson_from_file_chunks(margs, profile, bundle_size=10):
    infilename = f'{margs.json_path}/{profile}.ndjson'
    response_list = []
    with open(infilename, 'r') as infile:
        reader = ndjson.reader(infile)
        resources = []
        for row in reader:
            resources.append(row)
            if len(resources) > bundle_size:
                response = load_resources_to_server(
                    resources, profile, margs, bundle_size
                )
                response_list.append(response)
                resources = []

        if len(resources) > 0:
            response = load_resources_to_server(
                resources, profile, margs, bundle_size
            )
            response_list.append(response)

        final_response = False if False in response_list else True
    return final_response