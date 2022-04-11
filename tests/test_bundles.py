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
from datetime import datetime

#from fhir.resources.bundle import Bundle
from py_mimic_fhir.bundle import Bundle, Bundler, rerun_bundle_from_file, get_n_patient_id

FHIR_SERVER = os.getenv('FHIR_SERVER')
FHIR_BUNDLE_ERROR_PATH = os.getenv('FHIR_BUNDLE_ERROR_PATH')

# ---------------- Test Support Functions -----------------------


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


# ---------------- Test Functions --------------------


def test_bundler(db_conn):
    patient_id = get_n_patient_id(db_conn, 1)[0]
    bundler = Bundler(patient_id, db_conn)
    assert True


def test_bad_bundle(db_conn):
    q_resource = f"""
        SELECT fhir FROM mimic_fhir.patient LIMIT 1
    """
    pd_resources = pd.read_sql_query(q_resource, db_conn)
    resource = pd_resources.fhir[0]
    resource['gender'] = 'FAKE CODE'  # Will cause bundle to fail

    bundle = Bundle()
    bundle.add_entry([resource])
    response = bundle.request(FHIR_SERVER, err_path=FHIR_BUNDLE_ERROR_PATH)
    assert response == False


def test_patient_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    resource_list = ['encounter']
    patient_id = get_pat_id_with_links(db_conn, resource_list)
    split_flag = True  # Divide up bundles into smaller chunks

    # Create bundle and post it
    bundler = Bundler(patient_id, db_conn)
    bundler.generate_patient_bundle()
    response = bundler.patient_bundle.request(
        FHIR_SERVER, split_flag, FHIR_BUNDLE_ERROR_PATH
    )
    assert response


def test_condition_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    resource_list = ['condition']
    patient_id = get_pat_id_with_links(db_conn, resource_list)
    split_flag = True  # Divide up bundles into smaller chunks

    # Create bundle
    bundler = Bundler(patient_id, db_conn)

    # Generate and post patient bundle, must do first to avoid referencing issues
    bundler.generate_patient_bundle()
    bundler.patient_bundle.request(FHIR_SERVER)

    #  Generate and post lab bundle
    bundler.generate_condition_bundle()
    response = bundler.condition_bundle.request(
        FHIR_SERVER, split_flag, FHIR_BUNDLE_ERROR_PATH
    )
    logging.error(patient_id)
    assert response


def test_procedure_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    resource_list = ['procedure']
    patient_id = get_pat_id_with_links(db_conn, resource_list)
    split_flag = True  # Divide up bundles into smaller chunks

    # Create bundle
    bundler = Bundler(patient_id, db_conn)

    # Generate and post patient bundle, must do first to avoid referencing issues
    bundler.generate_patient_bundle()
    bundler.patient_bundle.request(FHIR_SERVER)

    #  Generate and post lab bundle
    bundler.generate_procedure_bundle()
    response = bundler.procedure_bundle.request(
        FHIR_SERVER, split_flag, FHIR_BUNDLE_ERROR_PATH
    )
    logging.error(patient_id)
    assert response


# Test posting specimen resources
def test_specimen_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    resource_list = ['specimen', 'specimen_lab']
    patient_id = get_pat_id_with_links(db_conn, resource_list)
    split_flag = True
    bundler = Bundler(patient_id, db_conn)

    # Generate patient first to make sure references are good
    bundler.generate_patient_bundle()
    bundler.patient_bundle.request(FHIR_SERVER)

    #  Generate and post spec bundle
    bundler.generate_specimen_bundle()
    response = bundler.specimen_bundle.request(
        FHIR_SERVER, split_flag, FHIR_BUNDLE_ERROR_PATH
    )
    logging.error(patient_id)
    assert response


def test_microbio_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    resource_list = [
        'observation_micro_test', 'observation_micro_org',
        'observation_micro_susc'
    ]
    patient_id = get_pat_id_with_links(db_conn, resource_list)
    split_flag = False  #Do not want to split up micro bundles

    # Create bundle
    bundler = Bundler(patient_id, db_conn)

    # Generate and post patient bundle, must do first to avoid referencing issues
    bundler.generate_patient_bundle()
    bundler.patient_bundle.request(FHIR_SERVER)

    # Generate and post specimen bundle, must do first to avoid referencing issues
    bundler.generate_specimen_bundle()
    bundler.specimen_bundle.request(FHIR_SERVER)

    #  Generate and post micro bundle
    bundler.generate_micro_bundle()
    response = bundler.micro_bundle.request(
        FHIR_SERVER, split_flag, FHIR_BUNDLE_ERROR_PATH
    )
    logging.error(patient_id)
    assert response


def test_lab_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    resource_list = ['observation_labevents']
    patient_id = get_pat_id_with_links(db_conn, resource_list)
    split_flag = True  # Divide up bundles into smaller chunks

    # Create bundle
    bundler = Bundler(patient_id, db_conn)

    # Generate and post patient bundle, must do first to avoid referencing issues
    bundler.generate_patient_bundle()
    bundler.patient_bundle.request(FHIR_SERVER)

    # Generate and post specimen bundle, must do first to avoid referencing issues
    bundler.generate_specimen_bundle()
    bundler.specimen_bundle.request(FHIR_SERVER)

    #  Generate and post lab bundle
    bundler.generate_lab_bundle()
    response = bundler.lab_bundle.request(
        FHIR_SERVER, split_flag, FHIR_BUNDLE_ERROR_PATH
    )
    logging.error(patient_id)
    assert response


