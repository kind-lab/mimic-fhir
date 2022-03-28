import psycopg2
import logging


# database connection
def db_conn(sqluser, sqlpass, dbname, host):
    sqluser = sqluser
    sqlpass = sqlpass
    dbname = dbname
    host = host

    connection = psycopg2.connect(
        dbname=dbname, user=sqluser, password=sqlpass, host=host
    )
    return connection


def get_table(db_conn, schema, table):
    q_table = f"SELECT * FROM {schema}.{table};"
    df_table = pd.read_sql_query(q_table, db_conn)
    return df_table