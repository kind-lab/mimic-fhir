from pathlib import Path
import json
import pandas as pd
import psycopg2
from dotenv import load_dotenv
import os

import pytest

# Load environment variables
load_dotenv(Path(Path.cwd()).parents[0] / '.env')

SQLUSER = os.getenv('SQLUSER')
SQLPASS = os.getenv('SQLPASS')
DBNAME_MIMIC = os.getenv('DBNAME_MIMIC')
DBNAME_HAPI = os.getenv('DBNAME_HAPI')
HOST = os.getenv('HOST')

#from fhir.resources.conceptmap import ConceptMap


# Example patient that has links to all other resources
def patient_id():
    return '01aa15d9-3114-5220-b492-332361c2f91c'


# Set validator for the session
@pytest.fixture(scope="session")
def validator():
    return 'JAVA'  # JAVA or HAPI


# Initialize database connection to mimic
@pytest.fixture(scope="session")
def db_conn():
    sqluser = SQLUSER
    sqlpass = SQLPASS
    dbname = DBNAME_MIMIC
    host = HOST

    conn = psycopg2.connect(
        dbname=dbname, user=sqluser, password=sqlpass, host=host
    )
    return conn


# Initialize database connection to hapi
@pytest.fixture(scope="session")
def db_conn_hapi():
    sqluser = SQLUSER
    sqlpass = SQLPASS
    dbname = DBNAME_HAPI
    host = HOST

    conn = psycopg2.connect(
        dbname=dbname, user=sqluser, password=sqlpass, host=host
    )
    return conn


# Generic function to initialize resources based on VALIDATOR
def initialize_single_resource(validator, db_conn, table_name):
    resource = get_single_resource(db_conn, table_name)

    # Write out resource to json, so java validator can find it later
    if validator == 'JAVA':
        print(f'CURRENT DIRECTORY: {os.getcwd()}')
        resource_file = f'tests/fhir/{table_name}.json'
        with open(resource_file, 'w') as outfile:
            json.dump(resource, outfile)
        return resource_file
    else:  #VALIDATOR == HAPI
        return resource


# Generic function to get single resource from the DB
def get_single_resource(db_conn, table_name):
    q_resource = f"SELECT * FROM mimic_fhir.{table_name} LIMIT 1"
    resource = pd.read_sql_query(q_resource, db_conn)

    return resource.fhir[0]


# Get a single resource with a link to a specific patient
def get_single_resource_by_pat(db_conn, table_name):
    q_resource = f"SELECT * FROM mimic_fhir.{table_name} WHERE patient_id = '{patient_id()}' LIMIT 1"
    resource = pd.read_sql_query(q_resource, db_conn)

    return resource.fhir[0]


# Return a single patient resource
@pytest.fixture(scope="session")
def patient_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'patient')


# Return a single encounter resource
@pytest.fixture(scope="session")
def encounter_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'encounter')


# Return a single condition resource
@pytest.fixture(scope="session")
def condition_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'condition')


# Return a single encounter_icu resource
@pytest.fixture(scope="session")
def encounter_icu_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'encounter_icu')


# Return a single medication administration resource
@pytest.fixture(scope="session")
def medadmin_resource(validator, db_conn):
    return initialize_single_resource(
        validator, db_conn, 'medication_administration'
    )


# Return a single medication administration icu resource
@pytest.fixture(scope="session")
def medadmin_icu_resource(validator, db_conn):
    return initialize_single_resource(
        validator, db_conn, 'medication_administration_icu'
    )


# Return a single medication request resource
@pytest.fixture(scope="session")
def medication_request_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'medication_request')


# Return a single medication resource
@pytest.fixture(scope="session")
def medication_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'medication')


# Return a single observation_chartevents resource
@pytest.fixture(scope="session")
def observation_chartevents_resource(validator, db_conn):
    return initialize_single_resource(
        validator, db_conn, 'observation_chartevents'
    )


# Return a single observation_dateevents resource
@pytest.fixture(scope="session")
def observation_datetimeevents_resource(validator, db_conn):
    return initialize_single_resource(
        validator, db_conn, 'observation_datetimeevents'
    )


# Return a single observation_labs resource
@pytest.fixture(scope="session")
def observation_labs_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'observation_labs')


# Return a single observation_micro_test resource
@pytest.fixture(scope="session")
def observation_micro_test_resource(validator, db_conn):
    return initialize_single_resource(
        validator, db_conn, 'observation_micro_test'
    )


# Return a single observation_micro_org resource
@pytest.fixture(scope="session")
def observation_micro_org_resource(validator, db_conn):
    return initialize_single_resource(
        validator, db_conn, 'observation_micro_org'
    )


# Return a single observation_micro_susc resource
@pytest.fixture(scope="session")
def observation_micro_susc_resource(validator, db_conn):
    return initialize_single_resource(
        validator, db_conn, 'observation_micro_susc'
    )


# Return a single observation_outputevents resource
@pytest.fixture(scope="session")
def observation_outputevents_resource(validator, db_conn):
    return initialize_single_resource(
        validator, db_conn, 'observation_outputevents'
    )


# Return a single procedure resource
@pytest.fixture(scope="session")
def procedure_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'procedure')


# Return a single procedure_icu resource
@pytest.fixture(scope="session")
def procedure_icu_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'procedure_icu')