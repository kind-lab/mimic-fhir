import base64
import requests
import json
import pandas as pd
from datetime import datetime
from google.cloud import storage
from google.cloud import bigquery


def bundler(event, context):
    """Triggered from a message on a Cloud Pub/Sub topic.
      Args:
         event (dict): Event payload.
         context (google.cloud.functions.Context): Metadata for the event.
      """
    fhir_access_token = get_fhir_access_token()

    message = base64.b64decode(event['data']).decode('utf-8')
    blob_dir = event['attributes']['blob_dir']
    bundle_group = event['attributes']['bundle_group']
    patient_id = event['attributes']['patient_id']
    gcp_project = event['attributes']['gcp_project']
    gcp_location = event['attributes']['gcp_location']
    gcp_bucket = event['attributes']['gcp_bucket']
    gcp_dataset = event['attributes']['gcp_dataset']
    gcp_fhirstore = event['attributes']['gcp_fhirstore']

    starttime = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    bundle, resp_fhir = send_bundle_to_healthcare_api(
        message, fhir_access_token
    )
    endtime = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(resp_fhir)

    # Error will show up when the Healthcare API is unresponsive or crashes
    if 'error' in resp_fhir:
        print(bundle['id'])
        print(bundle)
        store_bad_bundle_in_cloud_storage(
            resp_fhir, gcp_bucket, bundle, blob_dir, error_key='error'
        )
        log_error_to_bigquery(
            bundle_group,
            bundle['id'],
            blob_dir,
            resp_fhir['error'],
            err_flg=True
        )
    # OperationOutcome will be returned when a validation issue has been found
    elif resp_fhir['resourceType'] == 'OperationOutcome':
        print(bundle['id'])
        print(bundle)
        store_bad_bundle_in_cloud_storage(
            resp_fhir, gcp_bucket, bundle, blob_dir
        )
        log_error_to_bigquery(
            gcp_project, bundle_group, bundle['id'], blob_dir,
            resp_fhir['issue'][0]
        )
    else:
        log_pass_to_bigquery(
            gcp_project, patient_id, bundle_group, bundle['id'], blob_dir,
            starttime, endtime
        )


def get_fhir_access_token():
    fhir_access_url = "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token?scopes=https://www.googleapis.com/auth/cloud-platform"
    fhir_access_headers = {"Metadata-Flavor": "Google"}
    resp_fhir_access = requests.get(
        fhir_access_url, headers=fhir_access_headers
    )
    return resp_fhir_access.json()['access_token']


def send_bundle_to_healthcare_api(
    message, fhir_access_token, gcp_project, gcp_location, gcp_dataset,
    gcp_fhirstore
):
    fhir_url = f"https://healthcare.googleapis.com/v1/projects/{gcp_project}/locations/{gcp_location}/datasets/{gcp_dataset}/fhirStores/{gcp_fhirstore}/fhir"
    fhir_headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {fhir_access_token}"
    }
    bundle = json.loads(message)
    resp_fhir = requests.post(fhir_url, json=bundle,
                              headers=fhir_headers).json()
    return bundle, resp_fhir


def store_bad_bundle_in_cloud_storage(
    resp_fhir, gcp_bucket, bundle, blob_dir, error_key='issue'
):
    err_bundle = {"error": resp_fhir[error_key], "bundle": bundle}

    storage_client = storage.Client()
    bucket = storage_client.get_bucket(gcp_bucket)
    blob = bucket.blob(f"{blob_dir}/error/{bundle['id']}")
    blob.upload_from_string(json.dumps(err_bundle))


def log_error_to_bigquery(
    gcp_project, bundle_group, bundle_id, bundle_dir, error, err_flg=False
):
    now = datetime.now()
    logtime = now.strftime("%Y-%m-%d %H:%M:%S")
    if err_flg:
        error_text = json.dumps(error)
        data = [
            [logtime, bundle_group, bundle_id, bundle_dir, error_text, "", ""]
        ]
    else:
        data = [
            [
                logtime, bundle_group, bundle_id, bundle_dir,
                error['details']['text'], error['diagnostics'],
                error['expression'][0]
            ]
        ]
    df = pd.DataFrame(
        data,
        columns=[
            'logtime', 'bundle_group', 'bundle_id', 'bundle_dir', 'error_text',
            'error_diagnostics', 'error_expression'
        ]
    )

    table_id = f'{gcp_project}.mimic_fhir_log.bundle_error'
    send_bigquery_insert(table_id, df)


def log_pass_to_bigquery(
    gcp_project, patient_id, bundle_group, bundle_id, bundle_dir, startime,
    endtime
):
    now = datetime.now()
    logtime = now.strftime("%Y-%m-%d %H:%M:%S")
    data = [
        [
            logtime, patient_id, bundle_group, bundle_id, bundle_dir, startime,
            endtime
        ]
    ]
    df = pd.DataFrame(
        data,
        columns=[
            'logtime', 'patient_id', 'bundle_group', 'bundle_id', 'bundle_dir',
            'starttime', 'endtime'
        ]
    )

    table_id = f'{gcp_project}.mimic_fhir_log.bundle_pass'
    send_bigquery_insert(table_id, df)


def send_bigquery_insert(table_id, df):
    ## Get BiqQuery Set up
    client = bigquery.Client()
    table = client.get_table(table_id)
    resp = client.insert_rows_from_dataframe(table, df)
    if resp == [[]]:
        print("Data logged!")
    else:
        print("FAILURE: NOT LOGGED")
        print(resp)
