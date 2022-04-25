# Bundle classes and useful functions
# Three main bundle classes made here:
#    1. Bundle - a FHIR transaction bundle with resources as entries
#    2. Bundler - Create bundles for each of the MIMIC resources
#    3. ErrBundle - When a bundle fails it is reorganized with ErrBundle and output
#
# The useful functions are primarily used to get links and resources for patient bundles

import logging
import requests
import json
import os
import pandas as pd
import numpy as np
from datetime import datetime

from py_mimic_fhir import db

logger = logging.getLogger(__name__)


# The ErrBundle captures any failed bundles and writes them out to a logfile
class ErrBundle():
    def __init__(self, issue, bundle):
        self.issue = issue
        self.bundle_list = []
        self.set_id_list(bundle)

    def json(self):
        return self.__dict__

    # Capture all fhir ids from resources that were part of the failed bundle
    def set_id_list(self, bundle):
        for entry in bundle.entry:
            if 'meta' in entry['resource']:
                profile = entry['resource']['meta']['profile'][0].split('/')[-1]
            else:
                profile = entry['resource']['resourceType']
            fhir_id = entry['resource']['id']
            itm = {'fhir_profile': profile, 'id': fhir_id}
            self.bundle_list.append(itm)

    # Write err bundle to file
    def write(self, err_path):
        if not os.path.isdir(err_path):
            os.mkdir(err_path)

        day_of_week = datetime.now().strftime('%A').lower(
        )  # will overwrite each week
        with open(f'{err_path}err-bundles-{day_of_week}.json', 'a+') as errfile:
            json.dump(self.json(), errfile)
            errfile.write('\n')


# FHIR bundle class with options to add entries and send requests to the server
class Bundle():
    def __init__(self):
        self.resourceType = 'Bundle'
        self.type = 'transaction'
        self.entry = []

    # Create bundle entry with given resources
    def add_entry(self, resources):
        for resource in resources:
            if 'resourceType' not in resource:
                logger.error(f'Resource has no resourceType: {resource}')
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

    # Send request out to HAPI server, validates on the server
    def request(
        self,
        fhir_server,
        split_flag=False,
        err_path=None,
        bundle_size=60,  # optimal based on testing, seems small but if no links is quick!
    ):
        output = True  # True until proven false

        # Split the entry into smaller bundles to speed up posting
        if split_flag:
            # Generate smaller bundles
            split_count = len(self.entry) // bundle_size
            split_count = 1 if split_count == 0 else split_count  # for bundles smaller than bundle_size

            entry_groups = np.array_split(self.entry, split_count)
            for entries in entry_groups:
                # Pull out resources from entries
                resources = [entry['resource'] for entry in entries]

                # Recreate smaller bundles and post
                bundle = Bundle()
                bundle.add_entry(resources)
                output_temp = bundle.request(fhir_server, err_path=err_path)
                if output_temp == False:
                    output = False
        else:
            # Post full bundle, no restriction on bundle size
            resp = requests.post(
                fhir_server,
                json=self.json(),
                headers={"Content-Type": "application/fhir+json"}
            )
            resp_text = json.loads(resp.text)
            if resp_text['resourceType'] == 'OperationOutcome':
                #write out error bundles!
                errbundle = ErrBundle(resp_text['issue'], self)
                errbundle.write(err_path)

                logger.error(resp_text)
                output = False
        return output


