import requests
import json
import ndjson
import os
import pandas as pd
from pathlib import Path
from dotenv import load_dotenv

# Environment variables
load_dotenv(Path(Path.cwd()).parents[0] / '.env')

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

codesystems = [
    'admission_class', 'admission_type', 'admission_type_icu', 'admit_source',
    'bodysite', 'd_items', 'd_labitems', 'diagnosis_icd9',
    'discharge_disposition', 'identifier_type', 'lab_flags', 'lab_fluid',
    'lab_priority', 'medadmin_category_icu', 'medication_icu',
    'medication_formulary_drug_cd', 'medication_method', 'medication_mix',
    'medication_name', 'medication_poe_iv', 'medication_route',
    'medication_site', 'microbiology_antibiotic', 'microbiology_interpretation',
    'microbiology_organism', 'microbiology_test', 'observation_category',
    'procedure_category', 'procedure_icd9', 'procedure_icd10', 'spec_type_desc',
    'units'
]

valuesets = [
    'admission_class', 'admission_type', 'admission_type_icu', 'admit_source',
    'bodysite', 'chartevents_d_items', 'd_labitems', 'datetimeevents_d_items',
    'diagnosis_icd', 'discharge_disposition', 'identifier_type', 'lab_flags',
    'lab_priority', 'medadmin_category_icu', 'medication', 'medication_method',
    'medication_route', 'medication_site', 'microbiology_antibiotic',
    'microbiology_interpretation', 'microbiology_organism', 'microbiology_test',
    'observation_category', 'outputevents_d_items', 'procedure_category',
    'procedureevents_d_items', 'procedure_icd', 'specimen_type', 'units'
]

for codesystem in codesystems:
    codesystem_file = f'CodeSystem-{codesystem}.json'
    codesystem_path = base_path / codesystem_file
    with open(codesystem_path, mode='r') as cs_content:
        cs = json.load(cs_content)

    cs['version'] = version
    put_resource('CodeSystem', cs)

for valueset in valuesets:
    valueset_file = f'ValueSet-{valueset}.json'
    valueset_path = base_path / valueset_file
    with open(valueset_path, mode='r') as vs_content:
        vs = json.load(vs_content)

    vs['version'] = version
    put_resource('ValueSet', vs)
