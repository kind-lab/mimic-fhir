\set outputdir '/tmp/mimic_output'
\! mkdir -p '/tmp/mimic_output'
\t
-- removes single space in front of output
\pset format unaligned 

-----------output mimic-fhir tables to ndjson-------------

-- institutional resources
\echo organization
\o :outputdir/MimicOrganization.ndjson
SELECT fhir FROM mimic_fhir.organization;

\echo location
\o :outputdir/MimicLocation.ndjson
SELECT fhir FROM mimic_fhir.location;

-- patient tracking resources
\echo patient
\o :outputdir/MimicPatient.ndjson
SELECT fhir FROM mimic_fhir.patient;

\echo encounter
\o :outputdir/MimicEncounter.ndjson
SELECT fhir FROM mimic_fhir.encounter;

\echo encounter
\o :outputdir/MimicEncounterED.ndjson
SELECT fhir FROM mimic_fhir.encounter_ed;

\echo encounter_icu
\o :outputdir/MimicEncounterICU.ndjson
SELECT fhir FROM mimic_fhir.encounter_icu;

-- data resources: conditions, diagnoses, procedures
\echo condition
\o :outputdir/MimicCondition.ndjson
SELECT fhir FROM mimic_fhir.condition;

\echo condition ED
\o :outputdir/MimicConditionED.ndjson
SELECT fhir FROM mimic_fhir.condition_ed;

\echo procedure
\o :outputdir/MimicProcedure.ndjson
SELECT fhir FROM mimic_fhir.procedure;

\echo procedure ED
\o :outputdir/MimicProcedureED.ndjson
SELECT fhir FROM mimic_fhir.procedure_ed;

\echo procedure_icu
\o :outputdir/MimicProcedureICU.ndjson
SELECT fhir FROM mimic_fhir.procedure_icu;

-- data resources: medications
\echo medication
\o :outputdir/MimicMedication.ndjson
SELECT fhir FROM mimic_fhir.medication;

\echo medication_request
\o :outputdir/MimicMedicationRequest.ndjson
SELECT fhir FROM mimic_fhir.medication_request;

\echo medication_dispense
\o :outputdir/MimicMedicationDispense.ndjson
SELECT fhir FROM mimic_fhir.medication_dispense;

\echo medication_dispense_ed
\o :outputdir/MimicMedicationDispenseED.ndjson
SELECT fhir FROM mimic_fhir.medication_dispense_ed;

\echo medadmin
\o :outputdir/MimicMedicationAdministration.ndjson
SELECT fhir FROM mimic_fhir.medication_administration;

\echo medication_administration_icu
\o :outputdir/MimicMedicationAdministrationICU.ndjson
SELECT fhir FROM mimic_fhir.medication_administration_icu;

\echo medication_statement_ed
\o :outputdir/MimicMedicationStatementED.ndjson
SELECT fhir FROM mimic_fhir.medication_statement_ed;

-- diagnostic resources
\echo observation_labevents
\o :outputdir/MimicObservationLabevents.ndjson
SELECT fhir FROM mimic_fhir.observation_labevents;

\echo observation_micro_org
\o :outputdir/MimicObservationMicroOrg.ndjson
SELECT fhir FROM mimic_fhir.observation_micro_org;

\echo observation_micro_susc
\o :outputdir/MimicObservationMicroSusc.ndjson
SELECT fhir FROM mimic_fhir.observation_micro_susc;

\echo observation_micro_test
\o :outputdir/MimicObservationMicroTest.ndjson
SELECT fhir FROM mimic_fhir.observation_micro_test;

\echo observation_chartevents
\o :outputdir/MimicObservationChartevents.ndjson
SELECT fhir FROM mimic_fhir.observation_chartevents;

\echo observation_datetimeevents
\o :outputdir/MimicObservationDatetimeevents.ndjson
SELECT fhir FROM mimic_fhir.observation_datetimeevents;

\echo observation_outputevents
\o :outputdir/MimicObservationOutputevents.ndjson
SELECT fhir FROM mimic_fhir.observation_outputevents;

\echo observation_ed
\o :outputdir/MimicObservationED.ndjson
SELECT fhir FROM mimic_fhir.observation_ed;

\echo observation_vitalsigns
\o :outputdir/MimicObservationVitalSigns.ndjson
SELECT fhir FROM mimic_fhir.observation_vital_signs;
