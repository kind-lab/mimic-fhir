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
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-chartevent',
    'ObservationDatetimeevents':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-datetime',
    'ObservationLabs':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-lab',
    'ObservationMicroTest':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-micro-test',
    'ObservationMicroOrg':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-micro-org',
    'ObservationMicroSusc':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-micro-susc',
    'ObservationOutputevents':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-outputevent',
    'Organization':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-organization',
    'Patient':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-patient',
    'Procedure':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-procedure',
    'ProcedureICU':
        'http://fhir.mimic.mit.edu/StructureDefinition/mimic-procedure-icu',
    'Specimen':
        ''
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
    'ObservationLabs': 'Observation',
    'ObservationMicroTest': 'Observation',
    'ObservationMicroOrg': 'Observation',
    'ObservationMicroSusc': 'Observation',
    'ObservationOutputevents': 'Observation',
    'Organization': 'Organization',
    'Patient': 'Patient',
    'Procedure': 'Procedure',
    'ProcedureICU': 'Procedure',
    'Specimen': 'Specimen'
}

MIMIC_FHIR_PROFILE_NAMES = [
    'Condition', 'Encounter', 'EncounterICU', 'Medication',
    'MedicationAdministration', 'MedicationAdministrationICU',
    'MedicationDispense', 'MedicationRequest', 'ObservationChartevents',
    'ObservationDatetimeevents', 'ObservationLabs', 'ObservationMicroTest',
    'ObservationMicroOrg', 'ObservationMicroSusc', 'ObservationOutputevents',
    'Organization', 'Patient', 'Procedure', 'ProcedureICU', 'Specimen'
]
