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

from google.cloud import pubsub_v1

#from fhir.resources.bundle import Bundle
from py_mimic_fhir.bundle import Bundle
from py_mimic_fhir.db import get_n_patient_id, get_pat_id_with_links
from py_mimic_fhir.lookup import MIMIC_BUNDLE_TABLE_LIST
from py_mimic_fhir.validate import validate_bundle


# ---------------- Test Functions --------------------
def test_bad_bundle(db_conn, margs):
    q_resource = f"""
        SELECT fhir FROM mimic_fhir.patient LIMIT 1
    """
    pd_resources = pd.read_sql_query(q_resource, db_conn)
    resource = pd_resources.fhir[0]
    resource['gender'] = 'FAKE CODE'  # Will cause bundle to fail

    bundle = Bundle(name='bad_bundle')
    bundle.add_entry([resource])
    response = bundle.request(margs.fhir_server, margs.err_path)
    assert response == False


def test_bad_bundle_gcp(db_conn, margs, gcp_args):
    q_resource = f"""
        SELECT fhir FROM mimic_fhir.patient LIMIT 1
    """
    pd_resources = pd.read_sql_query(q_resource, db_conn)
    resource = pd_resources.fhir[0]
    resource['gender'] = 'FAKE CODE'  # Will cause bundle to fail

    bundle = Bundle(name='bad-bundle')
    bundle.add_entry([resource])
    response = bundle.publish(gcp_args)

    assert response


def test_bad_ref_bundle_gcp(db_conn, margs, gcp_args):
    q_resource = f"""
        SELECT fhir FROM mimic_fhir.encounter LIMIT 1
    """
    pd_resources = pd.read_sql_query(q_resource, db_conn)
    resource = pd_resources.fhir[0]
    resource['subject'] = {"reference": "Patient/DOES_NOT_EXISSSSST"}

    bundle = Bundle(name='bad-bundle')
    bundle.add_entry([resource])
    response = bundle.publish(gcp_args)

    assert response


def test_organization_bundle(organization_bundle_resources, margs, gcp_args):
    resources = organization_bundle_resources
    bundle = Bundle('init-org-data')
    bundle.add_entry(resources)
    if margs.validator == 'HAPI':
        response = bundle.request(margs.fhir_server, margs.err_path)
    elif margs.validator == 'GCP':
        response = bundle.publish(gcp_args)
    else:
        response = False
    assert response


def test_patient_bundle(db_conn, margs, gcp_args):
    # Get patient_id that has resources from the resource_list
    resource_list = ['encounter']  # omit patient table for this search
    patient_id = get_pat_id_with_links(db_conn, resource_list)

    # Create bundle and post it
    response = validate_bundle('patient', patient_id, db_conn, margs, gcp_args)
    assert response


def test_condition_bundle(db_conn, margs, gcp_args):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'condition'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs, gcp_args)
    response = validate_bundle(
        bundle_name, patient_id, db_conn, margs, gcp_args
    )
    assert response


def test_location_bundle(location_bundle_resources, margs, gcp_args):
    resources = location_bundle_resources
    bundle = Bundle('init-location-data')
    bundle.add_entry(resources)
    if margs.validator == 'HAPI':
        response = bundle.request(margs.fhir_server, margs.err_path)
    elif margs.validator == 'GCP':
        response = bundle.publish(gcp_args)
    else:
        response = False
    assert response


def test_procedure_bundle(db_conn, margs, gcp_args):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'procedure'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs, gcp_args)
    response = validate_bundle(
        bundle_name, patient_id, db_conn, margs, gcp_args
    )
    assert response


# Test posting specimen resources
def test_specimen_bundle(db_conn, margs, gcp_args):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'specimen'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs, gcp_args)
    response = validate_bundle(
        bundle_name, patient_id, db_conn, margs, gcp_args
    )
    assert response


def test_microbiology_bundle(db_conn, margs, gcp_args):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'microbiology'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient and specimen bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs, gcp_args)
    validate_bundle('specimen', patient_id, db_conn, margs, gcp_args)
    response = validate_bundle(
        bundle_name, patient_id, db_conn, margs, gcp_args
    )
    assert response


def test_lab_bundle(db_conn, margs, gcp_args):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'lab'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient and spcimen bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs, gcp_args)
    validate_bundle('specimen', patient_id, db_conn, margs, gcp_args)
    response = validate_bundle(
        bundle_name, patient_id, db_conn, margs, gcp_args
    )
    assert response


# Only passing a small portion of the meds here (~100)
def test_med_data_bundle(med_data_bundle_resources, margs, gcp_args):
    # Can pass all meds if slicing is dropped
    resources = med_data_bundle_resources  #[0:1000]
    split_flag = True  # Divide up bundles into smaller chunks
    bundle = Bundle('init-medication')
    bundle.add_entry(resources)
    if margs.validator == 'HAPI':
        response = bundle.request(margs.fhir_server, margs.err_path)
    elif margs.validator == 'GCP':
        response = bundle.publish(gcp_args)
    else:
        response = False
    assert response


