# Constant lookups that are used throughout the package
MIMIC_FHIR_PROFILES = {
    'MimicCondition':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-condition',
            'resource':
                'Condition'
        },
    'MimicEncounter':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-encounter',
            'resource':
                'Encounter'
        },
    'MimicLocation':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-location',
            'resource':
                'Location'
        },
    'MimicMedication':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-medication',
            'resource':
                'Medication'
        },
    'MimicMedicationAdministration':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-medication-administration',
            'resource':
                'MedicationAdministration'
        },
    'MimicMedicationAdministrationICU':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-medication-administration-icu',
            'resource':
                'MedicationAdministration'
        },
    'MimicMedicationDispense':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-medication-dispense',
            'resource':
                'MedicationDispense'
        },
    'MimicMedicationDispenseED':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-medication-dispense-ed',
            'resource':
                'MedicationDispense'
        },
    'MimicMedicationRequest':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-medication-request',
            'resource':
                'MedicationRequest'
        },
    'MimicMedicationStatementED':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-medication-statement-ed',
            'resource':
                'MedicationStatement'
        },
    'MimicObservationChartevents':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-observation-chartevents',
            'resource':
                'Observation'
        },
    'MimicObservationDatetimeevents':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-observation-datetimeevents',
            'resource':
                'Observation'
        },
    'MimicObservationED':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-observation-ed',
            'resource':
                'Observation'
        },
    'MimicObservationLabevents':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-observation-labevents',
            'resource':
                'Observation'
        },
    'MimicObservationMicroTest':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-observation-micro-test',
            'resource':
                'Observation'
        },
    'MimicObservationMicroOrg':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-observation-micro-org',
            'resource':
                'Observation'
        },
    'MimicObservationMicroSusc':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-observation-micro-susc',
            'resource':
                'Observation'
        },
    'MimicObservationOutputevents':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-observation-outputevents',
            'resource':
                'Observation'
        },
    'MimicObservationVitalSigns':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-observation-vital-signs',
            'resource':
                'Observation'
        },
    'MimicOrganization':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-organization',
            'resource':
                'Organization'
        },
    'MimicPatient':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-patient',
            'resource':
                'Patient'
        },
    'MimicProcedure':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-procedure',
            'resource':
                'Procedure'
        },
    'MimicProcedureED':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-procedure-ed',
            'resource':
                'Procedure'
        },
    'MimicProcedureICU':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-procedure-icu',
            'resource':
                'Procedure'
        },
    'MimicSpecimen':
        {
            'url':
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-specimen',
            'resource':
                'Specimen'
        }
}

MIMIC_CODESYSTEMS = [
    'admission_class', 'admission_type', 'admit_source', 'bodysite',
    'chartevents_d_items', 'd_items', 'd_labitems', 'diagnosis_icd9',
    'diagnosis_icd10', 'discharge_disposition', 'hcpcs_cd', 'lab_fluid',
    'lab_priority', 'medadmin_category_icu', 'medication_etc', 'medication_icu',
    'medication_formulary_drug_cd', 'medication_frequency', 'medication_gsn',
    'medication_method', 'medication_method_icu', 'medication_name',
    'medication_ndc', 'medication_poe_iv', 'medication_route',
    'medication_site', 'microbiology_antibiotic', 'microbiology_organism',
    'microbiology_test', 'observation_category', 'procedure_category',
    'procedure_icd9', 'procedure_icd10', 'services', 'spec_type_desc', 'units'
]

MIMIC_VALUESETS = [
    'admission_class', 'admission_type', 'admit_source', 'bodysite',
    'chartevents_d_items', 'd_labitems', 'datetimeevents_d_items',
    'diagnosis_icd', 'discharge_disposition', 'encounter_type', 'lab_priority',
    'medadmin_category_icu', 'medication', 'medication_etc',
    'medication_frequency', 'medication_gsn', 'medication_method',
    'medication_method_icu', 'medication_route', 'medication_site',
    'microbiology_antibiotic', 'microbiology_organism', 'microbiology_test',
    'observation_category', 'outputevents_d_items', 'procedure_category',
    'procedureevents_d_items', 'procedure_icd', 'services', 'specimen_type',
    'units'
]

VALUESETS_COMPLEX = [
    'admission_class', 'admission_type', 'datetimeevents_d_items',
    'diagnosis_icd', 'encounter_type', 'medication', 'outputevents_d_items',
    'procedureevents_d_items', 'procedure_icd', 'specimen_type'
]
# ORDER MATTERS!!
# The patient bundle must be first and the icu_encounter bundle must be before all other icu bundles
# Medication request, dispense and administration have been spaced out so one is processed before the next
# Medication bundle with all them became too big
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
    'medication-request': ['medication_request'],
    'icu-encounter': ['encounter_icu'],
    'icu-medication': ['medication_administration_icu'],
    'medication-dispense': ['medication_dispense'],
    'icu-procedure': ['procedure_icu'],
    'icu-observation':
        [
            'observation_chartevents', 'observation_datetimeevents',
            'observation_outputevents'
        ],
    'medication-administration': ['medication_administration'],
    'ed-base': ['encounter_ed', 'procedure_ed'],
    'ed-observation': ['observation_ed', 'observation_vital_signs'],
    'ed-medication': ['medication_statement_ed', 'medication_dispense_ed']
}

# MIMIC_PATIENT_TABLE_LIST = ['encounter', 'condition']
# Note that this excludes patient, since it is used in a loop with patient_ids
MIMIC_PATIENT_TABLE_LIST = [
    'condition', 'condition_ed', 'encounter', 'encounter_ed', 'encounter_icu',
    'medication_administration', 'medication_administration_icu',
    'medication_dispense', 'medication_dispense_ed', 'medication_request',
    'medication_statement_ed', 'observation_chartevents',
    'observation_datetimeevents', 'observation_ed', 'observation_labevents',
    'observation_micro_org', 'observation_micro_susc', 'observation_micro_test',
    'observation_vital_signs', 'observation_outputevents', 'procedure',
    'procedure_ed', 'procedure_icu', 'specimen', 'specimen_lab'
]

MIMIC_DATA_TABLE_LIST = [
    'organization', 'location', 'medication', 'medication_mix'
]

MIMIC_DATA_BUNDLE_LIST = [
    'organization', 'location', 'medication', 'medication_mix'
]

MIMIC_BUNDLES_NO_SPLIT_LIST = ['microbiology', 'medication-workflow']
