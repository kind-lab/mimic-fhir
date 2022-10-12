import psycopg2
import logging
import json
import pandas as pd
import pandas_gbq as pdq
import google.auth


class MFDatabaseConnection():
    def __init__(self, sqluser, sqlpass, dbname, host, db_mode, port=5432):
        self.db_conn = self.connect_db(
            sqluser, sqlpass, dbname, host, db_mode, port
        )
        self.db_mode = db_mode

    # database connection
    def connect_db(self, sqluser, sqlpass, dbname, host, db_mode, port=5432):
        if db_mode == 'POSTGRES':
            connection = psycopg2.connect(
                dbname=dbname,
                user=sqluser,
                password=sqlpass,
                host=host,
                port=port
            )
            connection.set_session(readonly=True)
        elif db_mode == 'BIGQUERY':
            credentials, project = google.auth.default()
            pdq.context.credentials = credentials
            pdq.context.project = project
            connection = db_mode
        else:
            connection = db_mode
        return connection

    def close(self):
        if self.db_mode == 'POSTGRES':
            self.db_conn.close()

    def read_query(self, query):
        if self.db_conn == 'BIGQUERY':
            df = pdq.read_gbq(query)
            if 'fhir' in df.columns:
                df['fhir'] = df['fhir'].apply(json.loads)
        else:
            df = pd.read_sql_query(query, self.db_conn)

        return df

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
            q_resource = f"SELECT * FROM mimic_fhir.patient"
        else:
            q_resource = f"SELECT * FROM mimic_fhir.patient LIMIT {n_patient}"
        resource = self.read_query(q_resource)
        patient_ids = [fhir['id'] for fhir in resource.fhir]

        return patient_ids

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
