from fhir.resources.codesystem import CodeSystem, CodeSystemConcept
from fhir.resources.valueset import ValueSet

from py_mimic_fhir import db
from py_mimic_fhir.lookup import (
    MIMIC_CODESYSTEMS, MIMIC_VALUESETS, VALUESETS_CODED, VALUESETS_DOUBLE_SYSTEM
)

logger = logging.getLogger(__name__)


class TerminologyMetaData():
    def __init__(self, db_conn):
        self.status = 'active'
        self.content = 'complete'
        self.version = '0.4'
        self.publisher = 'KinD Lab'
        self.language = 'en'
        self.current_date = str(
            datetime.now().strftime('%Y-%m-%dT%H:%M:%S-04:00')
        )
        self.base_url = 'http://fhir.mimic.mit.edu'
        self.cs_descriptions = set_cs_descriptions(db_conn)
        self.vs_descriptions = set_vs_descriptions(db_conn)

    def set_cs_descriptions(self, db_conn):
        q_cs_descriptions = f"SELECT * FROM fhir_trm.cs_descriptions;"
        self.cs_descriptions = pd.read_sql_query(q_cs_descriptions, db_conn)

    def set_vs_descriptions(self, db_conn):
        q_vs_descriptions = f"SELECT * FROM fhir_trm.vs_descriptions;"
        self.vs_descriptions = pd.read_sql_query(q_vs_descriptions, db_conn)


def generate_all_terminology(args):
    db_conn = db.db_conn(
        args.sqluser, args.sqlpass, args.dbname_mimic, args.host
    )
    meta = TerminologyMetaData(db_conn)
    generate_codesystems(db_conn, meta, args)
    generate_valuesets(db_conn, meta, args)


def generate_codesystems(db_conn, meta, args):
    for mimic_codesystem in MIMIC_CODESYSTEMS:
        codesystem = generate_codesystem(mimic_codesystem, db_conn, meta)
        write_terminology(codesystem, args.terminology_path)


def write_terminology(terminology, terminology_path):
    # Write out CodeSystem json to terminology folder
    output_filename = f'{terminology_path}{terminology.resourceType}-{terminology.id}.json'
    with open(output_filename, 'w') as outfile:
        json.dump(json.loads(terminology.json()), outfile, indent=4)


def generate_valuesets(args):
    for mimic_valueset in MIMIC_VALUESETS:
        valueset = generate_codesystem(mimic_valueset, db_conn, meta)
        write_terminology(valueset, args.terminology_path)


def generate_codesystem(mimic_codsystem, db_conn, meta):
    codesystem = CodeSystem(status=meta.status, content=meta.content)
    codesystem.id = codesystem.replace('_', '-')
    codesystem.url = f'{meta.base_url}/CodeSystem/{codesystem.id}'
    codesystem.version = meta.version
    codesystem.language = meta.language
    codesystem.name = codesystem.title().replace('_', '')
    codesystem.title = codesystem.name
    codesystem.date = meta.current_date
    codesystem.publisher = meta.publisher
    codesystem.description = meta.cs_descriptions[
        meta.cs_descriptions['codesystem'] == mimic_codsystem
    ]['description'].iloc[0]

    # Generate code/display combos from the fhir_trm tables
    df_codesystem = db.get_table(db_conn, 'fhir_trm', f'cs_{mimic_codesystem}')
    concept = []
    for _, row in df_codesystem.iterrows():
        elem = {}
        elem['code'] = row['code']
        if 'display' in row:
            elem['display'] = row['display']
        concept.append(elem)

    codesystem.concept = concept

    return codesystem


def generate_valueset(mimic_valueset, db_conn, meta):
    vs = ValueSet(status=meta.status)
    vs.id = valueset.replace('_', '-')
    vs.url = f'{meta.base_url}/ValueSet/{vs.id}'
    vs.version = meta.version
    vs.language = meta.language
    vs.name = valueset.title().replace('_', '')
    vs.title = vs.name
    vs.date = meta.current_date
    vs.publisher = meta.publisher
    vs.description = meta.vs_descriptions[meta.vs_descriptions['valueset'] ==
                                          mimic_valueset]['description'].iloc[0]

    if mimic_valueset in VALUESETS_CODED:
        logger.info('coded valueset')
        # Generate code/display combos from the fhir_trm tables
        df_valueset = db.get_table(db_conn, 'fhir_trm', f'vs_{mimic_valueset}')
        include_dict = {}
        # Only coded values right now are d-items valuesets, would need to change system otherwise
        include_dict['system'] = f'{base_url}CodeSystem/d-items'

        # Create valueset codes
        concept = []
        for index, row in df_valueset.iterrows():
            elem = {}
            elem['code'] = row['code']
            if row['display'] != '' and not pd.isna(row['display']):
                elem['display'] = row['display']
            concept.append(elem)

            include_dict['concept'] = concept
            vs.compose = {'include': [include_dict]}
    elif valueset in VALUESETS_DOUBLE_SYSTEM:
        # For valuesets who inherit from more than one CodeSystem
        # Store both systems in the ValueSet include
        logger.info('double system valueset')

        # Grab systems from fhir_trm table
        df_valueset = db.get_table(db_conn, 'fhir_trm', f'vs_{mimic_valueset}')

        include_list = []
        for sys in df_valueset.system:
            include_list.append({'system': sys})
            vs.compose = {'include': include_list}
    else:
        sys = {'system': f'{meta.base_url}/CodeSystem/{vs.id}'}
        vs.compose = {'include': [sys]}

    return valueset