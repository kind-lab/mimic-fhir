from pathlib import Path
import json
import pandas as pd
import psycopg2
from dotenv import load_dotenv
import os
import tkinter as tk

import pytest

# Load environment variables
load_dotenv(Path(Path.cwd()).parents[0] / '.env')

SQLUSER = os.getenv('SQLUSER')
SQLPASS = os.getenv('SQLPASS')
DBNAME_MIMIC = os.getenv('DBNAME_MIMIC')
DBNAME_HAPI = os.getenv('DBNAME_HAPI')
HOST = os.getenv('HOST')


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
    validator = 'HAPI'  # JAVA or HAPI
    if validator == 'JAVA':
        warn_java_validator()
    return validator
    #------------------------ WARNING ---------------------------
    # DO NOT RUN all validation tests when JAVA is set
    # Run individual tests, or java validator will crash everything
    # Need to explore way to run all test with java validator, but not
    # working right now


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


# Generic function to get N resources from the DB
def get_n_resources(db_conn, table_name, n_limit):
    q_resources = f"SELECT * FROM mimic_fhir.{table_name} LIMIT {n_limit}"
    resources = pd.read_sql_query(q_resources, db_conn)

    return resources


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


# Return a single specimen resource
@pytest.fixture(scope="session")
def specimen_resource(validator, db_conn):
    return initialize_single_resource(validator, db_conn, 'specimen')


#----------------------------------------------------------------
#----------------- BUNDLE RESOURCES -----------------------------
#----------------------------------------------------------------


# Function to find links between a patient and certain resources
def get_pat_resource_with_links(db_conn, resource_list):
    q_resource = 'SELECT pat.fhir FROM mimic_fhir.patient pat'

    # Dynamically create query to find links between a patient and certain resources
    for idx, resource in enumerate(resource_list):
        q_resource = f"""{q_resource} 
            INNER JOIN mimic_fhir.{resource} t{idx}
                ON pat.id = t{idx}.patient_id 
        """
    q_resource = f'{q_resource} LIMIT 1;'

    resource = pd.read_sql_query(q_resource, db_conn)
    return resource.fhir[0]


# Generic function to get resources linked to patient from the DB
def get_resources_by_pat(db_conn, table_name, patient_id):
    q_resource = f"""
        SELECT fhir FROM mimic_fhir.{table_name}
        WHERE patient_id = '{patient_id}'
    """
    resources = pd.read_sql_query(q_resource, db_conn)

    return resources


# Return a patient bundle (include Patient, Encounter, Condition, Procedure)
@pytest.fixture(scope="session")
def patient_bundle_resources(db_conn):
    resources = []
    resource_list = ['encounter', 'condition', 'procedure']
    patient_resource = get_pat_resource_with_links(db_conn, resource_list)

    # Get all linked Encounter/Condition/Procedure resources to this patient
    encounter_resources = get_resources_by_pat(
        db_conn, 'encounter', patient_resource['id']
    )
    condition_resources = get_resources_by_pat(
        db_conn, 'condition', patient_resource['id']
    )
    procedure_resources = get_resources_by_pat(
        db_conn, 'procedure', patient_resource['id']
    )

    # Get all the patient resources into the master list
    resources.append(patient_resource)
    [resources.append(fhir) for fhir in encounter_resources.fhir]
    [resources.append(fhir) for fhir in condition_resources.fhir]
    [resources.append(fhir) for fhir in procedure_resources.fhir]
    return resources


# Return a micro bundle (include Specimen, ObservationMicroTest, ObservationMicroOrg, ObservationMicroSusc)
@pytest.fixture(scope="session")
def microbio_bundle_resources(db_conn):
    resources = []
    resource_list = [
        'observation_micro_test', 'observation_micro_org',
        'observation_micro_susc'
    ]
    patient_resource = get_pat_resource_with_links(db_conn, resource_list)

    # Get all linked ObservationMicro test/org/susc resources to this patient
    micro_test_resources = get_resources_by_pat(
        db_conn, 'observation_micro_test', patient_resource['id']
    )
    micro_org_resources = get_resources_by_pat(
        db_conn, 'observation_micro_org', patient_resource['id']
    )
    micro_susc_resources = get_resources_by_pat(
        db_conn, 'observation_micro_susc', patient_resource['id']
    )
    specimen_resources = get_resources_by_pat(
        db_conn, 'specimen', patient_resource['id']
    )

    # Get all the patient resources into the master list
    resources.append(patient_resource)
    [resources.append(fhir) for fhir in micro_test_resources.fhir]
    [resources.append(fhir) for fhir in micro_org_resources.fhir]
    [resources.append(fhir) for fhir in micro_susc_resources.fhir]
    [resources.append(fhir) for fhir in specimen_resources.fhir]
    return resources