# Class to bundle all resources associated with one patient
class Bundler():
    def __init__(self, patient_id, db_conn):
        self.patient_id = patient_id
        self.patient_bundle = Bundle()
        self.condition_bundle = Bundle()
        self.procedure_bundle = Bundle()
        self.specimen_bundle = Bundle()
        self.micro_bundle = Bundle()
        self.med_bundle = Bundle()
        self.lab_bundle = Bundle()
        self.icu_enc_bundle = Bundle()
        self.icu_base_bundle = Bundle()
        self.icu_medadmin_bundle = Bundle()
        self.icu_obs_bundle = Bundle()
        self.icu_ce_bundle = Bundle()
        self.db_conn = db_conn
        logger.info('----------- NEW BUNDLE -----------')
        logger.info(f'Patient_id: {patient_id}')

    def generate_all_bundles(self):
        self.generate_patient_bundle()
        self.generate_condition_bundle()
        self.generate_procedure_bundle()
        self.generate_specimen_bundle()
        self.generate_micro_bundle()
        self.generate_med_bundle()
        self.generate_lab_bundle()
        self.generate_icu_enc_bundle()
        self.generate_icu_base_bundle()
        self.generate_icu_medadmin_bundle()
        self.generate_icu_obs_bundle()

    # Add all resources from table_list for the patient to the bundle
    def fill_bundle(self, bundle, table_list):
        for table_name in table_list:
            resources = get_resources_by_pat(
                self.db_conn, table_name, self.patient_id
            )
            bundle.add_entry(resources)

    def generate_patient_bundle(self):
        logger.info('Generating patient bundle')
        table_list = ['encounter']

        # Add individual patient
        pat_resource = get_patient_resource(self.db_conn, self.patient_id)
        self.patient_bundle.add_entry([pat_resource])

        # Add all base patient resources for the Patient to the bundle
        self.fill_bundle(self.patient_bundle, table_list)

    def generate_condition_bundle(self):
        logger.info('Generating condition bundle')
        table_list = ['condition']
        self.fill_bundle(self.condition_bundle, table_list)

    def generate_procedure_bundle(self):
        logger.info('Generating procedure bundle')
        table_list = ['procedure']
        self.fill_bundle(self.procedure_bundle, table_list)

    def generate_specimen_bundle(self):
        logger.info('Generating specimen bundle')
        table_list = ['specimen', 'specimen_lab']
        self.fill_bundle(self.specimen_bundle, table_list)

    # Add all micro resources associated with the Patient to the bundle
    def generate_micro_bundle(self):
        logger.info('Generating micro bundle')
        table_list = [
            'observation_micro_test', 'observation_micro_org',
            'observation_micro_susc'
        ]

        self.fill_bundle(self.micro_bundle, table_list)

    # Add all medication resources associated with the Patient to the bundle
    def generate_med_bundle(self):
        logger.info('Generating med bundle')
        table_list = [
            'medication_request ', 'medication_dispense',
            'medication_administration'
        ]

        self.fill_bundle(self.med_bundle, table_list)

    def generate_icu_medadmin_bundle(self):
        logger.info('Generating medication administration ICU bundle')
        table_list = ['medication_administration_icu']
        self.fill_bundle(self.icu_medadmin_bundle, table_list)

    # Add all lab resources associated with the Patient to the bundle
    def generate_lab_bundle(self):
        logger.info('Generating lab bundle')
        table_list = ['observation_labevents']
        self.fill_bundle(self.lab_bundle, table_list)

    # Add all ICU base resources associated with the Patient to the bundle
    def generate_icu_enc_bundle(self):
        logger.info('Generating icu enc bundle')
        table_list = ['encounter_icu']
        self.fill_bundle(self.icu_enc_bundle, table_list)

    # Add all ICU base resources associated with the Patient to the bundle
    def generate_icu_base_bundle(self):
        logger.info('Generating icu base bundle')
        table_list = ['procedure_icu']  #, 'medication_administration_icu']
        self.fill_bundle(self.icu_base_bundle, table_list)

    # Add all ICU observation resources associated with the Patient to the bundle
    def generate_icu_obs_bundle(self):
        logger.info('Generating icu obs bundle')
        table_list = [
            'observation_chartevents', 'observation_datetimeevents',
            'observation_outputevents'
        ]
        self.fill_bundle(self.icu_obs_bundle, table_list)

    # Add all ICU observation chartevents resources associated with the Patient to the bundle
    # Useful in testing to get just the chartevents, since it is a larger grouping
    def generate_icu_ce_bundle(self):
        logger.info('Generating icu obs bundle')
        table_list = ['observation_chartevents']
        self.fill_bundle(self.icu_ce_bundle, table_list)

    # Post all bundles to the fhir server, recording their result status
    def post_all_bundles(self, fhir_server, split_flag=False, err_path=None):
        logger.info('------ POSTING BUNDLES ----------')
        response_list = []

        logger.info('Post patient bundle')
        response_list.append(
            self.patient_bundle.request(fhir_server, split_flag, err_path)
        )

        logger.info('Post condition bundle')
        response_list.append(
            self.condition_bundle.request(fhir_server, split_flag, err_path)
        )

        logger.info('Post procedure bundle')
        response_list.append(
            self.procedure_bundle.request(fhir_server, split_flag, err_path)
        )

        logger.info('Post specimen bundle')
        response_list.append(
            self.specimen_bundle.request(fhir_server, split_flag, err_path)
        )

        logger.info('Post micro bundle')
        response_list.append(
            self.micro_bundle.request(fhir_server, False, err_path)
        )

        logger.info('Post med bundle')
        response_list.append(
            self.med_bundle.request(fhir_server, False, err_path)
        )

        logger.info('Post lab bundle')
        response_list.append(
            self.lab_bundle.request(fhir_server, split_flag, err_path)
        )

        logger.info('Post icu_enc bundle')
        response_list.append(
            self.icu_enc_bundle.request(fhir_server, split_flag, err_path)
        )

        logger.info('Post icu_base bundle')
        response_list.append(
            self.icu_base_bundle.request(fhir_server, split_flag, err_path)
        )

        logger.info('Post icu_medadmin bundle')
        response_list.append(
            self.icu_medadmin_bundle.request(fhir_server, split_flag, err_path)
        )

        logger.info('Post icu_obs bundle')
        response_list.append(
            self.icu_obs_bundle.request(fhir_server, split_flag, err_path)
        )

        return response_list


