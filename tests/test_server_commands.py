import json
import requests
import logging
import os
import subprocess
import pytest

FHIR_SERVER = os.getenv('FHIR_SERVER')
JAVA_VALIDATOR = os.getenv('JAVA_VALIDATOR')
MIMIC_IG_PATH = os.getenv('MIMIC_IG_PATH')


# Validate resources based on the validator being used
def validate_resource(validator, resource):
    if validator == 'HAPI':
        output = put_resource(resource)
        result = outcome['resourceType'] == resource['resourceType']
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


@pytest.mark.order(1)
def test_condition_validation(validator, condition_resource):
    result = validate_resource(validator, condition_resource)
    assert True  #result


@pytest.mark.order(2)
def test_encounter_validation(validator, encounter_resource):
    result = validate_resource(validator, encounter_resource)
    assert result


@pytest.mark.order(3)
def test_encounter_icu_validation(validator, encounter_icu_resource):
    result = validate_resource(validator, encounter_icu_resource)
    assert result


@pytest.mark.order(4)
def test_medadmin_validation(validator, medadmin_resource):
    result = validate_resource(validator, medadmin_resource)
    assert result


@pytest.mark.order(5)
def test_medadmin_icu_validation(validator, medadmin_icu_resource):
    result = validate_resource(validator, medadmin_icu_resource)
    assert result


@pytest.mark.order(6)
def test_medication_request_validation(validator, medication_request_resource):
    result = validate_resource(validator, medication_request_resource)
    assert result


@pytest.mark.order(7)
def test_medication_validation(validator, medication_resource):
    result = validate_resource(validator, medication_resource)
    assert result


@pytest.mark.order(8)
def test_observation_chartevents_validation(
    validator, observation_chartevents_resource
):
    result = validate_resource(validator, observation_chartevents_resource)
    assert result


@pytest.mark.order(9)
def test_observation_datetimeevents_validation(
    validator, observation_datetimeevents_resource
):
    result = validate_resource(validator, observation_datetimeevents_resource)
    assert result


@pytest.mark.order(10)
def test_observation_labs_validation(validator, observation_labs_resource):
    result = validate_resource(validator, observation_labs_resource)
    assert result


@pytest.mark.order(11)
def test_observation_micro_test_validation(
    validator, observation_micro_test_resource
):
    result = validate_resource(validator, observation_micro_test_resource)
    assert result


@pytest.mark.order(12)
def test_observation_micro_org_validation(
    validator, observation_micro_org_resource
):
    result = validate_resource(validator, observation_micro_org_resource)
    assert result


@pytest.mark.order(13)
def test_observation_micro_susc_validation(
    validator, observation_micro_susc_resource
):
    result = validate_resource(validator, observation_micro_susc_resource)
    assert result


@pytest.mark.order(14)
def test_observation_outputevents_validation(
    validator, observation_outputevents_resource
):
    result = validate_resource(validator, observation_outputevents_resource)
    assert result


@pytest.mark.order(15)
def test_patient_validation(validator, patient_resource):
    result = validate_resource(validator, patient_resource)
    assert result


@pytest.mark.order(16)
def test_procedure_validation(validator, procedure_resource):
    result = validate_resource(validator, procedure_resource)
    assert result


@pytest.mark.order(17)
def test_procedure_icu_validation(validator, procedure_icu_resource):
    result = validate_resource(validator, procedure_icu_resource)
    assert result


@pytest.mark.order(18)
def test_specimen_validation(validator, specimen_resource):
    result = validate_resource(validator, specimen_resource)
    assert result
