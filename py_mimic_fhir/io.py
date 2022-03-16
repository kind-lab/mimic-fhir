# Initialize logger - MIGRARTE THIS TO MAIN, should just pull in the logger, not the basicConfig
import logging

LOG_FORMAT = "%(levelname)s %(asctime)s - %(message)s"
logging.basicConfig(
    filename='log/export.log',
    filemode='a',
    format=LOG_FORMAT,
    level=logging.INFO,
    force=True
)

logger = logging.getLogger(__name__)

import numpy as np
import pandas as pd
import json
import psycopg2
import requests
import base64
from pathlib import Path
import os
import time

from py_mimic_fhir.lookup import (
    MIMIC_FHIR_PROFILE_URL, MIMIC_FHIR_RESOURCES, MIMIC_FHIR_PROFILE_NAMES
)


# Export all the resoruces, for debugging can limit how many to output. limit = 1 ~1000 resources
def export_all_resources(fhir_server, output_path, limit=1000):
    result_dict = {}
    bypass_profiles = [
        'Medication', 'MedicationRequest', 'MedicationDispense',
        'MedicationAdministration', 'MedicationAdministrationICU'
    ]

    for profile in MIMIC_FHIR_PROFILE_NAMES:
        if profile not in bypass_profiles:
            logger.info(f'Export {profile}')
            result = export_resource(profile, fhir_server, output_path, limit)
            result_dict[profile] = result

    if False in result_dict.values():
        logging.error(f'Result dictionary: {result_dict}')

    return result_dict


def export_resource(profile, fhir_server, output_path, limit=1000):
    resource = MIMIC_FHIR_RESOURCES[profile]
    profile_url = MIMIC_FHIR_PROFILE_URL[profile]
    resp_export = send_export_resource_request(
        resource, profile_url, fhir_server
    )
    resp_export_poll = get_exported_resource(resp_export)
    result = write_exported_resource_to_ndjson(
        resp_export_poll, profile, output_path, limit
    )

    return result


# Start the export process on HAPI FHIR. This is an async request, so the actual result is not provided yet
def send_export_resource_request(resource, profile_url, fhir_server):
    url = f"{fhir_server}$export?_type={resource}&_typeFilter={resource}?_profile={profile_url}"
    resp = requests.get(
        url,
        headers={
            "Content-Type": "application/fhir+json",
            "Prefer": "respond-async"
        }
    )
    return resp


# The exported resources are stored in a binary at the polling location specified in the initial export response
# The resource may NOT be ready when this is called, should the logic stay here to keep polling? or in parent function?
def get_exported_resource(resp_export, time_max=20):
    timeout = time.time() + time_max  # 30 seconds from now
    if resp_export.status_code == 202:
        url_content_location = resp_export.headers['Content-Location']
    else:
        logging.error(f'Export status code is: {resp_export.status_code}')
        url_content_location = ''

    while True:
        if url_content_location == '':
            resp = 'Initial request failed, no 202 status_code from response'
            break

        resp = requests.get(
            url_content_location,
            headers={"Content-Type": "application/fhir+json"}
        )
        if resp.status_code == 200:
            break
        elif time.time() > timeout:
            break  # exit if data not ready after timeout time
    return resp


# Take the binary exported resources and write them to json
def write_exported_resource_to_ndjson(
    resp_poll, profile, output_path, limit=1000
):
    output_file = f'{output_path}output_from_hapi/{profile}.ndjson'
    resp_poll_json = json.loads(resp_poll.text)

    #logging.error(resp_poll.text)
    #logging.error(resp_poll.headers)
    # Check if any resources were found in the export call
    if 'output' not in resp_poll_json:
        logging.error(f'No matching {profile} resources found on the server')
        return False

    # Delete the file if it exists since all writing will be appended in the next step
    if os.path.exists(output_file):
        os.remove(output_file)

    hapi_outputs = resp_poll_json['output']
    for idx, hapi_output in enumerate(hapi_outputs):
        # Limit the number of binaries to export, used primarily in debug
        if idx >= limit:
            break

        url_download = hapi_output['url']

        resp_download = requests.get(
            url_download, headers={"Content-Type": "application/fhir+json"}
        )

        # Decode base64 since that is HAPI FHIR's binary format
        output_data = base64.b64decode(
            json.loads(resp_download.content)['data']
        ).decode()

        with open(output_file, 'a+') as out_file:
            out_file.write(output_data)

    result = os.path.exists(output_file) and os.path.getsize(output_file) > 0
    return result
