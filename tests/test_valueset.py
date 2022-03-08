# ----------------- ValueSet Validation ---------------------
# Purpose: Test the valuesets from the mimic package
# Method:  Ensure that valuesets exist, are expanded and have the right number of codes.
# Expected outcome: Valueset should be expanded and return specified number of codes

import json
import requests
import logging
import pandas as pd
import subprocess
import os

MIMIC_TERMINOLOGY_PATH = os.getenv('MIMIC_TERMINOLOGY_PATH')
JAVA_VALIDATOR = os.getenv('JAVA_VALIDATOR')
MIMIC_IG_PATH = os.getenv('MIMIC_IG_PATH')

#------------------------ WARNING ---------------------------
# DO NOT RUN all validation tests when JAVA validator is set
# Run individual tests, or java validator will crash everything
# Need to explore way to run all test with java validator, but not
# working right now


# Validate valueset
def validate_valueset(validator, db_conn_hapi, valueset, vs_count):
    if validator == 'HAPI':
        result = assert_expanded_and_count(db_conn_hapi, valueset, vs_count)
    else:  # Java validator
        valueset_name = valueset.lower().replace(' ', '-')
        valueset_filename = f'{MIMIC_TERMINOLOGY_PATH}ValueSet-{valueset_name}.json'
        output = subprocess.run(
            [
                'java', '-jar', JAVA_VALIDATOR, valueset_filename, '-version',
                '4.0', '-ig', MIMIC_IG_PATH
            ],
            stdout=subprocess.PIPE
        ).stdout.decode('utf-8')
        result = 'Success' in output
    return result


# Generic function to test expansion and the count of the valueset
def assert_expanded_and_count(db_conn_hapi, valueset, vs_count):
    q_valueset = f"SELECT expansion_status, total_concepts \
                   FROM trm_valueset WHERE vsname = '{valueset}'"

    result = pd.read_sql_query(q_valueset, db_conn_hapi)
    if result.expansion_status[0] == 'EXPANDED' and \
       result.total_concepts[0] == vs_count:
        result = True
    else:
        result = False
        logging.error(
            f'exp_stat: {result.expansion_status[0]}, total_concepts: {result.total_concepts[0]}'
        )
    return result


def test_vs_admission_class(validator, db_conn_hapi):
    valueset = 'Admission Class'
    vs_count = 9
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_admission_type(validator, db_conn_hapi):
    valueset = 'Admission Type'
    vs_count = 9
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_admission_type_icu(validator, db_conn_hapi):
    valueset = 'Admission Type ICU'
    vs_count = 9
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_bodysite(validator, db_conn_hapi):
    valueset = 'Bodysite'
    vs_count = 109
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_chartevents_d_items(validator, db_conn_hapi):
    valueset = 'Chartevents D Items'
    vs_count = 2226
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_datetime_d_items(validator, db_conn_hapi):
    valueset = 'Datetime D Items'
    vs_count = 170
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_diagnosis_icd(validator, db_conn_hapi):
    valueset = 'Diagnosis ICD'
    vs_count = 27192
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_discharge_disposition(validator, db_conn_hapi):
    valueset = 'Discharge Disposition'
    vs_count = 13
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_d_labitems(validator, db_conn_hapi):
    valueset = 'D Lab Items'
    vs_count = 1630
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_lab_flags(validator, db_conn_hapi):
    valueset = 'Lab Flags'
    vs_count = 1
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_medadmin_category_icu(validator, db_conn_hapi):
    valueset = 'MedAdmin Category ICU'
    vs_count = 16
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_medication_method(validator, db_conn_hapi):
    valueset = 'Medication Method'
    vs_count = 75
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_medication_route(validator, db_conn_hapi):
    valueset = 'Medication Route'
    vs_count = 116
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_medication_site(validator, db_conn_hapi):
    valueset = 'Medication Site'
    vs_count = 6598
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_microbiology_antibiotic(validator, db_conn_hapi):
    valueset = 'Microbiology Antibiotic'
    vs_count = 27
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_microbiology_interpretation(validator, db_conn_hapi):
    valueset = 'Microbiology Interpretation'
    vs_count = 4
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_microbiology_organism(validator, db_conn_hapi):
    valueset = 'Microbiology Organism'
    vs_count = 647
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_microbiology_test(validator, db_conn_hapi):
    valueset = 'Microbiology Test'
    vs_count = 177
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_mimic_observation_category(validator, db_conn_hapi):
    valueset = 'MIMIC Observation Category'
    vs_count = 79
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_outputevents_d_items(validator, db_conn_hapi):
    valueset = 'Outputevents D Items'
    vs_count = 71
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_procedure_category(validator, db_conn_hapi):
    valueset = 'Procedure Category'
    vs_count = 14
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_procedure_d_items(validator, db_conn_hapi):
    valueset = 'Procedure Items'
    vs_count = 157
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_procedure_icd(validator, db_conn_hapi):
    valueset = 'Procedure ICD'
    vs_count = 13016
    assert validate_valueset(validator, db_conn_hapi, valueset, vs_count)


def test_vs_units(validator, db_conn_hapi):
    valueset = 'Units'
    vs_count = 686
    assert assert_expanded_and_count(db_conn_hapi, valueset, vs_count)
