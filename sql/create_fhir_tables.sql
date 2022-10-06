SET client_min_messages TO WARNING; -- ignore notices, lots of small ones for drop tables
DROP SCHEMA IF EXISTS mimic_fhir CASCADE;
DROP SCHEMA IF EXISTS fhir_etl CASCADE;

CREATE SCHEMA IF NOT EXISTS mimic_fhir;
CREATE SCHEMA IF NOT EXISTS fhir_etl;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- prepare tables necessary for ETL
\echo =========================== fhir_etl tables ====================================
\echo subjects
\i fhir_etl/subjects.sql

\echo uuid_namespace
\i fhir_etl/uuid_namespace.sql

\echo fhir_etl.map_gender
\i fhir_etl/map_gender.sql

\echo fhir_etl.map_marital_status
\i fhir_etl/map_marital_status.sql

\echo fhir_etl.map_medreq_status
\i fhir_etl/map_medreq_status.sql

\echo fhir_etl.map_med_duration_unit
\i fhir_etl/map_med_duration_unit.sql

\echo fhir_etl.map_status_procedure_icu
\i fhir_etl/map_status_procedure_icu.sql

\echo map ethnicity
\i fhir_etl/map_ethnicity.sql

\echo map race
\i fhir_etl/map_race_omb.sql

\echo map encounter class
\i fhir_etl/map_encounter_class.sql

\echo map encounter priority
\i fhir_etl/map_encounter_priority.sql

\echo map microbiology interpretation
\i fhir_etl/map_micro_interpretation.sql

\echo map lab interpretation
\i fhir_etl/map_lab_interpretation.sql

\echo =========================== fhir_etl functions ====================================
\echo fn_patient_extension
\i fn/fn_patient_extension.sql
-- prepare MIMIC-IV tables

\echo fn_med_statement
\i fn/fn_med_statement.sql


\echo fn_create_table_patient_dependent
\i fn/fn_create_table_patient_dependent.sql

-- institutional resources
\echo =========================== mimic_fhir tables ====================================
\echo fhir_organization
\i fhir_organization.sql

\echo fhir_location
\i fhir_location.sql

-- patient tracking resources
\echo fhir_patient
\i fhir_patient.sql

\echo fhir_encounter
\i fhir_encounter.sql

\echo fhir_encounter_icu
\i fhir_encounter_icu.sql

-- data resources: conditions, diagnoses, procedures, specimen
\echo condition
\i fhir_condition.sql

\echo fhir_procedure
\i fhir_procedure.sql

\echo fhir_procedure_icu
\i fhir_procedure_icu.sql

\echo fhir_specimen
\i fhir_specimen.sql

\echo fhir_specimen_lab
\i fhir_specimen_lab.sql

-- data resources: medications
\echo create fhir medication
\i create_fhir_medication.sql

\echo fhir_medication_administration_icu
\i fhir_medication_administration_icu.sql

\echo fhir_medication_administration
\i fhir_medication_administration.sql

\echo fhir_medication_dispense
\i fhir_medication_dispense.sql

\echo fhir_medication_request
\i fhir_medication_request.sql

-- data resources: observations
\echo fhir_observation_chartevents
\i fhir_observation_chartevents.sql

\echo fhir_observation_datetimeevents
\i fhir_observation_datetimeevents.sql

\echo fhir_observation_labevents
\i fhir_observation_labevents.sql
\echo Chartevents D Items

--microbiology
\echo fhir_observation_micro_test
\i fhir_observation_micro_test.sql

\echo fhir_observation_micro_org
\i fhir_observation_micro_org.sql


\echo fhir_observation_micro_susc
\i fhir_observation_micro_susc.sql


\echo fhir_observation_outputevents
\i fhir_observation_outputevents.sql

-- mimic-ed tables
\echo fhir_condition_ed
\i fhir_condition_ed.sql

\echo fhir_encounter_ed
\i fhir_encounter_ed.sql

\echo fhir_medication_dispense_ed
\i fhir_medication_dispense_ed.sql

\echo fhir_medication_statement_ed
\i fhir_medication_statement_ed.sql

\echo fhir_observation_ed
\i fhir_observation_ed.sql

\echo fhir_observation_vitalsigns
\i fhir_observation_vitalsigns.sql

\echo fhir_procedure_ed
\i fhir_procedure_ed.sql

-- cluster mimic_fhir tables
\echo cluster mimic_fhir tables
\i create_table_clusters.sql

-- fhir terminology tables
\echo create_fhir_terminology
\i create_fhir_terminology.sql
