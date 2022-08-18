# Constant lookups that are used throughout the package

MIMIC_FHIR_PROFILE_URL = {
    'Condition':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-condition',
    'Encounter':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-encounter',
    'EncounterTransfers':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-encounter-transfers',
    'EncounterICU':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-encounter-icu',
    'Location':
        '',
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
    'MimicCondition': 'Condition',
    'MimicEncounter': 'Encounter',
    'MimicEncounterICU': 'Encounter',
    'Location': 'Location',
    'MimicMedication': 'Medication',
    'MimicMedicationAdministration': 'MedicationAdministration',
    'MimicMedicationAdministrationICU': 'MedicationAdministration',
    'MimicMedicationDispense': 'MedicationDispense',
    'MimicMedicationRequest': 'MedicationRequest',
    'MimicObservationChartevents': 'Observation',
    'MimicObservationDatetimeevents': 'Observation',
    'MimicObservationLabevents': 'Observation',
    'MimicObservationMicroTest': 'Observation',
    'MimicObservationMicroOrg': 'Observation',
    'MimicObservationMicroSusc': 'Observation',
    'MimicObservationOutputevents': 'Observation',
    'MimicOrganization': 'Organization',
    'MimicPatient': 'Patient',
    'MimicProcedure': 'Procedure',
    'MimicProcedureICU': 'Procedure',
    'MimicSpecimen': 'Specimen'
}

MIMIC_FHIR_PROFILE_NAMES = [
    'MimicCondition', 'MimicEncounter', 'MimicEncounterICU', 'MimicLocation',
    'MimicMedication', 'MimicMedicationAdministration',
    'MimicMedicationAdministrationICU', 'MimicMedicationDispense',
    'MimicMedicationRequest', 'MimicObservationChartevents',
    'MimicObservationDatetimeevents', 'MimicObservationLabevents',
    'MimicObservationMicroTest', 'MimicObservationMicroOrg',
    'MimicObservationMicroSusc', 'MimicObservationOutputevents',
    'MimicOrganization', 'MimicPatient', 'MimicProcedure', 'MimicProcedureICU',
    'MimicSpecimen'
]

MIMIC_CODESYSTEMS = [
    'admit_source', 'bodysite', 'chartevents_d_items', 'd_items', 'd_labitems',
    'diagnosis_icd9', 'diagnosis_icd10', 'discharge_disposition', 'hcpcs_cd',
    'lab_fluid', 'lab_priority', 'medadmin_category_icu', 'medication_etc',
    'medication_icu', 'medication_formulary_drug_cd', 'medication_frequency',
    'medication_gsn', 'medication_method', 'medication_method_icu',
    'medication_name', 'medication_ndc', 'medication_poe_iv',
    'medication_route', 'medication_site', 'microbiology_antibiotic',
    'microbiology_organism', 'microbiology_test', 'observation_category',
    'procedure_category', 'procedure_icd9', 'procedure_icd10', 'services',
    'spec_type_desc', 'units'
]

MIMIC_VALUESETS = [
    'admit_source', 'bodysite', 'chartevents_d_items', 'd_labitems',
    'datetimeevents_d_items', 'diagnosis_icd', 'discharge_disposition',
    'encounter_type', 'lab_priority', 'medadmin_category_icu', 'medication',
    'medication_etc', 'medication_frequency', 'medication_gsn',
    'medication_method', 'medication_method_icu', 'medication_route',
    'medication_site', 'microbiology_antibiotic', 'microbiology_organism',
    'microbiology_test', 'observation_category', 'outputevents_d_items',
    'procedure_category', 'procedureevents_d_items', 'procedure_icd',
    'services', 'specimen_type', 'units'
]

VALUESETS_COMPLEX = [
    'datetimeevents_d_items', 'diagnosis_icd', 'encounter_type', 'medication',
    'outputevents_d_items', 'procedureevents_d_items', 'procedure_icd',
    'specimen_type'
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
        ],
    'ed_base': ['encounter_ed', 'procedure_ed'],
    'ed_observation': ['observation_ed', 'observation_vitalsigns'],
    'ed_medication': ['medication_statement_ed', 'medication_dispense_ed']
}

MIMIC_DATA_BUNDLE_LIST = [
    'organization', 'location', 'medication', 'medication_mix'
]
