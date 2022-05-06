# Constant lookups that are used throughout the package

MIMIC_FHIR_PROFILE_URL = {
    'Condition':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-condition',
    'Encounter':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-encounter',
    'EncounterICU':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-encounter-icu',
    'Medication':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication',
    'MedicationAdministration':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication-administration',
    'MedicationAdministrationICU':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication-administration-icu',
    'MedicationDispense':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication-dispense',
    'MedicationRequest':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication-request',
    'ObservationChartevents':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-chartevents',
    'ObservationDatetimeevents':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-datetimeevents',
    'ObservationLabevents':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-labevents',
    'ObservationMicroTest':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-micro-test',
    'ObservationMicroOrg':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-micro-org',
    'ObservationMicroSusc':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-micro-susc',
    'ObservationOutputevents':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-outputevents',
    'Organization':
        '',
    'Patient':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-patient',
    'Procedure':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-procedure',
    'ProcedureICU':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-procedure-icu',
    'Specimen':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-specimen',
    'SpecimenLab':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-specimen'
}

MIMIC_FHIR_RESOURCES = {
    'Condition': 'Condition',
    'Encounter': 'Encounter',
    'EncounterICU': 'Encounter',
    'Medication': 'Medication',
    'MedicationAdministration': 'MedicationAdministration',
    'MedicationAdministrationICU': 'MedicationAdministration',
    'MedicationDispense': 'MedicationDispense',
    'MedicationRequest': 'MedicationRequest',
    'ObservationChartevents': 'Observation',
    'ObservationDatetimeevents': 'Observation',
    'ObservationLabevents': 'Observation',
    'ObservationMicroTest': 'Observation',
    'ObservationMicroOrg': 'Observation',
    'ObservationMicroSusc': 'Observation',
    'ObservationOutputevents': 'Observation',
    'Organization': 'Organization',
    'Patient': 'Patient',
    'Procedure': 'Procedure',
    'ProcedureICU': 'Procedure',
    'Specimen': 'Specimen',
    'SpecimenLab': 'Specimen'
}

MIMIC_FHIR_PROFILE_NAMES = [
    'Condition', 'Encounter', 'EncounterICU', 'Medication',
    'MedicationAdministration', 'MedicationAdministrationICU',
    'MedicationDispense', 'MedicationRequest', 'ObservationChartevents',
    'ObservationDatetimeevents', 'ObservationLabevents', 'ObservationMicroTest',
    'ObservationMicroOrg', 'ObservationMicroSusc', 'ObservationOutputevents',
    'Organization', 'Patient', 'Procedure', 'ProcedureICU', 'Specimen',
    'SpecimenLab'
]

MIMIC_CODESYSTEMS = [
    'admission_class', 'admission_type', 'admission_type_icu', 'admit_source',
    'bodysite', 'careunit', 'chartevents_d_items', 'd_items', 'd_labitems',
    'diagnosis_icd9', 'diagnosis_icd10', 'discharge_disposition',
    'identifier_type', 'lab_flags', 'lab_fluid', 'lab_priority',
    'medadmin_category_icu', 'medication_icu', 'medication_formulary_drug_cd',
    'medication_frequency', 'medication_method', 'medication_method_icu',
    'medication_name', 'medication_ndc', 'medication_poe_iv',
    'medication_route', 'medication_site', 'microbiology_antibiotic',
    'microbiology_interpretation', 'microbiology_organism', 'microbiology_test',
    'observation_category', 'procedure_category', 'procedure_icd9',
    'procedure_icd10', 'spec_type_desc', 'transfer_type', 'units'
]

MIMIC_VALUESETS = [
    'admission_class', 'admission_type', 'admission_type_icu', 'admit_source',
    'bodysite', 'careunit', 'chartevents_d_items', 'd_labitems',
    'datetimeevents_d_items', 'diagnosis_icd', 'discharge_disposition',
    'identifier_type', 'lab_flags', 'lab_priority', 'medadmin_category_icu',
    'medication', 'medication_frequency', 'medication_method',
    'medication_method_icu', 'medication_route', 'medication_site',
    'microbiology_antibiotic', 'microbiology_interpretation',
    'microbiology_organism', 'microbiology_test', 'observation_category',
    'outputevents_d_items', 'procedure_category', 'procedureevents_d_items',
    'procedure_icd', 'specimen_type', 'transfer_type', 'units'
]

VALUESETS_CODED = [
    'datetimeevents_d_items', 'outputevents_d_items', 'procedureevents_d_items'
]
VALUESETS_DOUBLE_SYSTEM = [
    'procedure_icd', 'diagnosis_icd', 'medication', 'specimen_type'
]

# ValueSets that are full encapulsation of the CodeSystem
VALUESETS_CANONICAL = [
    'admission_class', 'admission_type', 'admission_type_icu', 'admit_source',
    'bodysite', 'd_labitems', 'discharge_disposition', 'identifier_type',
    'lab_flags', 'lab_priority', 'medadmin_category_icu', 'medication_method',
    'medication_method_icu', 'medication_route', 'medication_site',
    'microbiology_antibiotic', 'microbiology_interpretation',
    'microbiology_organism', 'microbiology_test', 'observation_category',
    'procedure_category', 'units'
]

# ORDER MATTERS!!
# The patient bundle must be first and the icu_encounter bundle must be before all other icu bundles
MIMIC_BUNDLE_TABLE_LIST = {
    'patient': ['patient', 'encounter'],
    'procedure': ['procedure'],
    'condition': ['condition'],
    'specimen': ['specimen', 'specimen_lab'],
    'lab': ['observation_labevents'],
    'microbiology':
        [
            'observation_micro_test', 'observation_micro_org',
            'observation_micro_susc'
        ],
    'medication_preparation': ['medication_request', 'medication_dispense'],
    'medication_administration': ['medication_administration'],
    'icu_encounter': ['encounter_icu'],
    'icu_medication': ['medication_administration_icu'],
    'icu_procedure': ['procedure_icu'],
    'icu_observation':
        [
            'observation_chartevents', 'observation_datetimeevents',
            'observation_outputevents'
        ]
}
