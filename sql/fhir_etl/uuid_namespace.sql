DROP TABLE IF EXISTS fhir_etl.uuid_namespace;
CREATE TABLE fhir_etl.uuid_namespace(
  	name VARCHAR NOT NULL UNIQUE,
    uuid uuid PRIMARY KEY
);

INSERT INTO fhir_etl.uuid_namespace(name, uuid)
VALUES	
	('Condition', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Condition'))
	, ('Encounter', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Encounter'))	
	, ('EncounterICU', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'EncounterICU'))
	, ('Medication', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Medication'))
	, ('MedicationAdministration', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'MedicationAdministration'))
	, ('MedicationAdministrationICU', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'MedicationAdministrationICU'))
	, ('MedicationRequest', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'MedicationRequest'))
	, ('ObservationMicroOrg', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'ObservationMicroOrg'))
    , ('ObservationMicroSusc', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'ObservationMicroSusc'))
    , ('ObservationMicroTest', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'ObservationMicroTest'))
	, ('ObservationChartevents', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'ObservationChartevents'))
	, ('ObservationDatetimeevents', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'ObservationDatetimeevents'))
	, ('ObservationLabs', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'ObservationLabs'))
	, ('ObservationOutputevents', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'ObservationOutputevents'))
	, ('Organization', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Organization'))
	, ('Patient', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient'))
	, ('Procedure', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Procedure'))
	, ('ProcedureICU', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'ProcedureICU'))
	, ('SpecimenLab', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'SpecimenLab')) 
	, ('SpecimenMicro', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'SpecimenMicro'))   
