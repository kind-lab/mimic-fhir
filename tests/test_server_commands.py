import json
import requests
import logging
import os

FHIR_SERVER = os.getenv('FHIR_SERVER')


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


def test_medadmin_validation(medadmin_resource):
    outcome = put_resource(medadmin_resource)

    # if it fails output error message returned from HAPI
    if outcome['resourceType'] == 'OperationOutcome':
        logging.error(outcome)
    assert outcome['resourceType'] == medadmin_resource['resourceType']


def test_medadmin_icu_validation(medadmin_icu_resource):
    outcome = put_resource(medadmin_icu_resource)

    # if it fails output error message returned from HAPI
    if outcome['resourceType'] == 'OperationOutcome':
        logging.error(outcome)
    assert outcome['resourceType'] == medadmin_icu_resource['resourceType']


def test_medication_request_validation(medication_request_resource):
    outcome = put_resource(medication_request_resource)

    # if it fails output error message returned from HAPI
    if outcome['resourceType'] == 'OperationOutcome':
        logging.error(outcome)
    assert outcome['resourceType'] == medication_request_resource['resourceType'
                                                                 ]


def test_medication_validation(medication_resource):
    outcome = put_resource(medication_resource)

    # if it fails output error message returned from HAPI
    if outcome['resourceType'] == 'OperationOutcome':
        logging.error(outcome)
    assert outcome['resourceType'] == medication_resource['resourceType']


def test_observation_chartevents_validation(observation_chartevents_resource):
    outcome = put_resource(observation_chartevents_resource)

    # if it fails output error message returned from HAPI
    if outcome['resourceType'] == 'OperationOutcome':
        logging.error(outcome)
    assert outcome['resourceType'] == observation_chartevents_resource[
        'resourceType']


def test_observation_datetimeevents_validation(
    observation_datetimeevents_resource
):
    outcome = put_resource(observation_datetimeevents_resource)

    # if it fails output error message returned from HAPI
    if outcome['resourceType'] == 'OperationOutcome':
        logging.error(outcome)
    assert outcome['resourceType'] == observation_datetimeevents_resource[
        'resourceType']


def test_observation_labs_validation(observation_labs_resource):
    outcome = put_resource(observation_labs_resource)

    # if it fails output error message returned from HAPI
    if outcome['resourceType'] == 'OperationOutcome':
        logging.error(outcome)
    assert outcome['resourceType'] == observation_labs_resource['resourceType']


def test_observation_micro_test_validation(observation_micro_test_resource):
    outcome = put_resource(observation_micro_test_resource)

    # if it fails output error message returned from HAPI
    if outcome['resourceType'] == 'OperationOutcome':
        logging.error(outcome)
    assert outcome['resourceType'] == observation_micro_test_resource[
        'resourceType']


def test_observation_micro_org_validation(observation_micro_org_resource):
    outcome = put_resource(observation_micro_org_resource)

    # if it fails output error message returned from HAPI
    if outcome['resourceType'] == 'OperationOutcome':
        logging.error(outcome)
    assert outcome['resourceType'] == observation_micro_org_resource[
        'resourceType']


def test_observation_micro_susc_validation(observation_micro_susc_resource):
    outcome = put_resource(observation_micro_susc_resource)

    # if it fails output error message returned from HAPI
    if outcome['resourceType'] == 'OperationOutcome':
        logging.error(outcome)
    assert outcome['resourceType'] == observation_micro_susc_resource[
        'resourceType']


def test_observation_outputevents_validation(observation_outputevents_resource):
    outcome = put_resource(observation_outputevents_resource)

    # if it fails output error message returned from HAPI
    if outcome['resourceType'] == 'OperationOutcome':
        logging.error(outcome)
    assert outcome['resourceType'] == observation_outputevents_resource[
        'resourceType']


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
