import json
import requests
import logging
import os
import subprocess
import pytest
from py_mimic_fhir.db import get_resource_by_id

FHIR_SERVER = os.getenv('FHIR_SERVER')
JAVA_VALIDATOR = os.getenv('JAVA_VALIDATOR')
MIMIC_IG_PATH = os.getenv('MIMIC_IG_PATH')

#------------------------ WARNING ---------------------------
# DO NOT RUN all validation tests when JAVA validator is set
# Run individual tests, or java validator will crash everything
# Need to explore way to run all test with java validator, but not
# working right now


# Validate resources based on the validator being used
def validate_resource(validator, resource):
    if validator == 'HAPI':
        output = put_resource(resource)
        result = output['resourceType'] == resource['resourceType']
    else:  #validator == 'JAVA'
        output = subprocess.run(
            [
                'java', '-jar', JAVA_VALIDATOR, resource, '-version', '4.0',
                '-ig', MIMIC_IG_PATH
            ],
            stdout=subprocess.PIPE
        ).stdout.decode('utf-8')
        result = 'Success' in output

    # log if error
    if result == False:
        logging.error(output)
    return result


# PUT fhir resource to HAPI FHIR server
def put_resource(resource):
    url = f'{FHIR_SERVER}/{resource["resourceType"]}/{resource["id"]}'

    resp = requests.put(
        url, json=resource, headers={"Content-Type": "application/fhir+json"}
    )
    output = json.loads(resp.text)
    return output


# ---------------- Resource Validation -------------------
# Validate a single generated resource from Postgres against a HAPI FHIR server
# Expected test results
#   - Pass: HAPI will return the validated resource
#   - Fail: HAPI will return an OperationOutcome resource with error info


def test_bad_patient_gender(validator):
    pat_resource = {
        'resourceType': 'Patient',
        'id': '123456',
        'gender': 'FAKE CODE'
    }
    result = validate_resource(validator, pat_resource)
    assert result == False


def test_organization_validation(validator, organization_resource):
    result = validate_resource(validator, organization_resource)
    assert result


def test_condition_validation(validator, condition_resource):
    result = validate_resource(validator, condition_resource)
    assert result


def test_encounter_validation(validator, encounter_resource):
    result = validate_resource(validator, encounter_resource)
    assert result


def test_encounter_transfers_validation(
    validator, encounter_transfers_resource
):
    result = validate_resource(validator, encounter_transfers_resource)
    assert result


def test_encounter_icu_validation(validator, encounter_icu_resource):
    result = validate_resource(validator, encounter_icu_resource)
    assert result


def test_medadmin_validation(validator, medadmin_resource):
    result = validate_resource(validator, medadmin_resource)
    assert result


def test_medadmin_icu_validation(validator, medadmin_icu_resource):
    result = validate_resource(validator, medadmin_icu_resource)
    assert result


def test_medication_dispense_validation(
    validator, medication_dispense_resource
):
    result = validate_resource(validator, medication_dispense_resource)
    assert result


def test_medication_request_validation(validator, medication_request_resource):
    result = validate_resource(validator, medication_request_resource)
    assert result


def test_medication_validation(validator, medication_resource):
    result = validate_resource(validator, medication_resource)
    assert result


def test_observation_chartevents_validation(
    validator, observation_chartevents_resource
):
    result = validate_resource(validator, observation_chartevents_resource)
    assert result


def test_observation_datetimeevents_validation(
    validator, observation_datetimeevents_resource
):
    result = validate_resource(validator, observation_datetimeevents_resource)
    assert result


def test_observation_labevents_validation(
    db_conn, validator, observation_labevents_resource
):
    # Need to post lab specimen before lab or referencing issues will occur
    resource = observation_labevents_resource
    if validator == 'HAPI':
        specimen_id = resource['specimen']['reference'].split('/')[1]
        specimen_resource = get_resource_by_id(
            db_conn, 'specimen_lab', specimen_id
        )
        validate_resource(validator, specimen_resource)
    result = validate_resource(validator, observation_labevents_resource)
    assert result


def test_observation_micro_test_validation(
    validator, observation_micro_test_resource
):
    result = validate_resource(validator, observation_micro_test_resource)
    assert result


def test_observation_micro_org_validation(
    validator, observation_micro_org_resource
):
    result = validate_resource(validator, observation_micro_org_resource)
    assert result


def test_observation_micro_susc_validation(
    validator, observation_micro_susc_resource
):
    result = validate_resource(validator, observation_micro_susc_resource)
    assert result


def test_observation_outputevents_validation(
    validator, observation_outputevents_resource
):
    result = validate_resource(validator, observation_outputevents_resource)
    assert result


def test_patient_validation(validator, patient_resource):
    result = validate_resource(validator, patient_resource)
    assert result


def test_procedure_validation(validator, procedure_resource):
    result = validate_resource(validator, procedure_resource)
    assert result


def test_procedure_icu_validation(validator, procedure_icu_resource):
    result = validate_resource(validator, procedure_icu_resource)
    assert result


def test_specimen_validation(validator, specimen_resource):
    result = validate_resource(validator, specimen_resource)
    assert result


def test_specimen_lab_validation(validator, specimen_lab_resource):
    result = validate_resource(validator, specimen_lab_resource)
    assert result
