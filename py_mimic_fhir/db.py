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