# Return a labs bundle (include ObservationLabs and Specimen)
@pytest.fixture(scope="session")
def lab_bundle_resources(db_conn):
    resources = []
    resource_list = ['observation_labs']
    patient_resource = get_pat_resource_with_links(db_conn, resource_list)

    # Get all linked ObservationLabs and Specimen to the patient
    lab_resources = get_resources_by_pat(
        db_conn, 'observation_labs', patient_resource['id']
    )
    specimen_resources = get_resources_by_pat(
        db_conn, 'specimen', patient_resource['id']
    )

    # Get all the patient resources into the master list
    resources.append(patient_resource)
    [resources.append(fhir) for fhir in lab_resources.fhir]
    [resources.append(fhir) for fhir in specimen_resources.fhir]
    return resources


# Grab a handful of medication data resoruces to send to the server
@pytest.fixture(scope="session")
def med_data_bundle_resources(db_conn):
    n_limit = 100
    q_resources = f'SELECT fhir FROM mimic_fhir.medication LIMIT {n_limit}'
    med_resources = pd.read_sql_query(q_resources, db_conn)

    resources = []
    [resources.append(fhir) for fhir in med_resources.fhir]
    return resources


# Return a meds bundle (include MedicationRequest, MedicationDispense, MedicationAdministration)
@pytest.fixture(scope="session")
def med_pat_bundle_resources(db_conn):
    resources = []

    #!!! TO DO: Add MedicationDispense when medication PR is integrated
    resource_list = ['medication_request', 'medication_administration']
    patient_resource = get_pat_resource_with_links(db_conn, resource_list)

    # Get all linked MedicationRequest, MedicationDispense, and MedicationAdministration resources to this patient
    med_req_resources = get_resources_by_pat(
        db_conn, 'medication_request', patient_resource['id']
    )
    med_admin_resources = get_resources_by_pat(
        db_conn, 'medication_administration', patient_resource['id']
    )

    # Get all the patient resources into the master list
    resources.append(patient_resource)
    [resources.append(fhir) for fhir in med_req_resources.fhir]
    [resources.append(fhir) for fhir in med_admin_resources.fhir]
    return resources


# Return an icu bundle (include EncounterICU, MedicationAdministrationICU)
@pytest.fixture(scope="session")
def icu_base_bundle_resources(db_conn):
    resources = []

    resource_list = [
        'encounter_icu', 'medication_administration_icu', 'procedure_icu'
    ]
    patient_resource = get_pat_resource_with_links(db_conn, resource_list)

    # Get all linked EncounterICU and MedicationAdministrationICU resources to this patient
    enc_resources = get_resources_by_pat(
        db_conn, 'encounter', patient_resource['id']
    )
    enc_icu_resources = get_resources_by_pat(
        db_conn, 'encounter_icu', patient_resource['id']
    )
    med_admin_icu_resources = get_resources_by_pat(
        db_conn, 'medication_administration_icu', patient_resource['id']
    )
    proc_icu_resources = get_resources_by_pat(
        db_conn, 'procedure_icu', patient_resource['id']
    )

    # Get all the patient resources into the master list
    resources.append(patient_resource)
    [resources.append(fhir) for fhir in enc_resources.fhir]
    [resources.append(fhir) for fhir in enc_icu_resources.fhir]
    [resources.append(fhir) for fhir in med_admin_icu_resources.fhir]
    [resources.append(fhir) for fhir in proc_icu_resources.fhir]
    return resources


# Return an observation icu bundle (include ObservationChartevents, ObservationDatetimeevents, ObservationOutputevents)
@pytest.fixture(scope="session")
def icu_observation_bundle_resources(db_conn):
    resources = []

    resource_list = [
        'observation_chartevents', 'observation_datetimeevents',
        'observation_outputevents'
    ]
    patient_resource = get_pat_resource_with_links(db_conn, resource_list)

    # Get all linked ObservationChartevents, ObservationDatetimeevents, ObservationOutputevents resources to this patient
    obs_ce_resources = get_resources_by_pat(
        db_conn, 'observation_chartevents', patient_resource['id']
    )
    obs_de_resources = get_resources_by_pat(
        db_conn, 'observation_datetimeevents', patient_resource['id']
    )
    obs_oo_resources = get_resources_by_pat(
        db_conn, 'observation_outputevents', patient_resource['id']
    )

    # Get all the patient resources into the master list
    resources.append(patient_resource)
    [resources.append(fhir) for fhir in obs_ce_resources.fhir]
    [resources.append(fhir) for fhir in obs_de_resources.fhir]
    [resources.append(fhir) for fhir in obs_oo_resources.fhir]
    return resources
