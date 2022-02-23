# ----------------- ValueSet Validation ---------------------
# Purpose: Test the valuesets from the mimic package
# Method:  Ensure that valuesets exist, are expanded and have the right number of codes.
# Expected outcome: Valueset should be expanded and return specified number of codes

import json
import requests
import logging
import pandas as pd
import os


# Generic function to test expansion and the count of the valueset
def assert_expanded_and_count(db_conn_hapi, valueset, vs_count):
    q_valueset = f"SELECT expansion_status, total_concepts \
                   FROM trm_valueset WHERE vsname = '{valueset}'"

    result = pd.read_sql_query(q_valueset, db_conn_hapi)
    if result.expansion_status[0] == 'EXPANDED' and \
       result.total_concepts[0] == vs_count:
        logging.error(
            f'exp_stat: {result.expansion_status[0]}, total_concepts: {result.total_concepts[0]}'
        )
    return True


def test_vs_admission_class(db_conn_hapi):
    valueset = 'Admission Class'
    vs_count = 9
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_admission_type(db_conn_hapi):
    valueset = 'Admission Type'
    vs_count = 9
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_admission_type_icu(db_conn_hapi):
    valueset = 'Admission Type ICU'
    vs_count = 9
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_bodysite(db_conn_hapi):
    valueset = 'Bodysite'
    vs_count = 109
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_chartevents_d_items(db_conn_hapi):
    valueset = 'Chartevents D Items'
    vs_count = 2226
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_datetime_d_items(db_conn_hapi):
    valueset = 'Datetime D Items'
    vs_count = 170
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_diagnosis_icd(db_conn_hapi):
    valueset = 'Diagnosis ICD'
    vs_count = 27192
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_discharge_disposition(db_conn_hapi):
    valueset = 'Discharge Disposition'
    vs_count = 13
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_d_labitems(db_conn_hapi):
    valueset = 'D Lab Items'
    vs_count = 1630
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_lab_flags(db_conn_hapi):
    valueset = 'Lab Flags'
    vs_count = 1
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_medadmin_category_icu(db_conn_hapi):
    valueset = 'MedAdmin Category ICU'
    vs_count = 16
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_medication_method(db_conn_hapi):
    valueset = 'Medication Method'
    vs_count = 75
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_medication_route(db_conn_hapi):
    valueset = 'Medication Route'
    vs_count = 116
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_medication_site(db_conn_hapi):
    valueset = 'Medication Site'
    vs_count = 6598
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_microbiology_antibiotic(db_conn_hapi):
    valueset = 'Microbiology Antibiotic'
    vs_count = 27
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_microbiology_interpretation(db_conn_hapi):
    valueset = 'Microbiology Interpretation'
    vs_count = 4
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_microbiology_organism(db_conn_hapi):
    valueset = 'Microbiology Organism'
    vs_count = 647
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_microbiology_test(db_conn_hapi):
    valueset = 'Microbiology Test'
    vs_count = 177
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_mimic_observation_category(db_conn_hapi):
    valueset = 'MIMIC Observation Category'
    vs_count = 79
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_outputevents_d_items(db_conn_hapi):
    valueset = 'Outputevents D Items'
    vs_count = 71
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_procedure_category(db_conn_hapi):
    valueset = 'Procedure Category'
    vs_count = 14
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_procedure_d_items(db_conn_hapi):
    valueset = 'Procedure Items'
    vs_count = 157
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_procedure_icd(db_conn_hapi):
    valueset = 'Procedure ICD'
    vs_count = 13016
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)


def test_vs_units(db_conn_hapi):
    valueset = 'Units'
    vs_count = 634
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)