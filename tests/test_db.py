import pytest
import pandas as pd
import os
from py_mimic_fhir.db import db_read_query


def test_mimic_fhir_row_count(db_conn, dbname):
    if dbname == 'mimic':
        test_filename = 'tests/test_mimic_fhir_row_count.sql'
    elif dbname == 'mimic_demo':
        test_filename = 'tests/test_mimic_fhir_demo_row_count.sql'
    else:
        print('ERROR: Database name must be either mimic or mimic_demo')
        assert False

    with open(test_filename) as f:
        sql_statement = f.read()

    results = db_read_query(sql_statement, db_conn)
    print(results)
    db_conn.commit()
    assert 'FAIL' not in results['test_status'].values


def test_mimic_fhir_row_count_approximate(db_conn, dbname):
    if dbname == 'mimic':
        test_filename = 'tests/test_mimic_fhir_row_count_approximate.sql'
    elif dbname == 'mimic_demo':
        test_filename = 'tests/test_mimic_fhir_demo_row_count_approximate.sql'
    else:
        print('ERROR: Database name must be either mimic or mimic_demo')
        assert False

    with open(test_filename) as f:
        sql_statement = f.read()

    results = db_read_query(sql_statement, db_conn)
    print(results)
    assert 'FAIL' not in results['test_status'].values
