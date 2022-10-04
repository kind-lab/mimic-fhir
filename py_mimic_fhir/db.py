import psycopg2
import logging
import json
import pandas as pd
import pandas_gbq as pdq
import google.auth


# database connection
def connect_db(sqluser, sqlpass, dbname, host, db_mode, port=5432):
    if db_mode == 'POSTGRES':
        connection = psycopg2.connect(
            dbname=dbname, user=sqluser, password=sqlpass, host=host, port=port
        )
    elif db_mode == 'BIGQUERY':
        credentials, project = google.auth.default()
        pdq.context.credentials = credentials
        pdq.context.project = project
        connection = db_mode
    else:
        connection = db_mode
    return connection


# --------------------------------------------------------
# ---------------- accessor functions to db --------------
#---------------------------------------------------------


def db_read_query(query, db_conn):
    if db_conn == 'BIGQUERY':
        df = pdq.read_gbq(query)
        if 'fhir' in df.columns:
            df['fhir'] = df['fhir'].apply(json.loads)
    else:
        df = pd.read_sql_query(query, db_conn)

    return df


def get_table(db_conn, schema, table):
    q_table = f"SELECT * FROM {schema}.{table};"
    df_table = db_read_query(q_table, db_conn)
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
    pd_resources = db_read_query(q_resource, db_conn)
    resources = pd_resources.fhir.to_list()

    return resources


# Generic function to get single resource from the DB
def get_patient_resource(db_conn, patient_id):
    q_resource = f"SELECT * FROM mimic_fhir.patient WHERE id='{patient_id}'"
    resource = db_read_query(q_resource, db_conn)

    return resource.fhir[0]


# Get any resource by its id
def get_resource_by_id(db_conn, profile, profile_id):
    q_resource = f"SELECT * FROM mimic_fhir.{profile} WHERE id='{profile_id}'"
    resource = db_read_query(q_resource, db_conn)

    return resource.fhir[0]


def get_n_patient_id(db_conn, n_patient):
    q_resource = f"SELECT * FROM mimic_fhir.patient LIMIT {n_patient}"
    resource = db_read_query(q_resource, db_conn)
    patient_ids = [fhir['id'] for fhir in resource.fhir]

    return patient_ids


def get_n_resources(db_conn, table, n_limit=0):
    if n_limit == 0:
        q_resource = f"SELECT * FROM mimic_fhir.{table}"
    else:
        q_resource = f"SELECT * FROM mimic_fhir.{table} LIMIT {n_limit}"
    resource = db_read_query(q_resource, db_conn)

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

    resource = db_read_query(q_resource, db_conn)
    return resource.fhir[0]['id']
