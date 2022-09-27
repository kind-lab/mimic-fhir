import base64
import requests
import json
import pandas as pd
from datetime import datetime
from google.cloud import storage
from google.cloud import bigquery


def patient_everything(event, context):
    """Triggered from a message on a Cloud Pub/Sub topic.
      Args:
         event (dict): Event payload.
         context (google.cloud.functions.Context): Metadata for the event.
      """
    fhir_access_token = get_fhir_access_token()
    message = base64.b64decode(event['data']).decode('utf-8')
    args = PatientEverythingArgs(event)

    print(args.patient_id)
    send_patient_everything(args, fhir_access_token)


def get_fhir_access_token():
    fhir_access_url = "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token?scopes=https://www.googleapis.com/auth/cloud-platform"
    fhir_access_headers = {"Metadata-Flavor": "Google"}
    resp_fhir_access = requests.get(
        fhir_access_url, headers=fhir_access_headers
    )
    return resp_fhir_access.json()['access_token']


def send_patient_everything(args, fhir_access_token, page_num=1, link=None):

    print(f'page_num: {page_num}')

    if page_num == 1:
        fhir_url = f"https://healthcare.googleapis.com/v1/projects/{args.gcp_project}/locations/{args.gcp_location}/datasets/{args.gcp_dataset}/fhirStores/{args.gcp_fhirstore}/fhir/Patient/{args.patient_id}/$everything?_count={args.count}&_type={args.resource_types}"
    else:
        fhir_url = link
        print(link)

    fhir_headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {fhir_access_token}"
    }

    resp_fhir = requests.get(fhir_url, headers=fhir_headers).json()
    print(resp_fhir)

    # Error will show up when the Healthcare API is unresponsive or crashes
    if 'error' in resp_fhir:
        log_error_to_bigquery(args, resp_fhir['error'], page_num, err_flg=True)
        print(resp_fhir['error'])
    # OperationOutcome will be returned when a validation issue has been found
    elif resp_fhir['resourceType'] == 'OperationOutcome':
        log_error_to_bigquery(args, resp_fhir['issue'][0], page_num)
        print(resp_fhir['issue'][0])
    elif ((resp_fhir['resourceType'] == 'Bundle') and ('link' in resp_fhir)):
        stored_filename = store_bundle_in_storage(args, resp_fhir, page_num)
        log_pass_to_bigquery(args, page_num, stored_filename)

        link_info = [
            resp for resp in resp_fhir['link'] if resp['relation'] == 'next'
        ]
        if len(link_info) > 0:
            send_patient_everything(
                args, fhir_access_token, page_num + 1, link_info[0]['url']
            )
    else:
        stored_filename = store_bundle_in_storage(args, resp_fhir, page_num)
        log_pass_to_bigquery(args, page_num, stored_filename)

    return resp_fhir


def store_bundle_in_storage(args, resp_fhir, page_num):
    bundle = resp_fhir

    storage_client = storage.Client()
    bucket = storage_client.get_bucket(args.gcp_bucket)
    filename = f"{args.blob_dir}/patient-{args.patient_id}-page{page_num}"
    blob = bucket.blob(filename)
    blob.upload_from_string(json.dumps(bundle))

    return filename


##############################################
############ BIGQUERY LOGGING ################
##############################################
def log_error_to_bigquery(args, error, page_num, err_flg=False):
    now = datetime.now()
    logtime = now.strftime("%Y-%m-%d %H:%M:%S")
    if err_flg:
        error_text = json.dumps(error)
        data = [[logtime, args.patient_id, args.resource_types, error_text, ""]]
    else:
        error_diagnostics = error['diagnostics'
                                 ] if 'diagnostics' in error else ""
        error_text = error['details']['text'] if 'details' in error else ""
        data = [
            [
                logtime, args.patient_id, page_num, args.resource_types,
                error_text, error_diagnostics
            ]
        ]
    df = pd.DataFrame(
        data,
        columns=[
            'logtime', 'patient_id', 'page_num', 'resource_types', 'error_text',
            'error_diagnostics'
        ]
    )

    table_id = f'{args.gcp_project}.mimic_fhir_log.pat_everything_error'
    send_bigquery_insert(table_id, df)


def log_pass_to_bigquery(args, page_num, gcp_filename):
    now = datetime.now()
    logtime = now.strftime("%Y-%m-%d %H:%M:%S")
    data = [
        [logtime, args.patient_id, page_num, args.resource_types, gcp_filename]
    ]
    df = pd.DataFrame(
        data,
        columns=[
            'logtime', 'patient_id', 'page_num', 'resource_types',
            'gcp_filename'
        ]
    )

    table_id = f'{args.gcp_project}.mimic_fhir_log.pat_everything_pass'
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


class PatientEverythingArgs():
    def __init__(self, event):
        self.blob_dir = event['attributes']['blob_dir']
        self.patient_id = event['attributes']['patient_id']
        self.gcp_project = event['attributes']['gcp_project']
        self.gcp_location = event['attributes']['gcp_location']
        self.gcp_bucket = event['attributes']['gcp_bucket']
        self.gcp_dataset = event['attributes']['gcp_dataset']
        self.gcp_fhirstore = event['attributes']['gcp_fhirstore']
        self.resource_types = event['attributes']['resource_types']
        self.count = event['attributes']['count']
