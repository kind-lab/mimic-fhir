-- Exports all tables to ndjson files
-- Usage: psql mimic -f sql/export_fhir_tables.sql -v mimic_json_path='/path/to/mimic/json'

\COPY (SELECT to_json(fhir) FROM condition) TO PROGRAM 'gzip -n > condition.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM condition_ed) TO PROGRAM 'gzip -n > condition_ed.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM encounter) TO PROGRAM 'gzip -n > encounter.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM encounter_ed) TO PROGRAM 'gzip -n > encounter_ed.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM encounter_icu) TO PROGRAM 'gzip -n > encounter_icu.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM location) TO PROGRAM 'gzip -n > location.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM medication) TO PROGRAM 'gzip -n > medication.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM medication_administration) TO PROGRAM 'gzip -n > medication_administration.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM medication_administration_icu) TO PROGRAM 'gzip -n > medication_administration_icu.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM medication_dispense) TO PROGRAM 'gzip -n > medication_dispense.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM medication_dispense_ed) TO PROGRAM 'gzip -n > medication_dispense_ed.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM medication_mix) TO PROGRAM 'gzip -n > medication_mix.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM medication_request) TO PROGRAM 'gzip -n > medication_request.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM medication_statement_ed) TO PROGRAM 'gzip -n > medication_statement_ed.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM observation_chartevents) TO PROGRAM 'gzip -n > observation_chartevents.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM observation_datetimeevents) TO PROGRAM 'gzip -n > observation_datetimeevents.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM observation_ed) TO PROGRAM 'gzip -n > observation_ed.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM observation_labevents) TO PROGRAM 'gzip -n > observation_labevents.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM observation_micro_org) TO PROGRAM 'gzip -n > observation_micro_org.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM observation_micro_susc) TO PROGRAM 'gzip -n > observation_micro_susc.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM observation_micro_test) TO PROGRAM 'gzip -n > observation_micro_test.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM observation_outputevents) TO PROGRAM 'gzip -n > observation_outputevents.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM observation_vital_signs) TO PROGRAM 'gzip -n > observation_vital_signs.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM organization) TO PROGRAM 'gzip -n > organization.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM patient) TO PROGRAM 'gzip -n > patient.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM procedure) TO PROGRAM 'gzip -n > procedure.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM procedure_ed) TO PROGRAM 'gzip -n > procedure_ed.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM procedure_icu) TO PROGRAM 'gzip -n > procedure_icu.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM specimen) TO PROGRAM 'gzip -n > specimen.ndjson.gz';
\COPY (SELECT to_json(fhir) FROM specimen_lab) TO PROGRAM 'gzip -n > specimen_lab.ndjson.gz';