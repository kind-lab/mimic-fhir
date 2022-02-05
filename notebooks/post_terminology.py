import requests
import json
import ndjson
import os
import pandas as pd
from pathlib import Path
import time


# PUT resources to HAPI fhir server
def put_resource(resource, fhir_data):
    server = 'http://localhost:8080/fhir/'
    url = server + resource + '/' + fhir_data['id']

    resp = requests.put(
        url, json=fhir_data, headers={"Content-Type": "application/fhir+json"}
    )
    output = json.loads(resp.text)
    return output


# Base path to resources
base_path = Path('/home/alex/git/mimic-profiles/input/resources/')
version = '0.1.1'  # Need to change version to trigger expansion (does not need to be greater just different)

codesystems = [
    'admission-class', 'admission-type', 'admission-type-icu', 'admit-source',
    'bodysite', 'd-items', 'd-labitems', 'diagnosis-icd9', 'diagnosis-icd10',
    'discharge-disposition', 'lab-flags', 'medadmin-category-icu',
    'medication-method', 'medication-route', 'medication-site',
    'microbiology-antibiotic', 'microbiology-interpretation',
    'microbiology-organism', 'microbiology-test', 'mimic-observation-category',
    'procedure-category', 'procedure-icd9', 'procedure-icd10', 'units'
]

valuesets = [
    'admission-class', 'admission-type', 'admission-type-icu', 'admit-source',
    'bodysite', 'chartevents-d-items', 'datetime-d-items', 'd-labitems',
    'diagnosis-icd', 'discharge-disposition', 'lab-flags',
    'medadmin-category-icu', 'medication-method', 'medication-route',
    'medication-site', 'microbiology-antibiotic', 'microbiology-interpretation',
    'microbiology-organism', 'microbiology-test', 'mimic-observation-category',
    'outputevents-d-items', 'procedure-category', 'procedure-d-items',
    'procedure-icd', 'units'
]

for codesystem in codesystems:
    codesystem_file = 'CodeSystem-' + codesystem + '.json'
    codesystem_path = base_path / codesystem_file
    with open(codesystem_path, mode='r') as cs_content:
        cs = json.load(cs_content)

    cs['version'] = version
    put_resource('CodeSystem', cs)

for valueset in valuesets:
    valueset_file = 'ValueSet-' + valueset + '.json'
    valueset_path = base_path / valueset_file
    with open(valueset_path, mode='r') as vs_content:
        vs = json.load(vs_content)

    vs['version'] = version
    put_resource('ValueSet', vs)
