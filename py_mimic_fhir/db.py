import psycopg2
import logging
import json
import pandas as pd
import pandas_gbq as pdq
import google.auth
from sqlalchemy import create_engine, URL

class MFDatabaseConnection():
    def __init__(self, sqluser, sqlpass, dbname, host, port=5432):
        # default is to connect with SQLAlchemy to postgresql
        engine = create_engine(
            f'postgresql://{sqluser}:{sqlpass}@{host}:{port}/{dbname}'
        )
        self.engine = engine
        self.con = engine.connect()
        self.db_mode = 'Postgres'

    def close(self):
        self.con.close()

    def read_query(self, query):
        return pd.read_sql_query(query, self.con)

    def get_table(self, schema, table):
        q_table = f"SELECT * FROM {schema}.{table};"
        df_table = self.read_query(q_table)
        return df_table

    def get_resources_by_pat(self, table_name, patient_id):
        if table_name == 'patient':
            id_field = 'id'
        else:
            id_field = 'patient_id'

        q_resource = f"""
            SELECT fhir FROM mimic_fhir.{table_name}
            WHERE {id_field} = '{patient_id}'
        """
        pd_resources = self.read_query(q_resource)
        resources = pd_resources.fhir.to_list()

        return resources

    def get_resource_by_id(self, profile, profile_id):
        q_resource = f"SELECT * FROM mimic_fhir.{profile} WHERE id='{profile_id}'"
        resource = self.read_query(q_resource)

        return resource.fhir[0]

    def get_n_patient_id(self, n_patient=0):
        if n_patient == 0:
            q_resource = f"SELECT * FROM mimic_fhir.patient ORDER BY id"
        else:
            q_resource = f"SELECT * FROM mimic_fhir.patient ORDER BY id LIMIT {n_patient}"
        resource = self.read_query(q_resource)
        patient_ids = [fhir['id'] for fhir in resource.fhir]

        return patient_ids

    def get_patient_id(self, n_patient: int=0):
        if n_patient == 0:
            q_resource = f"SELECT id FROM mimic_fhir.patient ORDER BY id"
        else:
            q_resource = f"SELECT id FROM mimic_fhir.patient ORDER BY id LIMIT {n_patient}"
        resource = self.read_query(q_resource)
        return resource['fhir'].tolist()

    def get_n_resources(self, table, n_limit=0):
        if n_limit == 0:
            q_resource = f"SELECT * FROM mimic_fhir.{table}"
        else:
            q_resource = f"SELECT * FROM mimic_fhir.{table} LIMIT {n_limit}"
        resource = self.read_query(q_resource)

        resources = []
        [resources.append(fhir) for fhir in resource.fhir]
        return resources

    # Function to find links between a patient and certain resources.
    # Allows for more complete testing if sending full bundle
    def get_pat_id_with_links(self, resource_list):
        q_resource = 'SELECT pat.fhir FROM mimic_fhir.patient pat'

        # Dynamically create query to find links between a patient and certain resources
        for idx, resource in enumerate(resource_list):
            q_resource = f"""{q_resource} 
                INNER JOIN mimic_fhir.{resource} t{idx}
                    ON pat.id = t{idx}.patient_id 
            """
        q_resource = f'{q_resource} LIMIT 20;'

        resource = self.read_query(q_resource)
        return resource.fhir[0]['id']


class BigQueryDB(MFDatabaseConnection):
    def connect_db(self, sqluser, sqlpass, dbname, host, port=5432):
        self.credentials, self.project = google.auth.default()
        pdq.context.credentials = self.credentials
        pdq.context.project = self.project
        self.db_mode = 'BigQuery'
    
    def read_query(self, query):
        df = pdq.read_gbq(query)
        if 'fhir' in df.columns:
            df['fhir'] = df['fhir'].apply(json.loads)
        return df

    def close(self):
        pass
class PostgresDB(MFDatabaseConnection):
    def __repr__(self):
        return f"PostgresDB(sqluser={self.sqluser}, sqlpass={self.sqlpass}, dbname={self.dbname}, host={self.host}, port={self.port})"