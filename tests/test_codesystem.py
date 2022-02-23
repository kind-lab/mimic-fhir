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

# Load env variables (should already have loaded in conftest.py)
FHIR_SERVER = os.getenv('FHIR_SERVER')


# Generic function to validate codes against CodeSystem in HAPI fhir
def cs_validate_code(codesystem, code):
    server = FHIR_SERVER
    url = f'{server}/CodeSystem/{codesystem}/$validate-code?code={code}'
    resp = requests.get(url, headers={"Content-Type": "application/json"})
    cs_output = json.loads(resp.text)
    return (cs_output)


def test_cs_admission_class():
    codesystem = 'admission-class'
    code = 'URGENT'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_admission_type():
    codesystem = 'admission-type'
    code = 'URGENT'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_admission_type_icu():
    codesystem = 'admission-type-icu'
    code = 'Neuro Stepdown'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_admit_source():
    codesystem = 'admit-source'
    code = 'EMERGENCY ROOM'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_bodysite():
    codesystem = 'bodysite'
    code = 'Right Foot'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_diagnosis_icd9():
    codesystem = 'diagnosis-icd9'
    code = '79509'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_diagnosis_icd10():
    codesystem = 'diagnosis-icd10'
    code = 'K1370'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_discharge_disposition():
    codesystem = 'discharge-disposition'
    code = 'HOME'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_d_items():
    codesystem = 'd-items'
    code = '224723'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_d_labitems():
    codesystem = 'd-labitems'
    code = '51905'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_lab_flags():
    codesystem = 'lab-flags'
    code = 'abnormal'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_medadmin_category_icu():
    codesystem = 'medadmin-category-icu'
    code = '15-Supplements'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_medication_method():
    codesystem = 'medication-method'
    code = 'Partial Administered'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_medication_route():
    codesystem = 'medication-route'
    code = 'INHALATION'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_medication_site():
    codesystem = 'medication-site'
    code = 'hip'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_microbiology_antibiotic():
    codesystem = 'microbiology-antibiotic'
    code = '90012'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_microbiology_interpretation():
    codesystem = 'microbiology-interpretation'
    code = 'P'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_microbiology_organism():
    codesystem = 'microbiology-organism'
    code = '90795'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_microbiology_test():
    codesystem = 'microbiology-test'
    code = '90212'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_mimic_observation_category():
    codesystem = 'mimic-observation-category'
    code = 'Output'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_procedure_category():
    codesystem = 'procedure-category'
    code = 'Imaging'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_procedure_icd9():
    codesystem = 'procedure-icd9'
    code = '3226'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_procedure_icd10():
    codesystem = 'procedure-icd10'
    code = '0SUB09Z'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


def test_cs_units():
    codesystem = 'units'
    code = 'mcg/ml'
    output = cs_validate_code(codesystem, code)
    assert output['parameter'][0]['valueBoolean']


# Valueset $validate-code not currently working. May need to add custom validator
# def test_vs_microbiology_test():
#     valueset = 'microbiology-test'
#     code = '90212'
#     output = vs_validate_code(valueset, code)
#     assert output['parameter'][0]['valueBoolean']
