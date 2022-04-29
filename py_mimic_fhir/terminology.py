from fhir.resources.codesystem import CodeSystem
from fhir.resources.valueset import ValueSet
from datetime import datetime
import logging
import pandas as pd
import json

from py_mimic_fhir.db import connect_db, get_table
from py_mimic_fhir.lookup import (
    MIMIC_CODESYSTEMS, MIMIC_VALUESETS, VALUESETS_CODED,
    VALUESETS_DOUBLE_SYSTEM, VALUESETS_CANONICAL
)

logger = logging.getLogger(__name__)


# Common meta data across all MIMIC Terminology
class TerminologyMetaData():
    def __init__(self, db_conn, version='0.4', status='draft'):
        self.status = status
        self.content = 'complete'
        self.version = version
        self.publisher = 'KinD Lab'
        self.language = 'en'
        self.current_date = str(
            datetime.now().strftime('%Y-%m-%dT%H:%M:%S-04:00')
        )
        self.base_url = 'http://fhir.mimic.mit.edu'
        self.set_cs_descriptions(db_conn)
        self.set_vs_descriptions(db_conn)

    def set_cs_descriptions(self, db_conn):
        self.cs_descriptions = get_table(db_conn, 'fhir_trm', 'cs_descriptions')

    def set_vs_descriptions(self, db_conn):
        self.vs_descriptions = get_table(db_conn, 'fhir_trm', 'vs_descriptions')


# Master terminology function. Creates all CodeSystems and ValueSets
def generate_all_terminology(args):
    db_conn = connect_db(
        args.sqluser, args.sqlpass, args.dbname_mimic, args.host
    )
    meta = TerminologyMetaData(db_conn, args.version, args.status)
    generate_codesystems(db_conn, meta, args.terminology_path)
    generate_valuesets(db_conn, meta, args.terminology_path)


def generate_codesystems(db_conn, meta, terminology_path):
    for mimic_codesystem in MIMIC_CODESYSTEMS:
        logger.info(f'Generating CodeSystem: {mimic_codesystem}')
        codesystem = generate_codesystem(mimic_codesystem, db_conn, meta)
        write_terminology(codesystem, terminology_path)


def generate_valuesets(db_conn, meta, terminology_path):
    for mimic_valueset in MIMIC_VALUESETS:
        logger.info(f'Generating ValueSet: {mimic_valueset}')
        valueset = generate_valueset(mimic_valueset, db_conn, meta)
        write_terminology(valueset, terminology_path)


def generate_codesystem(mimic_codesystem, db_conn, meta):
    codesystem = CodeSystem(status=meta.status, content=meta.content)
    codesystem.id = mimic_codesystem.replace('_', '-')
    codesystem.url = f'{meta.base_url}/CodeSystem/{codesystem.id}'
    codesystem.version = meta.version
    codesystem.language = meta.language
    codesystem.name = mimic_codesystem.title().replace('_', '')
    codesystem.title = codesystem.name
    codesystem.date = meta.current_date
    codesystem.publisher = meta.publisher
    codesystem.description = meta.cs_descriptions[
        meta.cs_descriptions['codesystem'] == mimic_codesystem
    ]['description'].iloc[0]

    # Generate code/display combos from the fhir_trm table
    df_codesystem = get_table(db_conn, 'fhir_trm', f'cs_{mimic_codesystem}')
    concept = generate_concept(df_codesystem)
    codesystem.concept = concept

    # Set canonical valueset if relevant
    if mimic_codesystem in VALUESETS_CANONICAL:
        codesystem.valueSet = f'{meta.base_url}/ValueSet/{codesystem.id}'

    return codesystem


def generate_valueset(mimic_valueset, db_conn, meta):
    valueset = ValueSet(status=meta.status)
    valueset.id = mimic_valueset.replace('_', '-')
    valueset.url = f'{meta.base_url}/ValueSet/{valueset.id}'
    valueset.version = meta.version
    valueset.language = meta.language
    valueset.name = mimic_valueset.title().replace('_', '')
    valueset.title = valueset.name
    valueset.date = meta.current_date
    valueset.publisher = meta.publisher
    valueset.description = meta.vs_descriptions[meta.vs_descriptions['valueset']
                                                == mimic_valueset
                                               ]['description'].iloc[0]

    if mimic_valueset in VALUESETS_CODED:
        logger.info('coded valueset')
        # Generate code/display combos from the fhir_trm tables
        df_valueset = get_table(db_conn, 'fhir_trm', f'vs_{mimic_valueset}')
        include_dict = {}
        # Only coded values right now are d-items valuesets, would need to change system otherwise
        include_dict['system'] = f'{meta.base_url}CodeSystem/d-items'

        # Create valueset codes
        concept = generate_concept(df_valueset)
        include_dict['concept'] = concept
        valueset.compose = {'include': [include_dict]}
    elif mimic_valueset in VALUESETS_DOUBLE_SYSTEM:
        # For valuesets who inherit from more than one CodeSystem
        # Store both systems in the ValueSet include
        logger.info('double system valueset')

        # Grab systems from fhir_trm table
        df_valueset = get_table(db_conn, 'fhir_trm', f'vs_{mimic_valueset}')

        include_list = []
        for sys in df_valueset.system:
            include_list.append({'system': sys})
            valueset.compose = {'include': include_list}
    else:
        sys = {'system': f'{meta.base_url}/CodeSystem/{valueset.id}'}
        valueset.compose = {'include': [sys]}

    return valueset


# Populate the terminology concept list with code/display values from data tables
def generate_concept(df):
    concept = []
    for _, row in df.iterrows():
        element = {}
        element['code'] = row['code']
        if 'display' in row and row['display'] != '' and not pd.isna(
            row['display']
        ):
            element['display'] = row['display']
        concept.append(element)
    return concept


# Write out terminology to a json file in the terminology_path
def write_terminology(terminology, terminology_path):
    logger.info(f'Writing out {terminology.resource_type}: {terminology.id}')
    output_filename = f'{terminology_path}{terminology.resource_type}-{terminology.id}.json'
    with open(output_filename, 'w') as outfile:
        # fhir.resources uses orjson package so not compatible for json.dump alone
        json.dump(json.loads(terminology.json()), outfile, indent=4)
