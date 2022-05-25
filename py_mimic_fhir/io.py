# IO module has functions for exporting resources from HAPI

# NEED TO UPDATE LOGGING WHEN __MAIN__ IS ADDED!!!
import logging
import numpy as np
import pandas as pd
import json
import requests
import base64
import os
import subprocess
import time

from py_mimic_fhir.lookup import (
    MIMIC_FHIR_PROFILE_URL, MIMIC_FHIR_RESOURCES, MIMIC_FHIR_PROFILE_NAMES
)

logger = logging.getLogger(__name__)


# Export all the resources, for debugging can limit how many to output. limit = 1 ~1000 resources
def export_all_resources(fhir_server, output_path, limit=10000):
    result_dict = {}

    # Export each resource based on its profile name
    for profile in MIMIC_FHIR_PROFILE_NAMES:
        logger.info(f'Export {profile}')
        result = export_resource(profile, fhir_server, output_path, limit)
        result_dict[profile] = result

    if False in result_dict.values():
        logger.error(f'Result dictionary: {result_dict}')
    else:
        sort_resources(output_path)

    return result_dict


# Export resource from the HAPI FHIR Server
# Process is 3 parts
#   1. Post export request
#   2. Poll HAPI export location, to get download location
#   3. Download from HAPI download location
#   4. Write the downloaded resources to file
def export_resource(profile, fhir_server, output_path, limit=10000):
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
# The ObservationChartevents resources take longer so time_max needs to be about 3 minutes!
def get_exported_resource(resp_export, time_max=600):
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
        elif resp.status_code == 202:
            # Server tells the program how long to wait till requesting again
            # retry_after_time = int(resp.headers['Retry-After'])
            # time.sleep(
            #     retry_after_time  # always 120 seconds, even when not necessary...
            # )  # need to figure out queueing system to avoid this...
            # just sleep for 20seconds and retry
            time.sleep(20)
        elif time.time() > timeout:
            break  # exit if data not ready after time_max time
        else:
            time.sleep(
                1
            )  #put a break in here to let other HAPI process finish. Needed for tests to work
    return resp


# Take the binary exported resources and write them to json
def write_exported_resource_to_ndjson(
    resp_poll, profile, output_path, limit=10000
):
    output_file = f'{output_path}/{profile}.ndjson'
    if resp_poll.text is None:
        logger.error(f'{profile} response poll is empty!!')
        return False

    resp_poll_json = json.loads(resp_poll.text)

    # Check if any resources were found in the export call
    if 'output' not in resp_poll_json:
        logger.error(f'No matching {profile} resources found on the server')
        logger.error(resp_poll.text)
        return False

    # Delete the file if it exists since all writing will be appended in the next step
    if os.path.exists(output_file):
        os.remove(output_file)

    hapi_outputs = resp_poll_json['output']
    for idx, hapi_output in enumerate(hapi_outputs):
        # Limit the number of binaries to export, used primarily in debug
        if idx >= limit:
            break

        # Download the resources from the HAPI url that was specified
        url_download = hapi_output['url']
        resp_download = requests.get(
            url_download, headers={"Content-Type": "application/fhir+json"}
        )

        # Decode base64 since that is HAPI FHIR's binary format
        output_data = base64.b64decode(
            json.loads(resp_download.content)['data']
        ).decode()

        # Write resources out to NDJSON
        with open(output_file, 'a+') as out_file:
            out_file.write(output_data)

    result = os.path.exists(output_file) and os.path.getsize(output_file) > 0
    return result


# PUT resources to HAPI fhir server
def put_resource(resource, fhir_data, fhir_server):
    url = fhir_server + resource + '/' + fhir_data['id']

    resp = requests.put(
        url, json=fhir_data, headers={"Content-Type": "application/fhir+json"}
    )
    output = json.loads(resp.text)
    return output


def sort_resources(output_path):
    profiles = ' '.join(MIMIC_FHIR_PROFILE_NAMES)

    # Sorting done with a shell script since pandas sorting crashes with large file sizes
    process = subprocess.run(
        ['sh', 'py_mimic_fhir/scripts/sort_ndjson.sh', profiles, output_path],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    assert len(process.stderr) == 0
    return process
