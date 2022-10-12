import json
import requests
import logging
import os
import subprocess
import pytest
import time

from py_mimic_fhir.terminology import TerminologyMetaData
import py_mimic_fhir.terminology as trm

from fhir.resources.codesystem import CodeSystem, CodeSystemConcept
from fhir.resources.valueset import ValueSet

from py_mimic_fhir.lookup import (MIMIC_CODESYSTEMS, MIMIC_VALUESETS)


def test_terminology_meta_data(db_conn):
    meta = TerminologyMetaData(db_conn)
    logging.error(meta)
    assert meta.language == 'en'


def test_codesystem_descriptions(db_conn, meta):
    description = meta.cs_descriptions[meta.cs_descriptions['codesystem'] ==
                                       'lab_flags']['description'].iloc[0]
    assert description == 'The lab alarm flags for abnormal lab events in MIMIC'


def test_valueset_descriptions(db_conn, meta):
    description = meta.vs_descriptions[meta.vs_descriptions['valueset'] ==
                                       'lab_flags']['description'].iloc[0]
    assert description == 'The lab alarm flags for abnormal lab events in MIMIC'


def test_db_get_table(db_conn):
    df_table = db_conn.get_table('fhir_trm', 'cs_lab_flags')
    print(df_table)


def test_generate_codesystem(db_conn, meta):
    mimic_codesystem = 'lab_flags'
    codesystem = trm.generate_codesystem(mimic_codesystem, db_conn, meta)
    assert codesystem.resource_type == 'CodeSystem'


def test_generate_valueset(db_conn, meta):
    mimic_valueset = 'lab_flags'
    valueset = trm.generate_valueset(mimic_valueset, db_conn, meta)
    assert valueset.resource_type == 'ValueSet'


# Check that the valueset coded generates without errors, not checking contents
def test_generate_valueset_coded(db_conn, meta):
    mimic_valueset = 'chartevents_d_items'
    valueset = trm.generate_valueset(mimic_valueset, db_conn, meta)
    logging.error(valueset.compose)
    assert valueset.resource_type == 'ValueSet'


# Check that the valueset double system generates without errors, not checking contents
def test_generate_valueset_double_system(db_conn, meta):
    mimic_valueset = 'procedure_icd'
    valueset = trm.generate_valueset(mimic_valueset, db_conn, meta)
    logging.error(valueset)
    assert valueset.resource_type == 'ValueSet'


def test_write_codeystem(example_codesystem, terminology_path):
    current_time = time.localtime()
    trm.write_terminology(example_codesystem, terminology_path)

    # Confirm the file has been updated
    output_filepath = f'{terminology_path}{example_codesystem.resource_type}-{example_codesystem.id}.json'
    modified_time_unstructured = os.path.getmtime(output_filepath)
    modified_time = time.localtime(modified_time_unstructured)
    assert current_time == modified_time


def test_write_valueset(example_valueset, terminology_path):
    current_time = time.localtime()
    trm.write_terminology(example_valueset, terminology_path)

    # Confirm the file has been updated
    output_filepath = f'{terminology_path}{example_valueset.resource_type}-{example_valueset.id}.json'
    modified_time_unstructured = os.path.getmtime(output_filepath)
    modified_time = time.localtime(modified_time_unstructured)
    assert current_time == modified_time


def test_generate_all_codesystems(db_conn, meta, terminology_path):
    trm.generate_codesystems(db_conn, meta, terminology_path)
    assert True


def test_generate_all_valuesets(db_conn, meta, terminology_path):
    trm.generate_valuesets(db_conn, meta, terminology_path)
    assert True
