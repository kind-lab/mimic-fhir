from pathlib import Path
import json
import pandas as pd
import psycopg2
from dotenv import load_dotenv
import os
import tkinter as tk
import pytest

from py_mimic_fhir.db import get_n_resources, connect_db, db_read_query
import py_mimic_fhir.terminology as trm
from py_mimic_fhir.config import MimicArgs, GoogleArgs, PatientEverythingArgs

# Load environment variables
load_dotenv(Path(__file__).parent.parent.resolve() / '.env')

SQLUSER = os.getenv('SQLUSER')
SQLPASS = os.getenv('SQLPASS')
DBNAME_MIMIC = os.getenv('DBNAME_MIMIC')
DBNAME_HAPI = os.getenv('DBNAME_HAPI')
DB_MODE = os.getenv('DB_MODE')
HOST = os.getenv('DBHOST')
TERMINOLOGY_PATH = os.getenv('MIMIC_TERMINOLOGY_PATH')
FHIR_SERVER = os.getenv('FHIR_SERVER')
FHIR_BUNDLE_ERROR_PATH = os.getenv('FHIR_BUNDLE_ERROR_PATH')
FHIR_VALIDATOR = os.getenv('FHIR_VALIDATOR')

GCP_PROJECT = os.getenv('GCP_PROJECT')
GCP_TOPIC = os.getenv('GCP_TOPIC')
GCP_LOCATION = os.getenv('GCP_LOCATION')
GCP_BUCKET = os.getenv('GCP_BUCKET')
GCP_DATASET = os.getenv('GCP_DATASET')
GCP_FHIRSTORE = os.getenv('GCP_FHIRSTORE')
GCP_EXPORT_FOLDER = os.getenv('GCP_EXPORT_FOLDER')
GCP_TOPIC_PATIENT_EVERYTHING = os.getenv('GCP_TOPIC_PATIENT_EVERYTHING')


# Example patient that has links to all other resources
def patient_id():
    return '01aa15d9-3114-5220-b492-332361c2f91c'


# Function to warn against the extensive use of Java Validator
def warn_java_validator():
    window = tk.Tk()
    width = 600
    height = 200
    screen_width = window.winfo_screenwidth()  # width of the screen
    screen_height = window.winfo_screenheight()  # height of the screen

    # calculate x and y coordinates for the Tk root window
    x = (screen_width / 2) - (width / 2)
    y = (screen_height / 2) - (height / 2)

    # set the dimensions of the screen
    # and where it is placed
    window.geometry('%dx%d+%d+%d' % (width, height, x, y))

    warning = tk.Label(
        text="""
        WARNING:\n
        DO NOT RUN all validation tests with Java Validator.
        Run individual tests, or Java Validator will crash everything.
        Abort multiple tests recommended.
        """,
        width=300,
        height=100,
        fg='red'
    )
    warning.pack()
    window.mainloop()


# Set validator for the session
@pytest.fixture(scope="session")
def validator():
    if FHIR_VALIDATOR == 'JAVA':
        warn_java_validator()
    return FHIR_VALIDATOR
    #------------------------ WARNING ---------------------------
    # DO NOT RUN all validation tests when JAVA is set
    # Run individual tests, or java validator will crash everything
    # Need to explore way to run all test with java validator, but not
    # working right now


# Initialize database connection to mimic
@pytest.fixture(scope="session")
def db_conn():
    conn = connect_db(SQLUSER, SQLPASS, DBNAME_MIMIC, HOST, DB_MODE)
    return conn


# Initialize database name to either mimic or mimic_demo
@pytest.fixture(scope="session")
def dbname():
    return DBNAME_MIMIC


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


# Initialize mimic args
@pytest.fixture(scope="session")
def margs():
    mimic_args = MimicArgs(FHIR_SERVER, FHIR_BUNDLE_ERROR_PATH, FHIR_VALIDATOR)
    return mimic_args


# Initialize gcp args
@pytest.fixture(scope="session")
def gcp_args():
    gcp_args = GoogleArgs(
        GCP_PROJECT, GCP_TOPIC, GCP_LOCATION, GCP_BUCKET, GCP_DATASET,
        GCP_FHIRSTORE, GCP_EXPORT_FOLDER
    )
    return gcp_args


