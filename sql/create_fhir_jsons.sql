\if :{?outputdir}
-- Variable is set, continue with other commands
\echo outputdir is set to :outputdir
\else
-- Variable is not set, produce an error and exit
\set ON_ERROR_STOP on
do $$ BEGIN RAISE 'outputdir not set, exiting'; END; $$ LANGUAGE plpgsql;
\endif

--- setup formatting options -----
--- this is a hack to avoid backslash escaping in the JSON output
\t
\pset format csv
\set with_format ' WITH CSV QUOTE AS E\'\\b\' DELIMITER E\'\\001\''
-----------output mimic-fhir tables to ndjson-------------

-- institutional resources
\echo organization
\set outputfile :outputdir/MimicOrganization.ndjson
\set command '\\copy mimic_fhir.organization(fhir) TO ' :'outputfile' :with_format
:command

\echo location
\set outputfile :outputdir/MimicLocation.ndjson
\set command '\\copy mimic_fhir.location(fhir) TO ' :'outputfile' :with_format
:command

-- patient tracking resources
\echo patient
\set outputfile :outputdir/MimicPatient.ndjson
\set command '\\copy mimic_fhir.patient(fhir) TO ' :'outputfile' :with_format
:command

\echo encounter
\set outputfile :outputdir/MimicEncounter.ndjson
\set command '\\copy mimic_fhir.encounter(fhir) TO ' :'outputfile' :with_format
:command

\echo encounter
\set outputfile :outputdir/MimicEncounterED.ndjson
\set command '\\copy mimic_fhir.encounter_ed(fhir) TO ' :'outputfile' :with_format
:command

\echo encounter_icu
\set outputfile :outputdir/MimicEncounterICU.ndjson
\set command '\\copy mimic_fhir.encounter_icu(fhir) TO ' :'outputfile' :with_format
:command

-- data resources: conditions, diagnoses, procedures
\echo condition
\set outputfile :outputdir/MimicCondition.ndjson
\set command '\\copy mimic_fhir.condition(fhir) TO ' :'outputfile' :with_format
:command

\echo condition ED
\set outputfile :outputdir/MimicConditionED.ndjson
\set command '\\copy mimic_fhir.condition_ed(fhir) TO ' :'outputfile' :with_format
:command

\echo procedure
\set outputfile :outputdir/MimicProcedure.ndjson
\set command '\\copy mimic_fhir.procedure(fhir) TO ' :'outputfile' :with_format
:command

\echo procedure ED
\set outputfile :outputdir/MimicProcedureED.ndjson
\set command '\\copy mimic_fhir.procedure_ed(fhir) TO ' :'outputfile' :with_format
:command

\echo procedure_icu
\set outputfile :outputdir/MimicProcedureICU.ndjson
\set command '\\copy mimic_fhir.procedure_icu(fhir) TO ' :'outputfile' :with_format
:command

-- data resources: medications
\echo medication
\set outputfile :outputdir/MimicMedication.ndjson
\set command '\\copy mimic_fhir.medication(fhir) TO ' :'outputfile' :with_format
:command

\echo medication_request
\set outputfile :outputdir/MimicMedicationRequest.ndjson
\set command '\\copy mimic_fhir.medication_request(fhir) TO ' :'outputfile' :with_format
:command

\echo medication_dispense
\set outputfile :outputdir/MimicMedicationDispense.ndjson
\set command '\\copy mimic_fhir.medication_dispense(fhir) TO ' :'outputfile' :with_format
:command

\echo medication_dispense_ed
\set outputfile :outputdir/MimicMedicationDispenseED.ndjson
\set command '\\copy mimic_fhir.medication_dispense_ed(fhir) TO ' :'outputfile' :with_format
:command

\echo medadmin
\set outputfile :outputdir/MimicMedicationAdministration.ndjson
\set command '\\copy mimic_fhir.medication_administration(fhir) TO ' :'outputfile' :with_format
:command

\echo medication_administration_icu
\set outputfile :outputdir/MimicMedicationAdministrationICU.ndjson
\set command '\\copy mimic_fhir.medication_administration_icu(fhir) TO ' :'outputfile' :with_format
:command

\echo medication_statement_ed
\set outputfile :outputdir/MimicMedicationStatementED.ndjson
\set command '\\copy mimic_fhir.medication_statement_ed(fhir) TO ' :'outputfile' :with_format
:command

-- diagnostic resources
\echo observation_labevents
\set outputfile :outputdir/MimicObservationLabevents.ndjson
\set command '\\copy mimic_fhir.observation_labevents(fhir) TO ' :'outputfile' :with_format
:command

\echo observation_micro_org
\set outputfile :outputdir/MimicObservationMicroOrg.ndjson
\set command '\\copy mimic_fhir.observation_micro_org(fhir) TO ' :'outputfile' :with_format
:command

\echo observation_micro_susc
\set outputfile :outputdir/MimicObservationMicroSusc.ndjson
\set command '\\copy mimic_fhir.observation_micro_susc(fhir) TO ' :'outputfile' :with_format
:command

\echo observation_micro_test
\set outputfile :outputdir/MimicObservationMicroTest.ndjson
\set command '\\copy mimic_fhir.observation_micro_test(fhir) TO ' :'outputfile' :with_format
:command

\echo observation_chartevents
\set outputfile :outputdir/MimicObservationChartevents.ndjson
\set command '\\copy mimic_fhir.observation_chartevents(fhir) TO ' :'outputfile' :with_format
:command

\echo observation_datetimeevents
\set outputfile :outputdir/MimicObservationDatetimeevents.ndjson
\set command '\\copy mimic_fhir.observation_datetimeevents(fhir) TO ' :'outputfile' :with_format
:command

\echo observation_outputevents
\set outputfile :outputdir/MimicObservationOutputevents.ndjson
\set command '\\copy mimic_fhir.observation_outputevents(fhir) TO ' :'outputfile' :with_format
:command

\echo observation_ed
\set outputfile :outputdir/MimicObservationED.ndjson
\set command '\\copy mimic_fhir.observation_ed(fhir) TO ' :'outputfile' :with_format
:command

\echo observation_vitalsigns
\set outputfile :outputdir/MimicObservationVitalSignsED.ndjson
\set command '\\copy mimic_fhir.observation_vital_signs(fhir) TO ' :'outputfile' :with_format
:command

\echo specimen
\set outputfile :outputdir/MimicSpecimen.ndjson
\set command '\\copy mimic_fhir.specimen(fhir) TO ' :'outputfile' :with_format
:command

\echo specimen_lab
\set outputfile :outputdir/MimicSpecimenLab.ndjson
\set command '\\copy mimic_fhir.specimen_lab(fhir) TO ' :'outputfile' :with_format
:command
