DROP TABLE IF EXISTS mimic_fhir.patient;
CREATE TABLE mimic_fhir.patient (
  id STRING(36),
  fhir STRING
);

-- DATA TABLES
DROP TABLE IF EXISTS mimic_fhir.location;
CREATE TABLE mimic_fhir.location (
  id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.medication;
CREATE TABLE mimic_fhir.medication (
  id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.medication_mix;
CREATE TABLE mimic_fhir.medication_mix (
  id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.organization;
CREATE TABLE mimic_fhir.organization (
  id STRING(36),
  fhir STRING
);


-- PATIENT TABLES

DROP TABLE IF EXISTS mimic_fhir.condition;
CREATE TABLE mimic_fhir.condition (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.condition_ed;
CREATE TABLE mimic_fhir.condition_ed (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.encounter;
CREATE TABLE mimic_fhir.encounter (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.encounter_ed;
CREATE TABLE mimic_fhir.encounter_ed (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.encounter_icu;
CREATE TABLE mimic_fhir.encounter_icu (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);


DROP TABLE IF EXISTS mimic_fhir.medication_administration;
CREATE TABLE mimic_fhir.medication_administration (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.medication_administration_icu;
CREATE TABLE mimic_fhir.medication_administration_icu (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.medication_dispense;
CREATE TABLE mimic_fhir.medication_dispense (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.medication_dispense_ed;
CREATE TABLE mimic_fhir.medication_dispense_ed (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);




DROP TABLE IF EXISTS mimic_fhir.medication_request;
CREATE TABLE mimic_fhir.medication_request (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.medication_statement_ed;
CREATE TABLE mimic_fhir.medication_statement_ed (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.observation_chartevents;
CREATE TABLE mimic_fhir.observation_chartevents (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.observation_datetimeevents;
CREATE TABLE mimic_fhir.observation_datetimeevents (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.observation_ed;
CREATE TABLE mimic_fhir.observation_ed (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.observation_labevents;
CREATE TABLE mimic_fhir.observation_labevents (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.observation_micro_org;
CREATE TABLE mimic_fhir.observation_micro_org (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.observation_micro_test;
CREATE TABLE mimic_fhir.observation_micro_test (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.observation_micro_susc;
CREATE TABLE mimic_fhir.observation_micro_susc (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.observation_outputevents;
CREATE TABLE mimic_fhir.observation_outputevents (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.observation_vital_signs;
CREATE TABLE mimic_fhir.observation_vital_signs (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);



DROP TABLE IF EXISTS mimic_fhir.procedure;
CREATE TABLE mimic_fhir.procedure (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.procedure_ed;
CREATE TABLE mimic_fhir.procedure_ed (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.procedure_icu;
CREATE TABLE mimic_fhir.procedure_icu (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.specimen;
CREATE TABLE mimic_fhir.specimen (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);

DROP TABLE IF EXISTS mimic_fhir.specimen_lab;
CREATE TABLE mimic_fhir.specimen_lab (
  id STRING(36),
  patient_id STRING(36),
  fhir STRING
);
