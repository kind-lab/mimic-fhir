""".
Test script for different bundles in MIMIC-FHIR
Main tests are:
- Data bundle: Organization and Medication
- Patient bundle: Patient/Encounter/Condition/Procedure
- Meds bundle: MedicationRequest/MedicationDispense/MedicationAdministration
- Micro bundle: ObservationMicroTest/ObservationMicroOrg/ObservationMicroSusc
- Lab bundle: ObservationLabs
- ICU base bundle: EncounterICU/MedicationAdministrationICU
- ICU observation bundle: ObservationChartevents/ObservationOutputevents/ObservationDatetimeevents

"""

import json
import requests
import logging
import os
import subprocess
import pytest
import numpy as np

from fhir.resources.bundle import Bundle

logging.basicConfig(level=logging.INFO)

FHIR_SERVER = os.getenv('FHIR_SERVER')


def initialize_bundle():
    bundle = Bundle.construct()
    bundle.type = 'transaction'
    bundle.entry = []

    return bundle


def add_bundle_entry(bundle, resources):
    for resource in resources:
        new_request = {}
        new_request['method'] = 'PUT'
        new_request['url'] = resource['resourceType'] + '/' + resource['id']

        new_entry = {}
        new_entry['fullUrl'] = resource['id']
        new_entry['request'] = new_request

        new_entry['resource'] = resource

        bundle.entry.append(new_entry)

    return bundle


def bundle_request(bundle):
    #requests.post(url,  json = self.to_json(), headers={"Content-Type": "application/fhir+json"} )
    resp = requests.post(
        FHIR_SERVER,
        json=json.loads(bundle.json()),
        headers={"Content-Type": "application/fhir+json"}
    )
    output = json.loads(resp.text)
    if output['resourceType'] == 'OperationOutcome':
        logging.error(output)
    return output


def test_bad_bundle():
    bundle = initialize_bundle()
    bad_resource = [{'resourceType': 'BAD RESOURCE', 'id': '123'}]
    bundle = add_bundle_entry(bundle, bad_resource)
    output = bundle_request(bundle)
    assert output['resourceType'] == 'OperationOutcome'


def test_bad_code_in_bundle():
    pat_resource = {
        'resourceType': 'Patient',
        'id': '123456',
        'gender': 'FAKE CODE'
    }
    bundle = initialize_bundle()
    bad_resource = [pat_resource]
    bundle = add_bundle_entry(bundle, bad_resource)
    output = bundle_request(bundle)
    assert output['resourceType'] == 'OperationOutcome'


def test_patient_bundle(patient_bundle_resources):
    bundle = initialize_bundle()
    bundle = add_bundle_entry(bundle, patient_bundle_resources)
    output = bundle_request(bundle)
    logging.error(output)
    assert output['resourceType'] == 'Bundle'


def test_microbio_bundle(microbio_bundle_resources):
    bundle = initialize_bundle()
    bundle = add_bundle_entry(bundle, microbio_bundle_resources)
    output = bundle_request(bundle)
    logging.error(output)
    assert output['resourceType'] == 'Bundle'


def test_lab_bundle(lab_bundle_resources):
    bundle = initialize_bundle()
    bundle = add_bundle_entry(bundle, lab_bundle_resources)
    output = bundle_request(bundle)
    logging.error(output)
    assert output['resourceType'] == 'Bundle'


# Only passing a small portion of the meds here (~100)
def test_med_data_bundle(med_data_bundle_resources):
    bundle = initialize_bundle()
    bundle = add_bundle_entry(bundle, med_data_bundle_resources)
    output = bundle_request(bundle)
    logging.error(output)
    assert output['resourceType'] == 'Bundle'


# Only passing a small portion of the meds here (~100)
def test_iterative_med_data_bundle(med_data_bundle_resources):
    output_list = []
    resource_splits = np.array_split(med_data_bundle_resources, 5)
    for resource_list in resource_splits:
        bundle = initialize_bundle()
        bundle = add_bundle_entry(bundle, med_data_bundle_resources)
        output = bundle_request(bundle)
        output_list.append(output['resourceType'])
        logging.error(output)
    assert 'OperationOutcome' not in output_list


# Need to figure out how to get medication references working if only a subuset of the Medication resources have been posted
# OR just post all medication resources..
def test_med_pat_bundle(med_pat_bundle_resources):
    bundle = initialize_bundle()
    bundle = add_bundle_entry(bundle, med_pat_bundle_resources)
    output = bundle_request(bundle)
    logging.error(output)
    assert output['resourceType'] == 'Bundle'


# Test icu base bundle that include EncounterICU and MedicationAdminstrationICU
def test_icu_base_bundle(icu_base_bundle_resources):
    bundle = initialize_bundle()
    bundle = add_bundle_entry(bundle, icu_base_bundle_resources)
    output = bundle_request(bundle)
    logging.error(output)
    assert output['resourceType'] == 'Bundle'


# Test all observation resources coming out of the ICU
def test_icu_observation_bundle(icu_observation_bundle_resources):
    bundle = initialize_bundle()
    bundle = add_bundle_entry(bundle, icu_observation_bundle_resources)
    output = bundle_request(bundle)
    logging.error(output)
    assert output['resourceType'] == 'Bundle'