def test_med_bundle(db_conn):
    resource_list = [
        'medication_request', 'medication_dispense', 'medication_administration'
    ]
    patient_id = get_pat_id_with_links(db_conn, resource_list)
    split_flag = False  # Do not break up meds right now, need to test further

    # Create bundle
    bundler = Bundler(patient_id, db_conn)

    # Generate and post patient bundle, must do first to avoid referencing issues
    bundler.generate_patient_bundle()
    bundler.patient_bundle.request(FHIR_SERVER)

    #  Generate and post medreq bundle
    bundler.generate_med_bundle()
    response = bundler.med_bundle.request(
        FHIR_SERVER, split_flag, FHIR_BUNDLE_ERROR_PATH
    )
    logging.error(patient_id)
    assert response


def test_icu_medadmin_bundle(db_conn):
    resource_list = ['medication_administration_icu']
    patient_id = get_pat_id_with_links(db_conn, resource_list)
    split_flag = False  # Do not break up meds right now, need to test further

    # Create bundle
    bundler = Bundler(patient_id, db_conn)

    # Generate and post patient bundle, must do first to avoid referencing issues
    bundler.generate_patient_bundle()
    bundler.patient_bundle.request(FHIR_SERVER)

    #  Generate and post medreq bundle
    bundler.generate_icu_medadmin_bundle()
    response = bundler.icu_medadmin_bundle.request(
        FHIR_SERVER, split_flag, FHIR_BUNDLE_ERROR_PATH
    )
    logging.error(patient_id)
    assert response


# Only passing a small portion of the meds here (~100)
def test_med_data_bundle(med_data_bundle_resources):
    # Can pass all meds if slicing is dropped
    resources = med_data_bundle_resources  #[0:100]
    split_flag = True  # Divide up bundles into smaller chunks
    bundle = Bundle()
    bundle.add_entry(resources)
    response = bundle.request(FHIR_SERVER, split_flag, FHIR_BUNDLE_ERROR_PATH)
    logging.error(response)
    assert response


def test_med_mix_data_bundle(med_mix_data_bundle_resources):
    # Can pass all meds if slicing is dropped
    resources = med_mix_data_bundle_resources  #[0:100]
    split_flag = True  # Divide up bundles into smaller chunks
    bundle = Bundle()
    bundle.add_entry(resources)
    response = bundle.request(FHIR_SERVER, split_flag, FHIR_BUNDLE_ERROR_PATH)
    logging.error(response)
    assert response


# Test icu base bundle that include EncounterICU and MedicationAdminstrationICU
def test_icu_base_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    resource_list = [
        'encounter_icu', 'procedure_icu', 'medication_administration_icu'
    ]
    patient_id = get_pat_id_with_links(db_conn, resource_list)
    split_flag = True  # Divide up bundles into smaller chunks

    # Create bundle
    bundler = Bundler(patient_id, db_conn)

    # Generate and post patient bundle, must do first to avoid referencing issues
    bundler.generate_patient_bundle()
    bundler.patient_bundle.request(FHIR_SERVER)

    #  Generate and post icu base bundle
    bundler.generate_icu_base_bundle()
    response = bundler.icu_base_bundle.request(
        FHIR_SERVER, split_flag, FHIR_BUNDLE_ERROR_PATH
    )
    logging.error(patient_id)
    assert response


def test_icu_enc_bundle_n_patients(db_conn):
    patient_ids = get_n_patient_id(db_conn, 2)
    split_flag = True  # Flag to subdivide bundles to speed up posting

    # Create bundle and post it
    result = True
    for patient_id in patient_ids:
        bundler = Bundler(patient_id, db_conn)
        bundler.generate_icu_enc_bundle()
        response = bundler.icu_enc_bundle.request(
            FHIR_SERVER, split_flag, FHIR_BUNDLE_ERROR_PATH
        )

        if response == False:
            result = False
    assert result


def test_med_bundle_n_patients(db_conn):
    patient_ids = get_n_patient_id(db_conn, 1)
    split_flag = False  # Do not subdivide, may cause issues in medications

    # Create bundle and post it
    result = True
    for patient_id in patient_ids:
        bundler = Bundler(patient_id, db_conn)
        bundler.generate_med_bundle()
        response = bundler.med_bundle.request(
            FHIR_SERVER, split_flag, FHIR_BUNDLE_ERROR_PATH
        )

        if response == False:
            result = False
    assert result


# Test all observation resources coming out of the ICU
def test_icu_observation_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    resource_list = [
        'observation_datetimeevents', 'observation_outputevents',
        'observation_chartevents'
    ]
    patient_id = get_pat_id_with_links(db_conn, resource_list)
    split_flag = True  # Flag to subdivide bundles to speed up posting

    # Create bundle
    bundler = Bundler(patient_id, db_conn)

    # Generate and post patient bundle, must do first to avoid referencing issues
    bundler.generate_patient_bundle()
    bundler.patient_bundle.request(FHIR_SERVER)

    # Generate and post icu enc bundle to avoid referencing issues
    bundler.generate_icu_enc_bundle()
    bundler.icu_enc_bundle.request(FHIR_SERVER)

    #  Generate and post icu observation bundle
    bundler.generate_icu_obs_bundle()
    response = bundler.icu_obs_bundle.request(
        FHIR_SERVER, split_flag, FHIR_BUNDLE_ERROR_PATH
    )
    logging.error(patient_id)
    assert response
