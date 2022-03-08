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

FHIR_SERVER = os.getenv('FHIR_SERVER')
MIMIC_JSON_PATH = os.getenv('MIMIC_JSON_PATH')


def test_delete_resource():
    #call to delete one resource
    assert False


def test_expunge_resource():
    # call to expunge one resource
    assert False


def test_delete_multiple_resources():
    # call to delete 10 unique resoruces
    assert False


def test_expunge_multiple_resources():
    # call to expunge 10 unique resources
    assert False


def test_expunge_all():
    # this may not work as a test... since it should clear out the whole db
    assert False


def test_export_single_resource():
    # See that a resource can be exported
    assert False


def test_export_resource_to_json():
    # Take the exported resource and write to json
    assert False


def test_bulk_export_resources():
    # Call bulk export resources and get one resource
    assert False


# Bulk export and get the resources into json
def test_export_all_resources():
    limit = 1
    result_dict = io.export_all_resources(limit)

    # Assert all resources exported without error
    assert False not in result_dict.values()


def test_send_export_resource_request():
    resource_type = 'Patient'
    resp = io.send_export_resource_request(resource_type)
    assert resp.status_code == 202


def test_get_exported_resource_timeout():
    time_max = 5
    timeout = time.time() + time_max
    resource_type = 'Patient'
    resp_export = io.send_export_resource_request(resource_type)
    # manipulate the polling location so it HAS to timeout
    resp_export.headers['Content-Location'
                       ] = resp_export.headers['Content-Location'] + '12345'
    resp = io.get_exported_resource(resp_export, time_max)
    print(resp)
    assert time.time() > timeout  # just want it to wait 10 seconds


def test_get_exported_resource():
    resource_type = 'Patient'
    resp_export = io.send_export_resource_request(resource_type)
    resp = io.get_exported_resource(resp_export)
    print(resp)
    assert resp.status_code == 200


def test_write_exported_resource_to_ndjson():
    resource_type = 'Encounter'
    resp_export = io.send_export_resource_request(resource_type)
    resp_poll = io.get_exported_resource(resp_export)
    io.write_exported_resource_to_ndjson(resp_poll, resource_type)

    #check outputfile exists and has some data
    output_file = f'{MIMIC_JSON_PATH}output_from_hapi/{resource_type}.ndjson'
    assert os.path.exists(output_file) and os.path.getsize(output_file) > 0


def test_export_patient():
    resource_type = 'Patient'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(resource_type, limit)
    assert result


def test_export_encounter():
    resource_type = 'Encounter'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(resource_type, limit)
    assert result


def test_export_condition():
    resource_type = 'Condition'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(resource_type, limit)
    assert result


def test_export_observation_micro_test():
    profile = 'ObservationMicroTest'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(profile, limit)
    assert result


def test_export_observation_micro_org():
    profile = 'ObservationMicroOrg'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(profile, limit)
    assert result


def test_export_observation_micro_susc():
    profile = 'ObservationMicroSusc'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(profile, limit)
    assert result


def test_export_observation_lab():
    profile = 'ObservationLabs'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(profile, limit)
    assert result


def test_export_observation_chartevents():
    profile = 'ObservationChartevents'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(profile, limit)
    assert result


def test_export_observation_datetimeevents():
    profile = 'ObservationDatetimeevents'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(profile, limit)
    assert result


def test_export_observation_outputevents():
    profile = 'ObservationOutputevents'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(profile, limit)
    assert result


def test_export_medication_request():
    resource_type = 'MedicationRequest'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(resource_type, limit)
    assert result


# MedicationDispense will fail until the Medication branch is merged
def test_export_medication_dispense():
    resource_type = 'MedicationDispense'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(resource_type, limit)
    assert result


def test_export_medication_administration():
    resource_type = 'MedicationAdministration'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(resource_type, limit)
    assert result


def test_export_medication_administration_icu():
    resource_type = 'MedicationAdministrationICU'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(resource_type, limit)
    assert result


def test_export_medication():
    resource_type = 'Medication'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(resource_type, limit)
    assert result


def test_export_procedure():
    resource_type = 'Procedure'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(resource_type, limit)
    assert result


def test_export_procedure_icu():
    resource_type = 'ProcedureICU'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(resource_type, limit)
    assert result


def test_export_specimen():
    resource_type = 'Specimen'
    limit = 1  #Just export 1 binary ndjson for the resource (~1000 resources)
    result = io.export_resource(resource_type, limit)
    assert result
