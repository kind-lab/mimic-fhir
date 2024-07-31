#!/usr/bin/env python3
import json
import os
from datetime import datetime

import click
import pandas as pd
import psycopg2
from fhir.resources.codesystem import CodeSystem
from fhir.resources.valueset import ValueSet
import itertools as it

valueset_coded = ['admission_class', 'admission_type', 'datetimeevents_d_items', 'diagnosis_icd', 'encounter_type',
                  'medication', 'outputevents_d_items', 'procedure_icd', 'procedureevents_d_items', 'specimen_type']


@click.command()
@click.argument('output-dir', type=click.Path())
@click.option('--db-name', help='Database name')
@click.option('--db-user', help='SQL username')
@click.option('--db-pass', help='SQL password')
@click.option('--db-host', help='Host', default='localhost')
@click.option('--date', help='Date to use for the FHIR resource date instead of the current datetime')
def pslq_export_trm(output_dir, db_name, db_user, db_pass, db_host, date) -> None:
    """
    Exports terminology from postresql
    """
    # static components
    fhir_status = 'draft'
    fhir_content = 'complete'
    version = '2.0'
    publisher = 'KinD Lab'
    current_date = str(datetime.now().strftime('%Y-%m-%dT%H:%M:%S-04:00')) if date is None else date
    base_url = 'http://mimic.mit.edu/fhir/mimic'

    os.makedirs(output_dir, exist_ok=True)

    # Connect to database
    con = psycopg2.connect(dbname=db_name, user=db_user, password=db_pass, host=db_host)

    # Pull in all the terminology descriptions
    q_cs_descriptions = "SELECT * FROM fhir_trm.cs_descriptions"
    cs_descriptions = pd.read_sql_query(q_cs_descriptions, con)

    codesystems = list(cs_descriptions.codesystem)
    click.echo(f"Exporting codesystems: {codesystems}")

    for codesystem in codesystems:
        print(codesystem)
        cs = CodeSystem(status=fhir_status, content=fhir_content)
        cs.id = "mimic-" + codesystem.replace('_', '-')
        cs.url = f'{base_url}/CodeSystem/{cs.id}'
        cs.valueSet = f'{base_url}/ValueSet/{cs.id}'
        cs.version = version
        cs.language = 'en'
        cs.name = "Mimic" + codesystem.title().replace('_', '')
        cs.title = cs.name
        cs.date = current_date
        cs.publisher = publisher
        cs.description = cs_descriptions[cs_descriptions['codesystem'] == codesystem]['description'].iloc[0]

        # Generate code/display combos from the fhir_trm tables
        q_codesystem = f"SELECT * FROM fhir_trm.cs_{codesystem};"
        df_codesystem = pd.read_sql_query(q_codesystem, con)
        concept = []
        for _, row in df_codesystem.iterrows():
            elem = {}
            elem['code'] = row['code']
            if 'display' in row:
                elem['display'] = row['display']
            concept.append(elem)

        cs.concept = concept

        print(f"CodeSystem: {codesystem} has {len(cs.concept)} concepts.")
        # Write out CodeSystem json to terminology folder
        with open(os.path.join(output_dir, f'CodeSystem-{cs.id}.json'), 'w') as outfile:
            json.dump(json.loads(cs.json()), outfile, indent=4)

    # Pull in all the valueset descriptions
    q_vs_descriptions = f"SELECT * FROM fhir_trm.vs_descriptions;"
    vs_descriptions = pd.read_sql_query(q_vs_descriptions, con)

    valuesets = list(vs_descriptions.valueset)
    click.echo(f"Exporting valuesets: {valuesets}")

    for valueset in valuesets:
        print(valueset)
        vs = ValueSet(status=fhir_status)
        vs.id = "mimic-" + valueset.replace('_', '-')
        vs.url = f'{base_url}/ValueSet/{vs.id}'
        vs.version = version
        vs.language = 'en'
        vs.name = "Mimic" + valueset.title().replace('_', '')
        vs.title = vs.name
        vs.date = current_date
        vs.publisher = publisher
        vs.description = vs_descriptions[vs_descriptions['valueset'] == valueset]['description'].iloc[0]

        if valueset in valueset_coded:
            print('coded valueset')
            # Generate code/display combos from the fhir_trm tables
            q_valueset = f"SELECT * FROM fhir_trm.vs_{valueset};"
            df_valueset = pd.read_sql_query(q_valueset, con)

            concepts_by_system = it.groupby(df_valueset.itertuples(index=False, name=None), key=lambda r:r[0])

            def to_concept(_, code, display = None):
                if not code or code == '*':
                    raise ValueError(f'Invalid concept code: {code}')
                return dict(code=code, display=display) if display else dict(code=code)

            def to_include(system, concepts_it):
                concepts = list(concepts_it)
                if len(concepts) == 1 and concepts[0][1] == '*':
                    return dict(system=system)
                else:
                    return dict(system=system, concept=[to_concept(*c) for c in concepts])

            include_list = [ to_include(system, concepts) for system, concepts in concepts_by_system ]
            vs.compose = {'include': include_list}
        else:
            sys = {'system': f'{base_url}/CodeSystem/{vs.id}'}
            vs.compose = {'include': [sys]}

        # Write out ValueSet json to terminology folder
        with open(os.path.join(output_dir, f'ValueSet-{vs.id}.json'), 'w') as outfile:
            json.dump(json.loads(vs.json()), outfile, indent=4)


if __name__ == '__main__':
    pslq_export_trm()
