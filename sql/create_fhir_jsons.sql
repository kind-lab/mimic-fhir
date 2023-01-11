--\set outputdir '/tmp/mimic_output'
--\! mkdir -p '/tmp/mimic_output'
\set outputdir '/Volumes/Samsung SSD T7/mimic-fhir-demo'

\t
-- removes single space in front of output
\pset format unaligned 

-----------output mimic-fhir tables to ndjson-------------

-- institutional resources
\echo organization
\set outputfile :outputdir/MimicOrganization.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.organization) TO ' :'outputfile' 
:command

\echo location
\set outputfile :outputdir/MimicLocation.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.location) TO ' :'outputfile' 
:command

-- patient tracking resources
\echo patient
\set outputfile :outputdir/MimicPatient.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.patient) TO ' :'outputfile' 
:command

\echo encounter
\set outputfile :outputdir/MimicEncounter.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.encounter) TO ' :'outputfile' 
:command

\echo encounter
\set outputfile :outputdir/MimicEncounterED.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.encounter_ed) TO ' :'outputfile' 
:command

\echo encounter_icu
\set outputfile :outputdir/MimicEncounterICU.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.encounter_icu) TO ' :'outputfile' 
:command

-- data resources: conditions, diagnoses, procedures
\echo condition
\set outputfile :outputdir/MimicCondition.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.condition) TO ' :'outputfile' 
:command

\echo condition ED
\set outputfile :outputdir/MimicConditionED.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.condition_ed) TO ' :'outputfile' 
:command

\echo procedure
\set outputfile :outputdir/MimicProcedure.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.procedure) TO ' :'outputfile' 
:command

\echo procedure ED
\set outputfile :outputdir/MimicProcedureED.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.procedure_ed) TO ' :'outputfile' 
:command

\echo procedure_icu
\set outputfile :outputdir/MimicProcedureICU.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.procedure_icu) TO ' :'outputfile' 
:command

-- data resources: medications
\echo medication
\set outputfile :outputdir/MimicMedication.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.medication) TO ' :'outputfile' 
:command

\echo medication_request
\set outputfile :outputdir/MimicMedicationRequest.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.medication_request) TO ' :'outputfile' 
:command

\echo medication_dispense
\set outputfile :outputdir/MimicMedicationDispense.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.medication_dispense) TO ' :'outputfile' 
:command

\echo medication_dispense_ed
\set outputfile :outputdir/MimicMedicationDispenseED.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.medication_dispense_ed) TO ' :'outputfile' 
:command

\echo medadmin
\set outputfile :outputdir/MimicMedicationAdministration.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.medication_administration) TO ' :'outputfile' 
:command

\echo medication_administration_icu
\set outputfile :outputdir/MimicMedicationAdministrationICU.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.medication_administration_icu) TO ' :'outputfile' 
:command

\echo medication_statement_ed
\set outputfile :outputdir/MimicMedicationStatementED.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.medication_statement_ed) TO ' :'outputfile' 
:command

-- diagnostic resources
\echo observation_labevents
\set outputfile :outputdir/MimicObservationLabevents.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.observation_labevents) TO ' :'outputfile' 
:command

\echo observation_micro_org
\set outputfile :outputdir/MimicObservationMicroOrg.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.observation_micro_org) TO ' :'outputfile' 
:command

\echo observation_micro_susc
\set outputfile :outputdir/MimicObservationMicroSusc.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.observation_micro_susc) TO ' :'outputfile' 
:command

\echo observation_micro_test
\set outputfile :outputdir/MimicObservationMicroTest.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.observation_micro_test) TO ' :'outputfile' 
:command

\echo observation_chartevents
\set outputfile :outputdir/MimicObservationChartevents.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.observation_chartevents) TO ' :'outputfile' 
:command

\echo observation_datetimeevents
\set outputfile :outputdir/MimicObservationDatetimeevents.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.observation_datetimeevents) TO ' :'outputfile' 
:command

\echo observation_outputevents
\set outputfile :outputdir/MimicObservationOutputevents.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.observation_outputevents) TO ' :'outputfile' 
:command

\echo observation_ed
\set outputfile :outputdir/MimicObservationED.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.observation_ed) TO ' :'outputfile' 
:command

\echo observation_vitalsigns
\set outputfile :outputdir/MimicObservationVitalSigns.ndjson
\set command '\\copy (SELECT fhir FROM mimic_fhir.observation_vital_signs) TO ' :'outputfile' 
:command
