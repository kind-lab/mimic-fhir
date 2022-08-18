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


def validate_reference_resource(
    db_conn, resource, table, ref, list_object=False
):
    if list_object:
        resource_id = resource[ref][0]['reference'].split('/')[1]
    else:
        resource_id = resource[ref]['reference'].split('/')[1]
    resource = get_resource_by_id(db_conn, table, resource_id)
    validate_resource('HAPI', resource)


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


def test_condition_validation(db_conn, validator, condition_resource):
    validate_reference_resource(
        db_conn, condition_resource, 'encounter', 'encounter'
    )

    result = validate_resource(validator, condition_resource)
    assert result


def test_encounter_validation(db_conn, validator, encounter_resource):
    validate_reference_resource(
        db_conn, encounter_resource, 'patient', 'subject'
    )

    print(f"ENCOUNTER RESOURCE ID: {encounter_resource['id']}")
    result = validate_resource(validator, encounter_resource)
    assert result


def test_encounter_icu_validation(db_conn, validator, encounter_icu_resource):
    validate_reference_resource(
        db_conn, encounter_icu_resource, 'encounter', 'partOf'
    )
    result = validate_resource(validator, encounter_icu_resource)
    assert result


def test_location_validation(validator, location_resource):
    result = validate_resource(validator, location_resource)
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
    db_conn, validator, observation_datetimeevents_resource
):
    validate_reference_resource(
        db_conn, observation_datetimeevents_resource, 'patient', 'subject'
    )
    validate_reference_resource(
        db_conn, observation_datetimeevents_resource, 'encounter_icu',
        'encounter'
    )
    print(f"ENCOUNTER ID: {observation_datetimeevents_resource['encounter']}")
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


# ----------------- MIMIC ED Resource Validation ----------------------
def test_encounter_ed_validation(validator, encounter_ed_resource):
    result = validate_resource(validator, encounter_ed_resource)
    assert result


def test_condition_ed_validation(db_conn, validator, condition_ed_resource):
    # validate encounter resource first so that encounter is on the server
    validate_reference_resource(
        db_conn, condition_ed_resource, 'encounter_ed', 'encounter'
    )
    result = validate_resource(validator, condition_ed_resource)
    assert result


def test_medication_dispense_ed_validation(
    db_conn, validator, medication_dispense_ed_resource
):
    # validate encounter resource first so that encounter is on the server
    validate_reference_resource(
        db_conn, medication_dispense_ed_resource, 'encounter_ed', 'context'
    )
    result = validate_resource(validator, medication_dispense_ed_resource)
    assert result


def test_medication_statement_ed_validation(
    db_conn, validator, medication_statement_ed_resource
):
    # validate encounter resource first so that encounter is on the server
    validate_reference_resource(
        db_conn, medication_statement_ed_resource, 'encounter_ed', 'context'
    )
    result = validate_resource(validator, medication_statement_ed_resource)

    assert result


def test_observation_ed_validation(db_conn, validator, observation_ed_resource):
    # validate encounter and procedure resource first for referencing
    validate_reference_resource(
        db_conn, observation_ed_resource, 'encounter_ed', 'encounter'
    )
    validate_reference_resource(
        db_conn,
        observation_ed_resource,
        'procedure_ed',
        'partOf',
        list_object=True
    )
    print(f'{observation_ed_resource["id"]}')

    result = validate_resource(validator, observation_ed_resource)
    assert result


def test_observation_vitalsigns_validation(
    db_conn, validator, observation_vitalsigns_resource
):
    # validate encounter resource first so that encounter is on the server
    # validate_reference_resource(
    #     db_conn, observation_vitalsigns_resource, 'encounter_ed', 'encounter'
    # )
    # validate_reference_resource(
    #     db_conn, observation_vitalsigns_resource, 'procedure_ed', 'partOf'
    # )
    result = validate_resource(validator, observation_vitalsigns_resource)
    print(f"OBSERVATION ID: {observation_vitalsigns_resource['id']}")
    assert result


def test_procedure_ed_validation(db_conn, validator, procedure_ed_resource):
    # validate encounter resource first so that encounter is on the server
    validate_reference_resource(
        db_conn, procedure_ed_resource, 'encounter_ed', 'encounter'
    )
    result = validate_resource(validator, procedure_ed_resource)
    assert result
