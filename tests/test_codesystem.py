# ----------------- CodeSystem Validation ---------------------
# Purpose: Test the codesystems from the mimic package
# Method:  Ensure that codesystems exist and that a code can
#          be validated against it using $validate-code.
# Expected outcome: test should return true if code present, false if not.
#                   A fail could also mean the codesystem does not exist

import json
import requests
import logging
import os
import subprocess

#------------------------ WARNING ---------------------------
# DO NOT RUN all validation tests when JAVA validator is set
# Run individual tests, or java validator will crash everything
# Need to explore way to run all test with java validator, but not
# working right now

# Load env variables (should already have loaded in conftest.py)
FHIR_SERVER = os.getenv('FHIR_SERVER')
MIMIC_TERMINOLOGY_PATH = os.getenv('MIMIC_TERMINOLOGY_PATH')
JAVA_VALIDATOR = os.getenv('JAVA_VALIDATOR')
MIMIC_IG_PATH = os.getenv('MIMIC_IG_PATH')


# Generic function to validate codes against CodeSystem in HAPI fhir
def cs_validate_code(validator, codesystem, code):
    if validator == 'HAPI':
        server = FHIR_SERVER
        url = f'{server}/CodeSystem/{codesystem}/$validate-code?code={code}'
        resp = requests.get(url, headers={"Content-Type": "application/json"})
        cs_output = json.loads(resp.text)['parameter'][0]['valueBoolean']
    else:  # JAVA validator
        codesystem_filename = f'{MIMIC_TERMINOLOGY_PATH}CodeSystem-{codesystem}.json'
        output = subprocess.run(
            [
                'java', '-jar', JAVA_VALIDATOR, codesystem_filename, '-version',
                '4.0', '-ig', MIMIC_IG_PATH
            ],
            stdout=subprocess.PIPE
        ).stdout.decode('utf-8')
        cs_output = 'Success' in output
    return cs_output


def test_cs_admission_class(validator):
    codesystem = 'admission-class'
    code = 'URGENT'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_admission_type(validator):
    codesystem = 'admission-type'
    code = 'URGENT'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_admission_type_icu(validator):
    codesystem = 'admission-type-icu'
    code = 'Neuro Stepdown'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_admit_source(validator):
    codesystem = 'admit-source'
    code = 'EMERGENCY ROOM'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_bodysite(validator):
    codesystem = 'bodysite'
    code = 'Right Foot'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_diagnosis_icd9(validator):
    codesystem = 'diagnosis-icd9'
    code = '79509'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_diagnosis_icd10(validator):
    codesystem = 'diagnosis-icd10'
    code = 'K1370'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_discharge_disposition(validator):
    codesystem = 'discharge-disposition'
    code = 'HOME'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_d_items(validator):
    codesystem = 'd-items'
    code = '224723'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_d_labitems(validator):
    codesystem = 'd-labitems'
    code = '51905'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_lab_flags(validator):
    codesystem = 'lab-flags'
    code = 'abnormal'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_medadmin_category_icu(validator):
    codesystem = 'medadmin-category-icu'
    code = '15-Supplements'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_medication_method(validator):
    codesystem = 'medication-method'
    code = 'Partial Administered'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_medication_route(validator):
    codesystem = 'medication-route'
    code = 'INHALATION'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_medication_site(validator):
    codesystem = 'medication-site'
    code = 'hip'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_microbiology_antibiotic(validator):
    codesystem = 'microbiology-antibiotic'
    code = '90012'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_microbiology_interpretation(validator):
    codesystem = 'microbiology-interpretation'
    code = 'P'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_microbiology_organism(validator):
    codesystem = 'microbiology-organism'
    code = '90795'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_microbiology_test(validator):
    codesystem = 'microbiology-test'
    code = '90212'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_mimic_observation_category(validator):
    codesystem = 'mimic-observation-category'
    code = 'Output'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_procedure_category(validator):
    codesystem = 'procedure-category'
    code = 'Imaging'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_procedure_icd9(validator):
    codesystem = 'procedure-icd9'
    code = '3226'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_procedure_icd10(validator):
    codesystem = 'procedure-icd10'
    code = '0SUB09Z'
    result = cs_validate_code(validator, codesystem, code)
    assert result


def test_cs_units(validator):
    codesystem = 'units'
    code = 'mcg/ml'
    result = cs_validate_code(validator, codesystem, code)
    assert result


# Valueset $validate-code not currently working. May need to add custom validator
# def test_vs_microbiology_test():
#     valueset = 'microbiology-test'
#     code = '90212'
#     output = vs_validate_code(valueset, code)
#     assert output['parameter'][0]['valueBoolean']
