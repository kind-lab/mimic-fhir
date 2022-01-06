\c mimic
CREATE SCHEMA IF NOT EXISTS mimic_fhir;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

\! echo subjects
\i fhir_etl/subjects

\! echo condition
\i fhir_condition.sql

\! echo fhir_encounter
\i fhir_encounter.sql

\! echo fhir_encounter_icu
\i fhir_encounter_icu.sql

\! echo map_drug_id
\i map_drug_id.sql

--\! echo fhir_medadmin_icu
--\i fhir_medadmin_icu.sql

\! echo fhir_medication
\i fhir_medication.sql

\! echo fhir_medication_administration
\i fhir_medication_administration.sql

\! echo fhir_medication_mix
\i fhir_medication_mix.sql

\! echo fhir_medication_request
\i fhir_medication_request.sql

--\! echo fhir_observation_chartevents
--\i fhir_observation_chartevents.sql

\! echo fhir_observation_datetimeevents
\i fhir_observation_datetimeevents.sql

\! echo fhir_observation_labs
\i fhir_observation_labs.sql

\! echo fhir_observation_micro_org
\i fhir_observation_micro_org.sql

\! echo fhir_observation_micro_susc
\i fhir_observation_micro_susc.sql

\! echo fhir_observation_micro_test
\i fhir_observation_micro_test.sql

\! echo fhir_observation_outputevents
\i fhir_observation_outputevents.sql

\! echo fhir_organization
\i fhir_organization.sql

\! echo fn_patient_extension
\i fn/fn_patient_extension.sql

\! echo fhir_patient
\i fhir_patient.sql

\! echo fhir_procedure
\i fhir_procedure.sql

\! echo fhir_procedure_icu
\i fhir_procedure_icu.sql