# Initialize patient everything args
@pytest.fixture(scope="session")
def pe_args():
    pe_args = PatientEverythingArgs(
        patient_bundle=False,
        num_patients=1,
        resource_types='Patient,Encounter,Condtion,Procedure',
        topic=GCP_TOPIC_PATIENT_EVERYTHING,
        count=100
    )
    return pe_args


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
    resource = db_read_query(q_resource, db_conn)

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


# Return a single location resource
@pytest.fixture(scope="session")
def location_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'location')


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


# Return a single medication dispense resource
@pytest.fixture(scope="session")
def medication_dispense_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'medication_dispense')


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


# Return a single observation_labevents resource
@pytest.fixture(scope="session")
def observation_labevents_resource(validator, db_conn):
    return initialize_single_resource(
        validator, db_conn, 'observation_labevents'
    )


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


# Return a single organization resource
@pytest.fixture(scope="session")
def organization_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'organization')


# Return a single procedure resource
@pytest.fixture(scope="session")
def procedure_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'procedure')


# Return a single procedure_icu resource
@pytest.fixture(scope="session")
def procedure_icu_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'procedure_icu')


# Return a single specimen resource
@pytest.fixture(scope="session")
def specimen_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'specimen')


# Return a single specimen resource
@pytest.fixture(scope="session")
def specimen_lab_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'specimen_lab')


#----------------------------------------------------------------
#----------------- MIMIMC ED RESOURCES --------------------------
#----------------------------------------------------------------


# Return a single encounter ed resource
@pytest.fixture(scope="session")
def encounter_ed_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'encounter_ed')


# Return a single condition ed resource
@pytest.fixture(scope="session")
def condition_ed_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'condition_ed')


# Return a single medication dispense ed resource
@pytest.fixture(scope="session")
def medication_dispense_ed_resource(validator, db_conn):
    return initialize_single_resource(
        validator, db_conn, 'medication_dispense_ed'
    )


# Return a single medication statement ed resource
@pytest.fixture(scope="session")
def medication_statement_ed_resource(validator, db_conn):
    return initialize_single_resource(
        validator, db_conn, 'medication_statement_ed'
    )


# Return a single observation  ed resource
@pytest.fixture(scope="session")
def observation_ed_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'observation_ed')


# Return a single observation vital signs resource
@pytest.fixture(scope="session")
def observation_vital_signs_resource(validator, db_conn):
    return initialize_single_resource(
        validator, db_conn, 'observation_vital_signs'
    )


# Return a single procedure ed resource
@pytest.fixture(scope="session")
def procedure_ed_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'procedure_ed')


#----------------------------------------------------------------
#----------------- DATA BUNDLE RESOURCES -----------------------------
#----------------------------------------------------------------


# Grab a handful of medication data resoruces to send to the server
@pytest.fixture(scope="session")
def med_data_bundle_resources(db_conn):
    resources = get_n_resources(db_conn, 'medication')
    return resources


@pytest.fixture(scope="session")
def med_mix_data_bundle_resources(db_conn):
    resources = get_n_resources(db_conn, 'medication_mix')
    return resources


@pytest.fixture(scope="session")
def organization_bundle_resources(db_conn):
    resources = get_n_resources(db_conn, 'organization')
    return resources


@pytest.fixture(scope="session")
def location_bundle_resources(db_conn):
    resources = get_n_resources(db_conn, 'location')
    return resources


#----------------------------------------------------------------
#---------------------- TERMINOLOGY -----------------------------
#----------------------------------------------------------------


# Initialize terminology meta data
@pytest.fixture(scope="session")
def meta(db_conn):
    meta = TerminologyMetaData(db_conn)
    return meta


# Initialize terminology path
@pytest.fixture(scope="session")
def terminology_path(db_conn):
    return TERMINOLOGY_PATH


# Example codeystem
@pytest.fixture(scope="session")
def example_codesystem(db_conn, meta):
    mimic_codesystem = 'lab_flags'
    codesystem = trm.generate_codesystem(mimic_codesystem, db_conn, meta)
    return codesystem


# Example valueset
@pytest.fixture(scope="session")
def example_valueset(db_conn, meta):
    mimic_valueset = 'lab_flags'
    valueset = trm.generate_valueset(mimic_valueset, db_conn, meta)
    return valueset
