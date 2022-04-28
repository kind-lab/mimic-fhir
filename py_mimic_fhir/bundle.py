# Bundle classes and useful functions
# Two bundle classes made here:
#    1. Bundle - a FHIR transaction bundle with resources as entries
#    2. ErrBundle - When a bundle fails it is reorganized with ErrBundle and output
#
# The useful functions are primarily used to get links and resources for patient bundles

import logging
import requests
import json
import os
import pandas as pd
import numpy as np
from datetime import datetime

from py_mimic_fhir.db import (
    get_resources_by_pat, get_patient_resource, get_resource_by_id,
    get_n_patient_id, get_n_resources
)

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
    def __init__(self, name, table_list=[]):
        self.name = name
        self.table_list = table_list
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

    def generate(self, patient_id, db_conn):
        for table_name in self.table_list:
            resources = get_resources_by_pat(db_conn, table_name, patient_id)
            self.add_entry(resources)

    def json(self):
        bundle_json = self.__dict__
        bundle_json.pop('name')
        bundle_json.pop('table_list')
        return bundle_json

    # Send request out to HAPI server, validates on the server
    def request(
        self,
        fhir_server,
        err_path=None,
        split_flag=True,
        bundle_size=60,  # optimal based on testing, seems small but if no links is quick!
    ):
        output = True  # True until proven false
        if self.name in ['microbiology', 'medication']:
            split_flag = False

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
                bundle = Bundle(self.name, self.table_list)
                bundle.add_entry(resources)
                output_temp = bundle.request(
                    fhir_server, err_path=err_path, split_flag=False
                )
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


#----------------------------------------------------------------------------
# ---------------------- Bundle Support Functions ---------------------------
#----------------------------------------------------------------------------


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
