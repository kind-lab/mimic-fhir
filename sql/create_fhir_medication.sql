-- Create medication tables

-- medication fhir_etl functions
\echo fn_build_medication_identifier
\i fn/fn_build_medication_identifier.sql

\echo fn_prescriptions_medication_code
\i fn/fn_prescriptions_medication_code.sql

-- medication data generation
\echo Medication prescriptions
\i medication/medication_prescriptions.sql

-- medication mix generation
\echo Medication mix
\i medication/medication_mix.sql