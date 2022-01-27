from pathlib import Path
import json
import pandas as pd
import psycopg2

import pytest

#from fhir.resources.conceptmap import ConceptMap


# Initialize database connection to mimic
@pytest.fixture(scope="session")
def db_conn():
    sqluser = 'postgres'
    sqlpass = 'postgres'
    dbname = 'mimic'
    host = 'localhost'

    conn = psycopg2.connect(
        dbname=dbname, user=sqluser, password=sqlpass, host=host
    )
    return conn


# Generic function to get single resource from the DB
def get_single_resource(db_conn, table_name):
    q_resource = f"SELECT * FROM mimic_fhir.{table_name} LIMIT 1"
    resource = pd.read_sql_query(q_resource, db_conn)

    return resource.fhir[0]


# Return a single patient resource
@pytest.fixture(scope="session")
def patient_resource(db_conn):
    return get_single_resource(db_conn, 'patient')


# Return a single encounter resource
@pytest.fixture(scope="session")
def encounter_resource(db_conn):
    return get_single_resource(db_conn, 'encounter')


# Return a single condition resource
@pytest.fixture(scope="session")
def condition_resource(db_conn):
    return get_single_resource(db_conn, 'condition')


# Return a single encounter_icu resource
@pytest.fixture(scope="session")
def encounter_icu_resource(db_conn):
    return get_single_resource(db_conn, 'encounter_icu')


# Return a single medication administration resource
@pytest.fixture(scope="session")
def medadmin_resource(db_conn):
    return get_single_resource(db_conn, 'medication_adminstration')


# Return a single medication administration icu resource
@pytest.fixture(scope="session")
def medadmin_icu_resource(db_conn):
    return get_single_resource(db_conn, 'medication_adminstration_icu')


# Return a single medication request resource
@pytest.fixture(scope="session")
def medadmin_resource(db_conn):
    return get_single_resource(db_conn, 'medication_request')


# Return a single medication resource
@pytest.fixture(scope="session")
def medadmin_resource(db_conn):
    return get_single_resource(db_conn, 'medication_request')
