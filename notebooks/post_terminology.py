import requests
import json
import ndjson
import os
import pandas as pd
from pathlib import Path
from dotenv import load_dotenv
from py_mimic_fhir.lookup import MIMIC_CODESYSTEMS, MIMIC_VALUESETS

# Environment variables
load_dotenv(Path(__file__).parent.parent.resolve() / '.env')

FHIR_SERVER = os.getenv('FHIR_SERVER')
MIMIC_TERMINOLOGY_PATH = os.getenv('MIMIC_TERMINOLOGY_PATH')
print(f'CWD Directory: {os.getcwd()}')
print(f'MIMIC_TERMINOLOGY_PATH: {MIMIC_TERMINOLOGY_PATH}')


# PUT resources to HAPI fhir server
def put_resource(resource, fhir_data):
    server = FHIR_SERVER
    url = server + resource + '/' + fhir_data['id']

    resp = requests.put(
        url, json=fhir_data, headers={"Content-Type": "application/fhir+json"}
    )
    output = json.loads(resp.text)
    return output


# Base path to resources
base_path = Path(MIMIC_TERMINOLOGY_PATH)
version = '0.1.1'  # Need to change version to trigger expansion (does not need to be greater just different)

for codesystem in MIMIC_CODESYSTEMS:
    codesystem_file = f'CodeSystem-{codesystem}.json'
    codesystem_path = base_path / codesystem_file
    with open(codesystem_path, mode='r') as cs_content:
        cs = json.load(cs_content)

    cs['version'] = version
    put_resource('CodeSystem', cs)

for valueset in MIMIC_VALUESETS:
    valueset_file = f'ValueSet-{valueset}.json'
    valueset_path = base_path / valueset_file
    with open(valueset_path, mode='r') as vs_content:
        vs = json.load(vs_content)

    vs['version'] = version
    put_resource('ValueSet', vs)
