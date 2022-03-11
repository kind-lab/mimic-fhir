# FHIR bundle class with options to add entries and send requests to the server
# Created a Bundle class since fhir.resources did not allow construction of the entry
# and request in a pythonic way (there was validation built in that needed both set at once)

# Initialize logger - MIGRARTE THIS TO MAIN, should just pull in the logger, not the basicConfig
import logging

LOG_FORMAT = "%(levelname)s %(asctime)s - %(message)s"
logging.basicConfig(
    filename='log/bundle.log',
    filemode='a',
    format=LOG_FORMAT,
    level=logging.INFO,
    force=True
)

logger = logging.getLogger(__name__)

# Import the rest of the packages
import requests
import json
from pathlib import Path
import os
import pandas as pd
import numpy as np

from py_mimic_fhir import db


class Bundle():
    def __init__(self):
        self.resourceType = 'Bundle'
        self.type = 'transaction'
        self.entry = []

    def add_entry(self, resources):
        for resource in resources:
            if 'resourceType' not in resource:
                logging.error(f'Resource no resourceType: {resource}')
            new_request = {}
            new_request['method'] = 'PUT'
            new_request['url'] = resource['resourceType'] + '/' + resource['id']

            new_entry = {}
            new_entry['fullUrl'] = resource['id']
            new_entry['request'] = new_request

            new_entry['resource'] = resource

            self.entry.append(new_entry)

    def json(self):
        return self.__dict__

    def request(self, fhir_server, split_flag=False):
        output = True  # True until proven false

        # Split the entry into smaller bundles to speed up posting
        if split_flag:

            # Generate smaller bundles
            peak_bundle_size = 10  # optimal based on testing, seems small but if no links is quick!
            split_count = len(self.entry) // peak_bundle_size
            split_count = 1 if split_count == 0 else split_count  # for bundles smaller than peak_bundle_size

            entry_groups = np.array_split(self.entry, split_count)
            for entries in entry_groups:
                # Pull out resources from entries
                resources = [entry['resource'] for entry in entries]

                # Recreate smaller bundles and post
                bundle = Bundle()
                bundle.add_entry(resources)
                output_temp = bundle.request(fhir_server)
                if output_temp == False:
                    output = False

        else:
            resp = requests.post(
                fhir_server,
                json=self.json(),
                headers={"Content-Type": "application/fhir+json"}
            )
            resp_text = json.loads(resp.text)
            if resp_text['resourceType'] == 'OperationOutcome':
                logging.error(resp_text)
                output = False
        return output


# Generic function to get resources linked to patient from the DB
def get_resources_by_pat(db_conn, table_name, patient_id):
    q_resource = f"""
        SELECT fhir FROM mimic_fhir.{table_name}
        WHERE patient_id = '{patient_id}'
    """
    pd_resources = pd.read_sql_query(q_resource, db_conn)
    resources = pd_resources.fhir.to_list()

    return resources


# Generic function to get single resource from the DB
def get_patient_resource(db_conn, patient_id):
    q_resource = f"SELECT * FROM mimic_fhir.patient WHERE id='{patient_id}'"
    resource = pd.read_sql_query(q_resource, db_conn)

    return resource.fhir[0]


# Class to bundle all resources associated with one patient
class Bundler():
    def __init__(self, patient_id):
        self.patient_id = patient_id
        self.patient_bundle = Bundle()
        self.micro_bundle = Bundle()
        self.med_bundle = Bundle()
        self.lab_bundle = Bundle()
        self.icu_base_bundle = Bundle()
        self.icu_obs_bundle = Bundle()
        self.db_conn = db.db_conn()
        logging.info('----------- NEW BUNDLE -----------')
        logging.info(f'Patient_id: {patient_id}')

    def generate_all_bundles(self):
        self.generate_patient_bundle()
        self.generate_micro_bundle()
        #self.generate_med_bundle() # Activate when medication PR is integrated
        self.generate_lab_bundle()
        self.generate_icu_base_bundle()
        self.generate_icu_obs_bundle()

    def generate_patient_bundle(self):
        logging.info('Generating patient bundle')
        table_list = ['encounter', 'condition', 'procedure']

        # Add individual patient
        pat_resource = get_patient_resource(self.db_conn, self.patient_id)
        self.patient_bundle.add_entry([pat_resource])

        # Add all base patient resources for the Patient to the bundle
        for table_name in table_list:
            resources = get_resources_by_pat(
                self.db_conn, table_name, self.patient_id
            )
            self.patient_bundle.add_entry(resources)

    def generate_micro_bundle(self):
        logging.info('Generating micro bundle')
        table_list = [
            'observation_micro_test', 'observation_micro_org',
            'observation_micro_susc'
        ]

        # Add all micro resources associated with the Patient to the bundle
        for table_name in table_list:
            resources = get_resources_by_pat(
                self.db_conn, table_name, self.patient_id
            )
            self.micro_bundle.add_entry(resources)

    def generate_med_bundle(self):
        logging.info('Generating med bundle')
        table_list = [
            'medication_request', 'medication_dispense',
            'medication_administration'
        ]

        # Add all medication resources associated with the Patient to the bundle
        for table_name in table_list:
            resources = get_resources_by_pat(
                self.db_conn, table_name, self.patient_id
            )
            self.med_bundle.add_entry(resources)

    def generate_lab_bundle(self):
        logging.info('Generating lab bundle')
        table_list = ['observation_labs']

        # Add all lab resources associated with the Patient to the bundle
        for table_name in table_list:
            resources = get_resources_by_pat(
                self.db_conn, table_name, self.patient_id
            )
            self.lab_bundle.add_entry(resources)

    def generate_icu_base_bundle(self):
        logging.info('Generating icu base bundle')
        table_list = [
            'encounter_icu', 'procedure_icu', 'medication_administration_icu'
        ]

        # Add all ICU base resources associated with the Patient to the bundle
        for table_name in table_list:
            resources = get_resources_by_pat(
                self.db_conn, table_name, self.patient_id
            )
            self.icu_base_bundle.add_entry(resources)

    def generate_icu_obs_bundle(self):
        logging.info('Generating icu obs bundle')
        table_list = [
            'observation_chartevents', 'observation_datetimeevents',
            'observation_outputevents'
        ]

        # Add all ICU observation resources associated with the Patient to the bundle
        for table_name in table_list:
            resources = get_resources_by_pat(
                self.db_conn, table_name, self.patient_id
            )
            self.icu_obs_bundle.add_entry(resources)

    def post_all_bundles(self, fhir_server, split_flag=False):
        logging.info('------ POSTING BUNDLES ----------')
        response_list = []

        logging.info('Post patient bundle')
        response_list.append(
            self.patient_bundle.request(fhir_server, split_flag)
        )

        logging.info('Post micro bundle')
        response_list.append(self.micro_bundle.request(fhir_server))

        #self.med_bundle.request(fhir_server)
        logging.info('Post lab bundle')
        response_list.append(self.lab_bundle.request(fhir_server, split_flag))

        logging.info('Post icu_base bundle')
        response_list.append(
            self.icu_base_bundle.request(fhir_server, split_flag)
        )

        logging.info('Post icu_obs bundle')
        response_list.append(
            self.icu_obs_bundle.request(fhir_server, split_flag)
        )

        return response_list
