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

#from fhir.resources.bundle import Bundle
from py_mimic_fhir.bundle import Bundle

FHIR_SERVER = os.getenv('FHIR_SERVER')


def test_bad_bundle():
    bundle = Bundle()
    bad_resource = [{'resourceType': 'BAD RESOURCE', 'id': '123'}]
    bundle.add_entry(bad_resource)
    bundle.request(FHIR_SERVER)
    assert bundle.response['resourceType'] == 'OperationOutcome'


def test_bad_code_in_bundle():
    pat_resource = {
        'resourceType': 'Patient',
        'id': '123456',
        'gender': 'FAKE CODE'
    }
    bundle = Bundle()
    bad_resource = [pat_resource]
    bundle.add_entry(bad_resource)
    bundle.request(FHIR_SERVER)
    assert bundle.response['resourceType'] == 'OperationOutcome'


def test_patient_bundle(patient_bundle_resources):
    bundle = Bundle()
    bundle.add_entry(patient_bundle_resources)
    bundle.request(FHIR_SERVER)
    assert bundle.response['resourceType'] == 'Bundle'


def test_microbio_bundle(microbio_bundle_resources):
    bundle = Bundle()
    bundle.add_entry(microbio_bundle_resources)
    bundle.request(FHIR_SERVER)
    assert bundle.response['resourceType'] == 'Bundle'


def test_lab_bundle(lab_bundle_resources):
    bundle = Bundle()
    bundle.add_entry(lab_bundle_resources)
    bundle.request(FHIR_SERVER)
    assert bundle.response['resourceType'] == 'Bundle'


# Only passing a small portion of the meds here (~100)
def test_med_data_bundle(med_data_bundle_resources):
    bundle = Bundle()
    bundle.add_entry(med_data_bundle_resources)
    bundle.request(FHIR_SERVER)
    assert bundle.response['resourceType'] == 'Bundle'


# Only passing a small portion of the meds here (~100)
def test_iterative_med_data_bundle(med_data_bundle_resources):
    response_list = []
    resource_splits = np.array_split(med_data_bundle_resources, 5)
    for resource_list in resource_splits:
        bundle = Bundle()
        bundle.add_entry(resource_list)
        bundle.request(FHIR_SERVER)
        response_list.append(bundle.response['resourceType'])
        logging.error(bundle.response)
    assert 'OperationOutcome' not in response_list


# Need to figure out how to get medication references working if only a subuset of the Medication resources have been posted
# OR just post all medication resources..
def test_med_pat_bundle(med_pat_bundle_resources):
    bundle = Bundle()
    bundle.add_entry(med_pat_bundle_resources)
    bundle.request(FHIR_SERVER)
    assert bundle.response['resourceType'] == 'Bundle'


# Test icu base bundle that include EncounterICU and MedicationAdminstrationICU
def test_icu_base_bundle(icu_base_bundle_resources):
    bundle = Bundle()
    bundle.add_entry(icu_base_bundle_resources)
    bundle.request(FHIR_SERVER)
    assert bundle.response['resourceType'] == 'Bundle'


# Test all observation resources coming out of the ICU
def test_icu_observation_bundle(icu_observation_bundle_resources):
    bundle = Bundle()
    bundle.add_entry(icu_observation_bundle_resources)
    bundle.request(FHIR_SERVER)
    assert bundle.response['resourceType'] == 'Bundle'
