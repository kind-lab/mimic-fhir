# IO module has functions for exporting resources from HAPI and GCP

import logging
import numpy as np
import pandas as pd
import json
import requests
import base64
import os
import subprocess
import time
from googleapiclient import discovery
from google.cloud import pubsub_v1

from py_mimic_fhir.lookup import (
    MIMIC_FHIR_PROFILES, MIMIC_DATA_TABLE_LIST, MIMIC_PATIENT_TABLE_LIST
)

logger = logging.getLogger(__name__)


# Export all the resources, for debugging can limit how many to output. limit = 1 ~1000 resources
def export_all_resources(
    fhir_server,
    output_path,
    gcp_args,
    pe_args,
    validator,
    db_conn,
    export_ndjson_by_patient,
    limit=10000
):

    if export_ndjson_by_patient:
        export_data_related_ndjson(db_conn, output_path)
        export_patient_related_ndjson(db_conn, output_path)
    if validator == 'HAPI':
        result_dict = export_all_resources_hapi(fhir_server, output_path, limit)
        result = False not in result_dict.values()
    elif validator == 'GCP' and pe_args.patient_everything:
        result = export_patient_everything_gcp(gcp_args, pe_args, db_conn)
    elif validator == 'GCP' and not pe_args.patient_everything:
        result = export_all_resources_gcp(gcp_args)

    return result


def export_all_resources_hapi(fhir_server, output_path, limit=10000):
    result_dict = {}

    # Export each resource based on its profile name
    for profile in MIMIC_FHIR_PROFILES:
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
    resource = MIMIC_FHIR_PROFILES[profile]['resource']
    profile_url = MIMIC_FHIR_PROFILES[profile]['url']
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


def export_all_resources_gcp(gcp_args):
    api_version = "v1"
    service_name = "healthcare"
    client = discovery.build(service_name, api_version)

    export_today_folder = time.strftime("%Y%m%d-%H%M%S")
    gcs_uri = f'{gcp_args.bucket}/{gcp_args.export_folder}/{export_today_folder}'

    fhir_store_parent = f"projects/{gcp_args.project}/locations/{gcp_args.location}/datasets/{gcp_args.dataset}"
    fhir_store_name = f"{fhir_store_parent}/fhirStores/{gcp_args.fhirstore}"

    body = {"gcsDestination": {"uriPrefix": f"gs://{gcs_uri}"}}

    request = (
        client.projects().locations().datasets().fhirStores().export(
            name=fhir_store_name, body=body
        )
    )
    try:
        response = request.execute()
        logger.info(response)
        result = True
    except Exception as e:
        logger.error(e)
        result = False

    return result


def export_patient_everything_gcp(gcp_args, pe_args, db_conn):
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(gcp_args.project, pe_args.topic)

    patient_list = db_conn.get_n_patient_id(pe_args.num_patients)
    result_flag = True
    for patient_id in patient_list:
        data_to_send = patient_id.encode('utf-8')
        pub_response = publisher.publish(
            topic_path,
            data_to_send,
            patient_id=patient_id,
            blob_dir=pe_args.blob_dir,
            gcp_project=gcp_args.project,
            gcp_location=gcp_args.location,
            gcp_bucket=gcp_args.bucket,
            gcp_dataset=gcp_args.dataset,
            gcp_fhirstore=gcp_args.fhirstore,
            resource_types=pe_args.resource_types,
            count=pe_args.count
        )
        # submitted properly if 16 digit id returned
        result = len(pub_response.result()) == 16
        if result_flag and not result:
            result_flag = False  # basically one fail and return fail

    return result_flag


# PUT resources to HAPI fhir server
def put_resource(resource, fhir_data, fhir_server):
    url = fhir_server + resource + '/' + fhir_data['id']

    resp = requests.put(
        url, json=fhir_data, headers={"Content-Type": "application/fhir+json"}
    )
    output = json.loads(resp.text)
    return output


def sort_resources(output_path):
    profiles = ' '.join(MIMIC_FHIR_PROFILES)

    # Sorting done with a shell script since pandas sorting crashes with large file sizes
    process = subprocess.run(
        ['sh', 'py_mimic_fhir/scripts/sort_ndjson.sh', profiles, output_path],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    assert len(process.stderr) == 0
    return process


def export_patient_related_ndjson(db_conn, output_path):
    patient_list = db_conn.get_n_patient_id()
    patient_output_path = f'{output_path}/patients'

    create_folder_if_not_exists(output_path)
    create_folder_if_not_exists(patient_output_path)
    for patient_id in patient_list:
        logger.info(f'Exporting resources from patient: {patient_id}')
        patient_folder = f'{patient_output_path}/{patient_id}'
        create_folder_if_not_exists(patient_folder)

        resource_list = db_conn.get_resources_by_pat('patient', patient_id)
        write_ndjson_by_table_name('patient', patient_folder, resource_list)
        for table in MIMIC_PATIENT_TABLE_LIST:
            resource_list = db_conn.get_resources_by_pat(table, patient_id)
            write_ndjson_by_table_name(table, patient_folder, resource_list)


def export_data_related_ndjson(db_conn, output_path):
    data_output_path = f'{output_path}/data'
    create_folder_if_not_exists(output_path)
    create_folder_if_not_exists(data_output_path)

    for table in MIMIC_DATA_TABLE_LIST:
        query_table = f"SELECT fhir FROM mimic_fhir.{table}"
        resource_list = db_conn.read_query(query_table)
        write_ndjson_by_table_name(table, data_output_path, resource_list)


def create_folder_if_not_exists(folder_name):
    if not os.path.exists(folder_name):
        os.mkdir(folder_name)


def write_ndjson_by_table_name(table, output_folder, resource_list):
    output = [json.dumps(resource) for resource in resource_list]
    output_ndjson = '\n'.join(output)

    if len(output_ndjson) != 0:
        with open(f'{output_folder}/{table}.njdson', 'w') as f:
            f.write(output_ndjson)
