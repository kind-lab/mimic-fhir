# Start with comment
"""
Test script for the io operations in mimic fhir
Primary io operations
- delete data in database
- export single resource
- bulk export resources
"""

import json
import requests
import logging
import os
import subprocess
import pytest
import numpy as np
import time
from py_mimic_fhir import io
from py_mimic_fhir.lookup import MIMIC_FHIR_PROFILE_URL, MIMIC_FHIR_RESOURCES

FHIR_SERVER = os.getenv('FHIR_SERVER')
MIMIC_JSON_PATH = os.getenv('MIMIC_JSON_PATH')


# Bulk export and get the resources into json
# Currently failing just based on MedicationDispense
def test_export_all_resources():
    limit = 1
    result_dict = io.export_all_resources(FHIR_SERVER, MIMIC_JSON_PATH, limit)

    # Assert all resources exported without error
    assert False not in result_dict.values()


def test_send_export_resource_request():
    profile = 'Patient'
    profile_url = MIMIC_FHIR_PROFILE_URL[profile]
    resource = MIMIC_FHIR_RESOURCES[profile]
    resp = io.send_export_resource_request(resource, profile_url, FHIR_SERVER)
    logging.error(resp.text)
    assert resp.status_code == 202


def test_get_exported_resource_timeout():
    time_max = 5
    timeout = time.time() + time_max
    profile = 'Patient'
    profile_url = MIMIC_FHIR_PROFILE_URL[profile]
    resource = MIMIC_FHIR_RESOURCES[profile]
    resp_export = io.send_export_resource_request(
        resource, profile_url, FHIR_SERVER
    )

    # manipulate the polling location so it HAS to timeout
    resp_export.headers['Content-Location'
                       ] = resp_export.headers['Content-Location'] + '12345'
    resp = io.get_exported_resource(resp_export, time_max)
    print(resp)
    assert time.time() > timeout  # just want it to wait 5 seconds


def test_get_exported_resource():
    profile = 'Patient'
    profile_url = MIMIC_FHIR_PROFILE_URL[profile]
    resource = MIMIC_FHIR_RESOURCES[profile]
    resp_export = io.send_export_resource_request(
        resource, profile_url, FHIR_SERVER
    )
    resp = io.get_exported_resource(resp_export)
    print(resp)
    assert resp.status_code == 200


def test_write_exported_resource_to_ndjson():
    profile = 'Patient'
    profile_url = MIMIC_FHIR_PROFILE_URL[profile]
    resource = MIMIC_FHIR_RESOURCES[profile]

    resp_export = io.send_export_resource_request(
        resource, profile_url, FHIR_SERVER
    )
    resp_poll = io.get_exported_resource(resp_export)
    io.write_exported_resource_to_ndjson(resp_poll, profile, MIMIC_JSON_PATH)

    #check outputfile exists and has some data
    output_file = f'{MIMIC_JSON_PATH}output_from_hapi/{profile}.ndjson'
    assert os.path.exists(output_file) and os.path.getsize(output_file) > 0


def test_export_patient():
    resource_type = 'Patient'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(
        resource_type, FHIR_SERVER, MIMIC_JSON_PATH, limit
    )
    assert result


def test_export_encounter():
    resource_type = 'Encounter'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(
        resource_type, FHIR_SERVER, MIMIC_JSON_PATH, limit
    )
    assert result


def test_export_condition():
    resource_type = 'Condition'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(
        resource_type, FHIR_SERVER, MIMIC_JSON_PATH, limit
    )
    assert result


def test_export_observation_micro_test():
    profile = 'ObservationMicroTest'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(profile, FHIR_SERVER, MIMIC_JSON_PATH, limit)
    assert result


def test_export_observation_micro_org():
    profile = 'ObservationMicroOrg'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(profile, FHIR_SERVER, MIMIC_JSON_PATH, limit)
    assert result


def test_export_observation_micro_susc():
    profile = 'ObservationMicroSusc'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(profile, FHIR_SERVER, MIMIC_JSON_PATH, limit)
    assert result


def test_export_observation_labevents():
    profile = 'ObservationLabevents'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(profile, FHIR_SERVER, MIMIC_JSON_PATH, limit)
    assert result


def test_export_observation_chartevents():
    profile = 'ObservationChartevents'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(profile, FHIR_SERVER, MIMIC_JSON_PATH, limit)
    assert result


def test_export_observation_datetimeevents():
    profile = 'ObservationDatetimeevents'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(profile, FHIR_SERVER, MIMIC_JSON_PATH, limit)
    assert result


def test_export_observation_outputevents():
    profile = 'ObservationOutputevents'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(profile, FHIR_SERVER, MIMIC_JSON_PATH, limit)
    assert result


def test_export_medication_request():
    resource_type = 'MedicationRequest'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(
        resource_type, FHIR_SERVER, MIMIC_JSON_PATH, limit
    )
    assert result


# MedicationDispense will fail until the Medication branch is merged
def test_export_medication_dispense():
    resource_type = 'MedicationDispense'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(
        resource_type, FHIR_SERVER, MIMIC_JSON_PATH, limit
    )
    assert result


def test_export_medication_administration():
    resource_type = 'MedicationAdministration'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(
        resource_type, FHIR_SERVER, MIMIC_JSON_PATH, limit
    )
    assert result


def test_export_medication_administration_icu():
    resource_type = 'MedicationAdministrationICU'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(
        resource_type, FHIR_SERVER, MIMIC_JSON_PATH, limit
    )
    assert result


def test_export_medication():
    resource_type = 'Medication'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(
        resource_type, FHIR_SERVER, MIMIC_JSON_PATH, limit
    )
    assert result


def test_export_organization():
    resource_type = 'Organization'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(
        resource_type, FHIR_SERVER, MIMIC_JSON_PATH, limit
    )
    assert result


def test_export_procedure():
    resource_type = 'Procedure'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(
        resource_type, FHIR_SERVER, MIMIC_JSON_PATH, limit
    )
    assert result


def test_export_procedure_icu():
    resource_type = 'ProcedureICU'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(
        resource_type, FHIR_SERVER, MIMIC_JSON_PATH, limit
    )
    assert result


def test_export_specimen():
    resource_type = 'Specimen'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(
        resource_type, FHIR_SERVER, MIMIC_JSON_PATH, limit
    )
    assert result


def test_export_specimen_lab():
    resource_type = 'SpecimenLab'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(
        resource_type, FHIR_SERVER, MIMIC_JSON_PATH, limit
    )
    assert result
