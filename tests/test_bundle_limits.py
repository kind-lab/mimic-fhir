import os
import pytest
import pandas as pd

from py_mimic_fhir.bundle import Bundle, rerun_bundle_from_file, get_n_patient_id
from py_mimic_fhir.lookup import MIMIC_BUNDLE_TABLE_LIST
from py_mimic_fhir.validate import validate_all_bundles

FHIR_SERVER = os.getenv('FHIR_SERVER')
FHIR_BUNDLE_ERROR_PATH = os.getenv('FHIR_BUNDLE_ERROR_PATH')


def test_bundle_with_lookup(db_conn):
    response_list = []
    patient_id = get_n_patient_id(db_conn, 1)[0]
    for name, table_list in MIMIC_BUNDLE_TABLE_LIST.items():
        # Create bundle and post it
        bundle = Bundle(name, table_list)
        bundle.generate(patient_id, db_conn)
        response_list.append(
            bundle.request(FHIR_SERVER, FHIR_BUNDLE_ERROR_PATH)
        )
    assert False not in response_list


def test_n_patient_bundles(db_conn):
    patient_ids = get_n_patient_id(db_conn, 1)
    bundle_name = 'patient'

    # Create bundle and post it
    result = True
    for patient_id in patient_ids:
        print(patient_id)
        bundle = Bundle(bundle_name, MIMIC_BUNDLE_TABLE_LIST[bundle_name])
        bundle.generate(patient_id, db_conn)
        response = bundle.request(FHIR_SERVER, FHIR_BUNDLE_ERROR_PATH)
        if response == False:
            result = False
    assert result


def test_n_patient_bundles_all_resources(db_conn):
    # Get n patient ids to then bundle and post
    patient_ids = get_n_patient_id(db_conn, 1)
    bundle_name = 'lab'

    # Create bundle and post it
    result = True
    for patient_id in patient_ids:
        response_list = validate_all_bundles(
            patient_id, db_conn, FHIR_SERVER, FHIR_BUNDLE_ERROR_PATH
        )
        if False in response_list:
            result = False
    assert result


def test_rerun_bundle(db_conn):
    day_of_week = datetime.now().strftime('%A').lower()
    err_file = f'{FHIR_BUNDLE_ERROR_PATH}err-bundles-{day_of_week}.json'
    resp = rerun_bundle_from_file(err_file, db_conn, FHIR_SERVER)

    # If only test_bad_bundle has been run then this should pass, if other issues run then it will fail
    # If other tests have failed and written to the log, this will fail since the root causes won't be solved
    assert resp == True


def test_post_100_resources(db_conn):
    q_resource = f"""
        SELECT fhir FROM mimic_fhir.patient LIMIT 100
    """
    pd_resources = pd.read_sql_query(q_resource, db_conn)
    resources = pd_resources.fhir.to_list()
    split_flag = True  # Divide up bundles into smaller chunks

    bundle = Bundle('test_100')
    bundle.add_entry(resources)
    resp = bundle.request(FHIR_SERVER, FHIR_BUNDLE_ERROR_PATH)
    assert resp


def test_bundle_multiple_lab_resources(db_conn):
    # Get n patient ids to then bundle and post
    patient_ids = get_n_patient_id(db_conn, 1)
    bundle_name = 'lab'

    # Create bundle and post it
    result = True
    for patient_id in patient_ids:
        bundle = Bundle(bundle_name, MIMIC_BUNDLE_TABLE_LIST[bundle_name])
        bundle.generate(patient_id, db_conn)
        response = bundle.request(FHIR_SERVER, FHIR_BUNDLE_ERROR_PATH)

        if response == False:
            result = False
    assert result


def test_largest_bundle():
    # Bundle is 44,277 resources!
    # Ran for ~20 minutes without finishing...
    # I was posting 1000 resources in 6 seconds, so ~44,000 should be about 5 minutes...
    # Keep playing with this
    patient_id = '77e10fd0-6a1c-5547-a130-fae1341acf36'
    bundle_name = 'icu_observation'

    bundle = Bundle(bundle_name, MIMIC_BUNDLE_TABLE_LIST[bundle_name])
    bundle.generate(patient_id, db_conn)
    response = bundle.request(FHIR_SERVER, FHIR_BUNDLE_ERROR_PATH)
    assert response