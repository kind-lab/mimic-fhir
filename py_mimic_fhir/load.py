import pandas as pd
import logging
import shutil
import os
import json
import ndjson
from datetime import datetime
from py_mimic_fhir.db import connect_db, get_n_patient_id, get_resource_by_id
from py_mimic_fhir.bundle import Bundle, get_n_resources
from py_mimic_fhir.lookup import MIMIC_BUNDLE_TABLE_LIST, MIMIC_DATA_BUNDLE_LIST

logger = logging.getLogger(__name__)


def load_resources_to_server(resources, bundle_name, margs):
    bundle = Bundle(bundle_name)
    bundle.add_entry(resources)
    response = bundle.request(margs.fhir_server, margs.err_path)
    return response


def load_ndjson_from_file(json_path, profile):
    infilename = f'{json_path}/{profile}.ndjson'
    with open(infilename, 'r') as infile:
        resources = ndjson.load(infile)

    return resources
