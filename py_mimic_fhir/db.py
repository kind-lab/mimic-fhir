import numpy as np
import pandas as pd
import json
import psycopg2
import requests
import base64
from pathlib import Path
import os
import time
import logging
from dotenv import load_dotenv

# load environment variables
load_dotenv(load_dotenv(Path(Path.cwd()).parents[0] / '.env'))
SQLUSER = os.getenv('SQLUSER')
SQLPASS = os.getenv('SQLPASS')
DBNAME_MIMIC = os.getenv('DBNAME_MIMIC')
HOST = os.getenv('HOST')


# database connection
def db_conn():
    sqluser = SQLUSER
    sqlpass = SQLPASS
    dbname = DBNAME_MIMIC
    host = HOST

    conn = psycopg2.connect(
        dbname=dbname, user=sqluser, password=sqlpass, host=host
    )
    return conn