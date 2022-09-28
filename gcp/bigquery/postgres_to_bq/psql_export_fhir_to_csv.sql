
-- :output_dir is set in the initial psql command. Ensure '--set output_dir=$OUTPUT_DIR' is included

\echo patient
\set outputcsv '\'' :output_dir 'patient.csv' '\''
COPY mimic_fhir.patient TO :outputcsv CSV;

\echo condition
\set outputcsv '\'' :output_dir 'condition.csv' '\''
COPY mimic_fhir.condition TO :outputcsv CSV;

\echo condition_ed
\set outputcsv '\'' :output_dir 'condition_ed.csv' '\''
COPY mimic_fhir.condition_ed TO :outputcsv CSV;

\echo encounter
\set outputcsv '\'' :output_dir 'encounter.csv' '\''
COPY mimic_fhir.encounter TO :outputcsv CSV;

\echo encounter_ed
\set outputcsv '\'' :output_dir 'encounter_ed.csv' '\''
COPY mimic_fhir.encounter_ed TO :outputcsv CSV;

\echo encounter_icu
\set outputcsv '\'' :output_dir 'encounter_icu.csv' '\''
COPY mimic_fhir.encounter_icu TO :outputcsv CSV;

\echo location
\set outputcsv '\'' :output_dir 'location.csv' '\''
COPY mimic_fhir.location TO :outputcsv CSV;

\echo medication
\set outputcsv '\'' :output_dir 'medication.csv' '\''
COPY mimic_fhir.medication TO :outputcsv CSV;

\echo medication_administration
\set outputcsv '\'' :output_dir 'medication_administration.csv' '\''
COPY mimic_fhir.medication_administration TO :outputcsv CSV;

\echo medication_administration_icu
\set outputcsv '\'' :output_dir 'medication_administration_icu.csv' '\''
COPY mimic_fhir.medication_administration_icu TO :outputcsv CSV;

\echo medication_dispense
\set outputcsv '\'' :output_dir 'medication_dispense.csv' '\''
COPY mimic_fhir.medication_dispense TO :outputcsv CSV;

\echo medication_dispense_ed
\set outputcsv '\'' :output_dir 'medication_dispense_ed.csv' '\''
COPY mimic_fhir.medication_dispense_ed TO :outputcsv CSV;

\echo medication_mix
\set outputcsv '\'' :output_dir 'medication_mix.csv' '\''
COPY mimic_fhir.medication_mix TO :outputcsv CSV;

\echo medication_request
\set outputcsv '\'' :output_dir 'medication_request.csv' '\''
COPY mimic_fhir.medication_request TO :outputcsv CSV;

\echo medication_statement_ed
\set outputcsv '\'' :output_dir 'medication_statement_ed.csv' '\''
COPY mimic_fhir.medication_statement_ed TO :outputcsv CSV;

\echo observation_chartevents
\set outputcsv '\'' :output_dir 'observation_chartevents.csv' '\''
COPY mimic_fhir.observation_chartevents TO :outputcsv CSV;

\echo observation_datetimeevents
\set outputcsv '\'' :output_dir 'observation_datetimeevents.csv' '\''
COPY mimic_fhir.observation_datetimeevents TO :outputcsv CSV;

\echo observation_ed
\set outputcsv '\'' :output_dir 'observation_ed.csv' '\''
COPY mimic_fhir.observation_ed TO :outputcsv CSV;

\echo observation_labevents
\set outputcsv '\'' :output_dir 'observation_labevents.csv' '\''
COPY mimic_fhir.observation_labevents TO :outputcsv CSV;

\echo observation_micro_org
\set outputcsv '\'' :output_dir 'observation_micro_org.csv' '\''
COPY mimic_fhir.observation_micro_org TO :outputcsv CSV;

\echo observation_micro_test
\set outputcsv '\'' :output_dir 'observation_micro_test.csv' '\''
COPY mimic_fhir.observation_micro_test TO :outputcsv CSV;

\echo observation_micro_susc
\set outputcsv '\'' :output_dir 'observation_micro_susc.csv' '\''
COPY mimic_fhir.observation_micro_susc TO :outputcsv CSV;

\echo observation_outputevents
\set outputcsv '\'' :output_dir 'observation_outputevents.csv' '\''
COPY mimic_fhir.observation_outputevents TO :outputcsv CSV;

\echo observation_vital_signs
\set outputcsv '\'' :output_dir 'observation_vital_signs.csv' '\''
COPY mimic_fhir.observation_vital_signs TO :outputcsv CSV;

\echo organization
\set outputcsv '\'' :output_dir 'organization.csv' '\''
COPY mimic_fhir.organization TO :outputcsv CSV;

\echo procedure
\set outputcsv '\'' :output_dir 'procedure.csv' '\''
COPY mimic_fhir.procedure TO :outputcsv CSV;

\echo procedure_ed
\set outputcsv '\'' :output_dir 'procedure_ed.csv' '\''
COPY mimic_fhir.procedure_ed TO :outputcsv CSV;

\echo procedure_icu
\set outputcsv '\'' :output_dir 'procedure_icu.csv' '\''
COPY mimic_fhir.procedure_icu TO :outputcsv CSV;

\echo specimen
\set outputcsv '\'' :output_dir 'specimen.csv' '\''
COPY mimic_fhir.specimen TO :outputcsv CSV;

\echo specimen_lab
\set outputcsv '\'' :output_dir 'specimen_lab.csv' '\''
COPY mimic_fhir.specimen_lab TO :outputcsv CSV;