def test_med_mix_data_bundle(med_mix_data_bundle_resources, margs, gcp_args):
    # Can pass all meds if slicing is dropped
    resources = med_mix_data_bundle_resources  #[0:100]
    split_flag = True  # Divide up bundles into smaller chunks
    bundle = Bundle('init-medication-mix')
    bundle.add_entry(resources)
    if margs.validator == 'HAPI':
        response = bundle.request(margs.fhir_server, margs.err_path)
    elif margs.validator == 'GCP':
        response = bundle.publish(gcp_args)
    else:
        response = False
    assert response


def test_med_workflow_bundle(db_conn, margs, gcp_args):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'medication-workflow'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs, gcp_args)
    response = validate_bundle(
        bundle_name, patient_id, db_conn, margs, gcp_args
    )
    assert response


def test_med_prep_bundle(db_conn, margs, gcp_args):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'medication-preparation'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs, gcp_args)
    response = validate_bundle(
        bundle_name, patient_id, db_conn, margs, gcp_args
    )
    assert response


def test_med_admin_bundle(db_conn, margs, gcp_args):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'medication-administration'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs, gcp_args)
    validate_bundle(
        'medication-preparation', patient_id, db_conn, margs, gcp_args
    )
    response = validate_bundle(
        bundle_name, patient_id, db_conn, margs, gcp_args
    )
    assert response


def test_icu_medication_bundle(db_conn, margs, gcp_args):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'icu-medication'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient and icu_encounter bundles, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs, gcp_args)
    validate_bundle('icu-encounter', patient_id, db_conn, margs, gcp_args)
    response = validate_bundle(
        bundle_name, patient_id, db_conn, margs, gcp_args
    )
    assert response


def test_icu_encounter_bundle(db_conn, margs, gcp_args):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'icu-encounter'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs, gcp_args)
    response = validate_bundle(
        bundle_name, patient_id, db_conn, margs, gcp_args
    )
    assert response


def test_icu_procedure_bundle(db_conn, margs, gcp_args):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'icu-procedure'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient and icu_encounter bundles, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs, gcp_args)
    validate_bundle('icu-encounter', patient_id, db_conn, margs, gcp_args)
    response = validate_bundle(
        bundle_name, patient_id, db_conn, margs, gcp_args
    )
    assert response


def test_med_bundle_n_patients(db_conn, margs):
    patient_ids = get_n_patient_id(db_conn, 1)

    # Create bundle and post it
    result = True
    for patient_id in patient_ids:
        # Generate and post patient bundle, must do first to avoid referencing issues
        validate_bundle('patient', patient_id, db_conn, margs)
        response1 = validate_bundle(
            'medication-preparation', patient_id, db_conn, margs
        )
        response2 = validate_bundle(
            'medication-administration', patient_id, db_conn, margs
        )

        if response1 & response2:
            result = True
        else:
            result = False
    assert result


# Test all observation resources coming out of the ICU
def test_icu_observation_bundle(db_conn, margs, gcp_args):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'icu-observation'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    #Generate and post patient and icu_encounter bundles, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs, gcp_args)
    validate_bundle('icu-encounter', patient_id, db_conn, margs, gcp_args)
    response = validate_bundle(
        bundle_name, patient_id, db_conn, margs, gcp_args
    )

    assert response


# -------------- ED BUNDLES -----------------------
# 'ed-base': ['encounter_ed', 'procedure_ed'],
# 'ed-observation': ['observation_ed', 'observation_vitalsigns'],
# 'ed-medication': ['medication_statement_ed', 'medication_dispense_ed']


# Test ED encounter and procedure resources
def test_ed_base_bundle(db_conn, margs, gcp_args):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'ed-base'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    #Generate and post patient and icu_encounter bundles, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs, gcp_args)
    response = validate_bundle(
        bundle_name, patient_id, db_conn, margs, gcp_args
    )

    assert response


# Test ED observation resources
def test_ed_observation_bundle(db_conn, margs, gcp_args):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'ed-observation'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    #Generate and post patient and icu_encounter bundles, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs, gcp_args)
    validate_bundle('ed-base', patient_id, db_conn, margs, gcp_args)
    response = validate_bundle(
        bundle_name, patient_id, db_conn, margs, gcp_args
    )

    assert response


# Test ED medication resources
def test_ed_medication_bundle(db_conn, margs, gcp_args):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'ed-medication'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    #Generate and post patient and icu_encounter bundles, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs, gcp_args)
    validate_bundle('ed-base', patient_id, db_conn, margs, gcp_args)
    response = validate_bundle(
        bundle_name, patient_id, db_conn, margs, gcp_args
    )

    assert response