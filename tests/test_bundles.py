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
from py_mimic_fhir.bundle import Bundle, rerun_bundle_from_file, get_n_patient_id
from py_mimic_fhir.lookup import MIMIC_BUNDLE_TABLE_LIST

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


def validate_bundle(bundle_name, patient_id, db_conn):
    bundle = Bundle(bundle_name, MIMIC_BUNDLE_TABLE_LIST[bundle_name])
    bundle.generate(patient_id, db_conn)
    response = bundle.request(FHIR_SERVER, FHIR_BUNDLE_ERROR_PATH)
    return response


# ---------------- Test Functions --------------------


def test_bad_bundle(db_conn):
    q_resource = f"""
        SELECT fhir FROM mimic_fhir.patient LIMIT 1
    """
    pd_resources = pd.read_sql_query(q_resource, db_conn)
    resource = pd_resources.fhir[0]
    resource['gender'] = 'FAKE CODE'  # Will cause bundle to fail

    bundle = Bundle('bad_bundle')
    bundle.add_entry([resource])
    response = bundle.request(FHIR_SERVER, err_path=FHIR_BUNDLE_ERROR_PATH)
    assert response == False


def test_patient_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    resource_list = ['encounter']  # omit patient table for this search
    patient_id = get_pat_id_with_links(db_conn, resource_list)

    # Create bundle and post it
    response = validate_bundle('patient', patient_id, db_conn)
    assert response


def test_condition_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'condition'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn)
    response = validate_bundle(bundle_name, patient_id, db_conn)
    assert response


def test_procedure_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'procedure'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn)
    response = validate_bundle(bundle_name, patient_id, db_conn)
    assert response


# Test posting specimen resources
def test_specimen_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'specimen'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn)
    response = validate_bundle(bundle_name, patient_id, db_conn)
    assert response


def test_microbiology_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'microbiology'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient and specimen bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn)
    validate_bundle('specimen', patient_id, db_conn)
    response = validate_bundle(bundle_name, patient_id, db_conn)
    assert response


def test_lab_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'lab'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient and spcimen bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn)
    validate_bundle('specimen', patient_id, db_conn)
    response = validate_bundle(bundle_name, patient_id, db_conn)
    assert response


def test_med_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'medication'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn)
    response = validate_bundle(bundle_name, patient_id, db_conn)
    assert response


def test_icu_medication_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'icu_medication'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient and icu_encounter bundles, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn)
    validate_bundle('icu_encounter', patient_id, db_conn)
    response = validate_bundle(bundle_name, patient_id, db_conn)
    assert response


def test_icu_encounter_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'icu_encounter'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn)
    response = validate_bundle(bundle_name, patient_id, db_conn)
    assert response


def test_icu_procedure_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'icu_procedure'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient and icu_encounter bundles, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn)
    validate_bundle('icu_encounter', patient_id, db_conn)
    response = validate_bundle(bundle_name, patient_id, db_conn)
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


def test_med_bundle_n_patients(db_conn):
    patient_ids = get_n_patient_id(db_conn, 1)

    # Create bundle and post it
    result = True
    for patient_id in patient_ids:
        # Generate and post patient bundle, must do first to avoid referencing issues
        validate_bundle('patient', patient_id, db_conn)
        response = validate_bundle('medication', patient_id, db_conn)

        if response == False:
            result = False
    assert result


# Test all observation resources coming out of the ICU
def test_icu_observation_bundle(db_conn):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'icu_observation'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient and icu_encounter bundles, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn)
    validate_bundle('icu_encounter', patient_id, db_conn)
    response = validate_bundle(bundle_name, patient_id, db_conn)
    assert response
