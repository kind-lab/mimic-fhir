import pytest

from py_mimic_fhir.load import load_ndjson_from_file, load_resources_to_server


def test_load_patient_ndjson(margs):
    resources = load_ndjson_from_file(margs.json_path, 'Patient')
    assert len(resources) > 0


def test_load_bundle_from_ndjson(margs):
    resources = load_ndjson_from_file(margs.json_path, 'Patient')
    response = load_resources_to_server(resources, 'Patient', margs)
    assert response


def test_load_bundle_from_ndjson_encounter(margs):
    profile = 'Patient'
    resources = load_ndjson_from_file(margs.json_path, profile)
    response = load_resources_to_server(resources, profile, margs)
    assert response
