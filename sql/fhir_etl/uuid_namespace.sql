DROP TABLE IF EXISTS fhir_etl.uuid_namespace;

SELECT 
	uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Condition') as uuid_condition	
	, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Encounter') as uuid_encounter	
	, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'EncounterICU') as uuid_encounter_icu
	, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Medication') as uuid_medication
	, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'MedicationAdministration') as uuid_medication_administration
	, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'MedicationAdministrationICU') as uuid_medication_administration_icu
	, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'MedicationRequest') as uuid_medication_request
	, uuid_generate_v5(uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Observation'), 'micro-org') as uuid_observation_micro_org
    , uuid_generate_v5(uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Observation'), 'micro-susc') as uuid_observation_micro_susc
    , uuid_generate_v5(uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Observation'), 'micro-test') as uuid_observation_micro_test
	, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'ObservationChartevents') as uuid_observation_ce
	, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'ObservationDatetimeevents') as uuid_observation_de
	, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Observation-Labs') as uuid_observation_lab
	, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'ObservationOutputevents') as uuid_observation_oe
	, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Organization') as uuid_organization
	, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient') as uuid_patient
	, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Procedure') as uuid_procedure
	, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'ProcedureICU') as uuid_procedure_icu
	, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Specimen') as uuid_specimen    
INTO fhir_etl.uuid_namespace;