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
import pandas as pd

#from fhir.resources.bundle import Bundle
from py_mimic_fhir.bundle import Bundle, Bundler, rerun_bundle_from_file

FHIR_SERVER = os.getenv('FHIR_SERVER')
FHIR_BUNDLE_ERROR_PATH = os.getenv('FHIR_BUNDLE_ERROR_PATH')


# Function to find links between a patient and certain resources.
# Allows for more complete testing if sending full bundle
def get_pat_id_with_links(db_conn, resource_list):
    q_resource = 'SELECT pat.fhir FROM mimic_fhir.patient pat'

    # Dynamically create query to find links between a patient and certain resources
    for idx, resource in enumerate(resource_list):
        q_resource = f"""{q_resource} 
            INNER JOIN mimic_fhir.{resource} t{idx}
                ON pat.id = t{idx}.patient_id 
        """
    q_resource = f'{q_resource} LIMIT 20;'

    resource = pd.read_sql_query(q_resource, db_conn)
    return resource.fhir[0]['id']


# Get n patient_ids
def get_n_patient_id(db_conn, n_patient):
    q_resource = f"SELECT * FROM mimic_fhir.patient LIMIT {n_patient}"
    resource = pd.read_sql_query(q_resource, db_conn)
    patient_ids = [fhir['id'] for fhir in resource.fhir]

    return patient_ids


def test_bundler(db_conn):
    patient_id = get_n_patient_id(db_conn, 1)[0]
    bundler = Bundler(patient_id)
    assert True


def test_bundle_patient_all_resources(db_conn):
    # Get n patient ids to then bundle and post
    patient_id = get_n_patient_id(db_conn, 1)[0]

    # Create bundle and post it
    bundler = Bundler(patient_id)
    bundler.generate_all_bundles()
    response_list = bundler.post_all_bundles(FHIR_SERVER)

    result = True
    if False in response_list:
        result = False
    assert result


def test_bundle_all_patient_bundles(db_conn):
    patient_ids = get_n_patient_id(db_conn, 10)
    split_flag = True  # Flag to subdivide bundles to speed up posting

    # Create bundle and post it
    result = True
    for patient_id in patient_ids:
        print(patient_id)
        bundler = Bundler(patient_id)
        bundler.generate_patient_bundle()
        response = bundler.patient_bundle.request(
            FHIR_SERVER, split_flag, FHIR_BUNDLE_ERROR_PATH
        )

        if response == False:
            result = False
    assert False  #result


def test_bundle_multiple_patient_all_resources(db_conn):
    # Get n patient ids to then bundle and post
    patient_ids = get_n_patient_id(db_conn, 10)
    split_flag = True  # Flag to subdivide bundles to speed up posting

    # Create bundle and post it
    result = True
    for patient_id in patient_ids:
        bundler = Bundler(patient_id)
        bundler.generate_all_bundles()
        response_list = bundler.post_all_bundles(
            FHIR_SERVER, split_flag, FHIR_BUNDLE_ERROR_PATH
        )

        if False in response_list:
            result = False
    assert result


def test_bad_bundle():
    bundle = Bundle()
    bad_resource = {
        'resourceType': 'Patient',
        'meta':
            {
                'profile':
                    [
                        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-patient'
                    ]
            },
        'id': '123456',
        'gender': 'FAKE CODE'
    }
    bundle.add_entry([bad_resource])
    bundle.add_entry([bad_resource])
    response = bundle.request(FHIR_SERVER, err_path=FHIR_BUNDLE_ERROR_PATH)
    assert response


def test_rerun_bundle(db_conn):
    err_file = f'{FHIR_BUNDLE_ERROR_PATH}err-bundles-2022-03-15.json'
    resp = rerun_bundle_from_file(err_file, db_conn, FHIR_SERVER)

    assert resp


def test_bundle_resources_from_list():
    q_resource = f"""
        SELECT fhir FROM mimic_fhir.observation_chartevents LIMIT 1000
    """
    pd_resources = pd.read_sql_query(q_resource, db_conn)
    resources = pd_resources.fhir.to_list()

    assert response


def test_bad_code_in_bundle():
    pat_resource = {
        'resourceType': 'Patient',
        'id': '123456',
        'gender': 'FAKE CODE'
    }
    bundle = Bundle()
    bad_resource = [pat_resource]
    bundle.add_entry(bad_resource)
    response = bundle.request(FHIR_SERVER)
    assert response == False


def test_patient_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    resource_list = ['encounter', 'condition', 'procedure']
    patient_id = get_pat_id_with_links(db_conn, resource_list)

    # Create bundle and post it
    bundler = Bundler(patient_id)
    bundler.generate_patient_bundle()
    response = bundler.patient_bundle.request(FHIR_SERVER)
    assert response


def test_microbio_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    resource_list = [
        'observation_micro_test', 'observation_micro_org',
        'observation_micro_susc'
    ]
    patient_id = get_pat_id_with_links(db_conn, resource_list)

    # Create bundle
    bundler = Bundler(patient_id)

    # Generate and post patient bundle, must do first to avoid referencing issues
    bundler.generate_patient_bundle()
    bundler.patient_bundle.request(FHIR_SERVER)

    #  Generate and post micro bundle
    bundler.generate_micro_bundle()
    response = bundler.micro_bundle.request(FHIR_SERVER)
    logging.error(patient_id)
    assert response


