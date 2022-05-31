import pytest
import sys

from py_mimic_fhir.load import load_ndjson_from_file, load_resources_to_server, multiprocess_load, load_worker
from py_mimic_fhir.bundle import Bundle
from py_mimic_fhir.db import get_n_resources


def test_load_patient_ndjson(margs):
    resources = load_ndjson_from_file(margs.json_path, 'Patient')
    assert len(resources) > 0


def test_load_bundle_from_ndjson(margs):
    resources = load_ndjson_from_file(margs.json_path, 'Patient')
    response = load_resources_to_server(resources, 'Patient', margs)
    assert response


def test_load_bundle_from_ndjson_resource(margs):
    profile = 'ObservationChartevents'
    bundle_size = 1000
    resources = load_ndjson_from_file(margs.json_path, profile)[0:1000]
    response = load_resources_to_server(resources, profile, margs, bundle_size)
    assert response


def test_load_bundle_from_ndjson_resource_2(db_conn, margs):
    profile = 'ObservationChartevents'
    bundle_size = 1000
    # resources = load_ndjson_from_file(margs.json_path, profile)[0:1000]
    resources = get_n_resources(
        db_conn, 'observation_chartevents', n_limit=1000
    )
    print(f'Size: {sys.getsizeof(resources)}, Length: {len(resources)}')
    bundle = Bundle('test_1000')
    bundle.add_entry(resources)
    resp = bundle.request(
        margs.fhir_server,
        margs.err_path,
        split_flag=True,
        bundle_size=bundle_size
    )
    assert resp


def test_multiprocess_load(margs):
    cores = 4
    result = multiprocess_load(cores, margs)
    assert result


def test_load_worker(margs):
    profile = 'Patient'
    response = load_worker(profile, margs)
    assert response