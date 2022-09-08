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
    bundle_to_send = json.dumps(bundle.json()).encode('utf-8')
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(gcp_args.project, gcp_args.topic)
    response = publisher.publish(
        topic_path, bundle_to_send, blob_dir=gcp_args.blob_dir
    )

    # message id is 16 digit int that is returned if processed. Else an exception is returned
    assert len(response.result()) == 16


def test_organization_bundle(organization_bundle_resources, margs):
    resources = organization_bundle_resources
    bundle = Bundle('init_organization_data')
    bundle.add_entry(resources)
    response = bundle.request(margs.fhir_server, margs.err_path)
    logging.error(response)
    assert response


def test_organization_bundle_gcp(
    organization_bundle_resources, margs, gcp_args
):
    resources = organization_bundle_resources
    bundle = Bundle('organization')
    bundle.add_entry(resources)

    bundle_to_send = json.dumps(bundle.json()).encode('utf-8')
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(gcp_args.project, gcp_args.topic)
    response = publisher.publish(
        topic_path, bundle_to_send, blob_dir=gcp_args.blob_dir
    )

    # message id is 16 digit int that is returned if processed. Else an exception is returned
    assert len(response.result()) == 16


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


def test_location_bundle(location_bundle_resources, margs):
    resources = location_bundle_resources
    bundle = Bundle('init_location_data')
    bundle.add_entry(resources)
    response = bundle.request(margs.fhir_server, margs.err_path)
    logging.error(response)
    assert response


def test_location_bundle_gcp(location_bundle_resources, margs, gcp_args):
    resources = location_bundle_resources
    bundle = Bundle('location')
    bundle.add_entry(resources)

    bundle_to_send = json.dumps(bundle.json()).encode('utf-8')
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(gcp_args.project, gcp_args.topic)
    response = publisher.publish(
        topic_path, bundle_to_send, blob_dir=gcp_args.blob_dir
    )
    print(bundle.json()['id'])

    # message id is 16 digit int that is returned if processed. Else an exception is returned
    assert len(response.result()) == 16


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


def test_lab_bundle(db_conn, margs):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'lab'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient and spcimen bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs)
    validate_bundle('specimen', patient_id, db_conn, margs)
    response = validate_bundle(bundle_name, patient_id, db_conn, margs)
    assert response


def test_med_data_bundle(med_data_bundle_resources, margs):
    # Can pass all meds if slicing is dropped
    resources = med_data_bundle_resources[0:100]
    split_flag = True  # Divide up bundles into smaller chunks
    bundle = Bundle('medication-data')
    bundle.add_entry(resources)
    response = bundle.request(margs.fhir_server, margs.err_path)
    logging.error(response)
    assert response


def test_med_mix_data_bundle(med_mix_data_bundle_resources, margs):
    # Can pass all meds if slicing is dropped
    resources = med_mix_data_bundle_resources[0:100]
    split_flag = True  # Divide up bundles into smaller chunks
    bundle = Bundle('init-medication-mix')
    bundle.add_entry(resources)
    response = bundle.request(margs.fhir_server, margs.err_path)
    logging.error(response)
    assert response


def test_med_prep_bundle(db_conn, margs):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'medication-preparation'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs)
    response = validate_bundle(bundle_name, patient_id, db_conn, margs)
    assert response


def test_med_admin_bundle(db_conn, margs):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'medication-administration'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs)
    response = validate_bundle(bundle_name, patient_id, db_conn, margs)
    assert response


def test_icu_medication_bundle(db_conn, margs):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'icu-medication'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient and icu_encounter bundles, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs)
    validate_bundle('icu-encounter', patient_id, db_conn, margs)
    response = validate_bundle(bundle_name, patient_id, db_conn, margs)
    assert response


def test_icu_encounter_bundle(db_conn, margs):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'icu-encounter'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient bundle, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs)
    response = validate_bundle(bundle_name, patient_id, db_conn, margs)
    assert response


def test_icu_procedure_bundle(db_conn, margs):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'icu-procedure'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient and icu_encounter bundles, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs)
    validate_bundle('icu-encounter', patient_id, db_conn, margs)
    response = validate_bundle(bundle_name, patient_id, db_conn, margs)
    assert response


# Only passing a small portion of the meds here (~100)
def test_med_data_bundle(med_data_bundle_resources, margs):
    # Can pass all meds if slicing is dropped
    resources = med_data_bundle_resources[0:100]
    split_flag = True  # Divide up bundles into smaller chunks
    bundle = Bundle('init-medication')
    bundle.add_entry(resources)
    response = bundle.request(margs.fhir_server, margs.err_path)
    logging.error(response)
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
def test_icu_observation_bundle(db_conn, margs):
    # Get patient_id that has resources from the resource_list
    bundle_name = 'icu-observation'
    table_list = MIMIC_BUNDLE_TABLE_LIST[bundle_name]
    patient_id = get_pat_id_with_links(db_conn, table_list)

    # Generate and post patient and icu_encounter bundles, must do first to avoid referencing issues
    validate_bundle('patient', patient_id, db_conn, margs)
    validate_bundle('icu-encounter', patient_id, db_conn, margs)
    response = validate_bundle(bundle_name, patient_id, db_conn, margs)
    assert response
