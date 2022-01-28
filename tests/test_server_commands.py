import json
import requests
import logging


# PUT fhir resource to HAPI FHIR server
def put_resource(resource):
    server = 'http://localhost:8080/fhir/'
    url = server + resource['resourceType'] + '/' + resource['id']

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


def test_condition_validation(condition_resource):
    outcome = put_resource(condition_resource)

    # if it fails output error message returned from HAPI
    if outcome['resourceType'] == 'OperationOutcome':
        logging.error(outcome)
    assert outcome['resourceType'] == condition_resource['resourceType']


def test_encounter_validation(encounter_resource):
    outcome = put_resource(encounter_resource)

    # if it fails output error message returned from HAPI
    if outcome['resourceType'] == 'OperationOutcome':
        logging.error(outcome)
    assert outcome['resourceType'] == encounter_resource['resourceType']


def test_encounter_icu_validation(encounter_icu_resource):
    outcome = put_resource(encounter_icu_resource)

    # if it fails output error message returned from HAPI
    if outcome['resourceType'] == 'OperationOutcome':
        logging.error(outcome)
    assert outcome['resourceType'] == encounter_icu_resource['resourceType']


def test_patient_validation(patient_resource):
    outcome = put_resource(patient_resource)

    # if it fails output error message returned from HAPI
    if outcome['resourceType'] == 'OperationOutcome':
        logging.error(outcome)
    assert outcome['resourceType'] == patient_resource['resourceType']


def test_procedure_validation(procedure_resource):
    outcome = put_resource(procedure_resource)

    # if it fails output error message returned from HAPI
    if outcome['resourceType'] == 'OperationOutcome':
        logging.error(outcome)
    assert outcome['resourceType'] == procedure_resource['resourceType']


def test_procedure_icu_validation(procedure_icu_resource):
    outcome = put_resource(procedure_icu_resource)

    # if it fails output error message returned from HAPI
    if outcome['resourceType'] == 'OperationOutcome':
        logging.error(outcome)
    assert outcome['resourceType'] == procedure_icu_resource['resourceType']
