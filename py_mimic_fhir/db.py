import psycopg2
import logging
import pandas as pd


# database connection
def connect_db(sqluser, sqlpass, dbname, host):
    sqluser = sqluser
    sqlpass = sqlpass
    dbname = dbname
    host = host

    connection = psycopg2.connect(
        dbname=dbname, user=sqluser, password=sqlpass, host=host
    )
    return connection


# --------------------------------------------------------
# ---------------- accessor functions to db --------------
#---------------------------------------------------------


def get_table(db_conn, schema, table):
    q_table = f"SELECT * FROM {schema}.{table};"
    df_table = pd.read_sql_query(q_table, db_conn)
    return df_table


# Generic function to get resources linked to patient from the DB
def get_resources_by_pat(db_conn, table_name, patient_id):
    if table_name == 'patient':
        id_field = 'id'
    else:
        id_field = 'patient_id'

    q_resource = f"""
        SELECT fhir FROM mimic_fhir.{table_name}
        WHERE {id_field} = '{patient_id}'
    """
    pd_resources = pd.read_sql_query(q_resource, db_conn)
    resources = pd_resources.fhir.to_list()

    return resources


# Generic function to get single resource from the DB
def get_patient_resource(db_conn, patient_id):
    q_resource = f"SELECT * FROM mimic_fhir.patient WHERE id='{patient_id}'"
    resource = pd.read_sql_query(q_resource, db_conn)

    return resource.fhir[0]


# Get any resource by its id
def get_resource_by_id(db_conn, profile, profile_id):
    q_resource = f"SELECT * FROM mimic_fhir.{profile} WHERE id='{profile_id}'"
    resource = pd.read_sql_query(q_resource, db_conn)

    return resource.fhir[0]


def get_n_patient_id(db_conn, n_patient):
    q_resource = f"SELECT * FROM mimic_fhir.patient LIMIT {n_patient}"
    resource = pd.read_sql_query(q_resource, db_conn)
    patient_ids = [fhir['id'] for fhir in resource.fhir]

    return patient_ids


def get_n_resources(db_conn, table, n_limit=0):
    if n_limit == 0:
        q_resource = f"SELECT * FROM mimic_fhir.{table}"
    else:
        q_resource = f"SELECT * FROM mimic_fhir.{table} LIMIT {n_limit}"
    resource = pd.read_sql_query(q_resource, db_conn)

    resources = []
    [resources.append(fhir) for fhir in resource.fhir]
    return resources


# Function to find links between a patient and certain resources.
# Allows for more complete testing if sending full bundle
def get_pat_id_with_links(db_conn, resource_list):
    q_resource = 'SELECT pat.fhir FROM mimic_fhir.patient pat'

    # Dynamically create query to find links between a patient and certain resources
    for idx, resource in enumerate(resource_list):
        q_resource = f"""{q_resource} 
            INNER JOIN mimic_fhir.{resource} t{idx}
                ON pat.id = t{idx}.patient_id 
        """
    q_resource = f'{q_resource} LIMIT 20;'

    resource = pd.read_sql_query(q_resource, db_conn)
    return resource.fhir[0]['id']