def test_lab_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    resource_list = ['observation_labs']
    patient_id = get_pat_id_with_links(db_conn, resource_list)

    # Create bundle
    bundler = Bundler(patient_id)

    # Generate and post patient bundle, must do first to avoid referencing issues
    bundler.generate_patient_bundle()
    bundler.patient_bundle.request(FHIR_SERVER)

    #  Generate and post lab bundle
    bundler.generate_lab_bundle()
    response = bundler.lab_bundle.request(FHIR_SERVER)
    logging.error(patient_id)
    assert response


def test_med_pat_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    resource_list = [
        'medication_request', 'medication_administration'
    ]  # Add medication_dispense after updating IG
    patient_id = get_pat_id_with_links(db_conn, resource_list)

    # Create bundle
    bundler = Bundler(patient_id)

    # Generate and post patient bundle, must do first to avoid referencing issues
    bundler.generate_patient_bundle()
    bundler.patient_bundle.request(FHIR_SERVER)

    #  Generate and post micro bundle
    bundler.generate_med_bundle()
    response = bundler.med_bundle.request(FHIR_SERVER)
    logging.error(patient_id)
    assert response


# Only passing a small portion of the meds here (~100)
def test_med_data_bundle_whole(med_data_bundle_resources):
    resources = med_data_bundle_resources  #[0:1000]
    bundle = Bundle()
    bundle.add_entry(resources)
    response = bundle.request(FHIR_SERVER, split_flag=True)
    logging.error(response)
    assert response


# Need to figure out how to get medication references working if only a subuset of the Medication resources have been posted
# OR just post all medication resources..
def test_med_data_bundle(db_conn):
    bundle = Bundle()
    bundle.add_entry(med_pat_bundle_resources)
    bundle.request(FHIR_SERVER)
    assert bundle.response


# Test icu base bundle that include EncounterICU and MedicationAdminstrationICU
def test_icu_base_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    resource_list = [
        'encounter_icu', 'procedure_icu', 'medication_administration_icu'
    ]
    patient_id = get_pat_id_with_links(db_conn, resource_list)

    # Create bundle
    bundler = Bundler(patient_id)

    # Generate and post patient bundle, must do first to avoid referencing issues
    bundler.generate_patient_bundle()
    bundler.patient_bundle.request(FHIR_SERVER)

    #  Generate and post icu base bundle
    bundler.generate_icu_base_bundle()
    response = bundler.icu_base_bundle.request(FHIR_SERVER)
    logging.error(patient_id)
    assert response


def test_icu_enc_bundle_n_patients(db_conn):
    patient_ids = get_n_patient_id(db_conn, 100)
    split_flag = True  # Flag to subdivide bundles to speed up posting

    # Create bundle and post it
    result = True
    for patient_id in patient_ids:
        bundler = Bundler(patient_id)
        bundler.generate_icu_enc_bundle()
        response = bundler.icu_enc_bundle.request(
            FHIR_SERVER, split_flag, FHIR_BUNDLE_ERROR_PATH
        )

        if response == False:
            result = False
    assert result


# Test all observation resources coming out of the ICU
def test_icu_observation_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    resource_list = [
        'observation_chartevents', 'observation_datetimeevents',
        'observation_outputevents'
    ]
    patient_id = get_pat_id_with_links(db_conn, resource_list)

    # Create bundle
    bundler = Bundler(patient_id)

    # Generate and post patient bundle, must do first to avoid referencing issues
    bundler.generate_patient_bundle()
    bundler.patient_bundle.request(FHIR_SERVER)

    #  Generate and post icu observation bundle
    bundler.generate_icu_obs_bundle()
    response = bundler.icu_obs_bundle.request(FHIR_SERVER)
    logging.error(patient_id)
    assert response


def test_post_1000_resources(db_conn):
    q_resource = f"""
        SELECT fhir FROM mimic_fhir.observation_chartevents LIMIT 40000
    """
    pd_resources = pd.read_sql_query(q_resource, db_conn)
    resources = pd_resources.fhir.to_list()

    bundle = Bundle()
    bundle.add_entry(resources)
    resp = bundle.request(
        FHIR_SERVER, True, err_path=FHIR_BUNDLE_ERROR_PATH, bundle_size=50
    )
    assert resp


def test_bundle_multiple_lab_resources(db_conn):
    # Get n patient ids to then bundle and post
    patient_ids = get_n_patient_id(db_conn, 30)
    split_flag = True  # Flag to subdivide bundles to speed up posting

    # Create bundle and post it
    result = True
    for patient_id in patient_ids:
        bundler = Bundler(patient_id)
        bundler.generate_lab_bundle()
        resp = bundler.lab_bundle.request(FHIR_SERVER, split_flag)

        if resp == False:
            result = False
    assert result


def test_largest_bundle():
    # Bundle is 44,277 resources!
    # Ran for ~20 minutes without finishing...
    # I was posting 1000 resources in 6 seconds, so ~44,000 should be about 5 minutes...
    # Keep playing with this
    patient_id = '77e10fd0-6a1c-5547-a130-fae1341acf36'
    bundler = Bundler(patient_id)
    bundler.generate_icu_obs_bundle()
    split_flag = True  # send bundle in smaller chunks
    resp = bundler.icu_obs_bundle.request(FHIR_SERVER, split_flag)
    assert resp


def test_largest_icu_ce_bundle():
    # Bundle is ~42,000
    patient_id = '77e10fd0-6a1c-5547-a130-fae1341acf36'
    bundler = Bundler(patient_id)
    bundler.generate_icu_ce_bundle()
    split_flag = True  # send bundle in smaller chunks
    resp = bundler.icu_ce_bundle.request(FHIR_SERVER, split_flag)
    assert resp
