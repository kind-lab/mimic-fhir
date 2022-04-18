CREATE SCHEMA IF NOT EXISTS mimic_fhir;
CREATE SCHEMA IF NOT EXISTS fhir_etl;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- prepare tables necessary for ETL
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

\echo fhir_etl.map_status_procedure_icu
\i fhir_etl/map_status_procedure_icu.sql

-- prepare MIMIC-IV tables

-- institutional resources
\echo fhir_organization
\i fhir_organization.sql

-- patient tracking resources
\echo fn_patient_extension
\i fn/fn_patient_extension.sql

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

-- data resources: medications
\echo fhir_medadmin_icu
\i fhir_medadmin_icu.sql

\echo fhir_medication
\i fhir_medication.sql

\echo fhir_medication_administration
\i fhir_medication_administration.sql

\echo fhir_medication_mix
\i fhir_medication_mix.sql

\echo fhir_medication_request
\i fhir_medication_request.sql

-- data resources: observations
\echo fhir_observation_chartevents
\i fhir_observation_chartevents.sql

\echo fhir_observation_datetimeevents
\i fhir_observation_datetimeevents.sql

\echo fhir_observation_labevents
\i fhir_observation_labevents.sql

\echo fhir_observation_micro_org
\i fhir_observation_micro_org.sql

\echo fhir_observation_micro_susc
\i fhir_observation_micro_susc.sql

\echo fhir_observation_micro_test
\i fhir_observation_micro_test.sql

\echo fhir_observation_outputevents
\i fhir_observation_outputevents.sql

-- fhir terminology tables
\echo create_fhir_terminology
\i fhir_terminology.sql