#----------------------------------------------------------------------------
# ---------------------- Bundle Support Functions ---------------------------
#----------------------------------------------------------------------------


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


# Get any resource by its id
def get_resource_by_id(db_conn, profile, profile_id):
    q_resource = f"SELECT * FROM mimic_fhir.{profile} WHERE id='{profile_id}'"
    resource = pd.read_sql_query(q_resource, db_conn)

    return resource.fhir[0]


def get_n_patient_id(db_conn, n_patient):
    q_resource = f"SELECT * FROM mimic_fhir.patient LIMIT {n_patient}"
    resource = pd.read_sql_query(q_resource, db_conn)
    patient_ids = [fhir['id'] for fhir in resource.fhir]

    return patient_ids


def get_n_resources(db_conn, table, n_limit=0):
    if n_limit == 0:
        q_resource = f"SELECT * FROM mimic_fhir.{table}"
    else:
        q_resource = f"SELECT * FROM mimic_fhir.{table} LIMIT {n_limit}"
    resource = pd.read_sql_query(q_resource, db_conn)

    resources = []
    [resources.append(fhir) for fhir in resource.fhir]
    return resources


# After changes have been made to correct bundle errors, the bundle can be rerurn from file
def rerun_bundle_from_file(err_filename, db_conn, fhir_server):
    bundle_result = []

    with open(err_filename, 'r') as err_file:
        for err in err_file:
            bundle_list = json.loads(err)['bundle_list']
            for entry in bundle_list:
                resources = []

                #drop mimic prefix from profile to get mimic table name
                profile = entry['fhir_profile'].replace('-', '_')[6:]
                fhir_id = entry['id']
                resource = get_resource_by_id(db_conn, profile, fhir_id)
                resources.append(resource)
            bundle = Bundle()
            bundle.add_entry(resources)
            resp = bundle.request(fhir_server)
            bundle_result.append(resp)

    output = True
    if False in bundle_result:
        output = False
    return output
