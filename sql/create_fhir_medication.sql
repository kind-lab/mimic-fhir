-- Create medication tables

\echo Create medication base table
\i medication/medication_base.sql

-- medication functions
\echo fn_build_medication_identifier
\i fn/fn_build_medication_identifier.sql

\echo fn_prescriptions_medication_code
\i fn/fn_prescriptions_medication_code.sql

-- medication data generation
\echo Medication formulary drug code
\i medication/medication_formulary_drug_cd.sql

\echo Medication prescriptions
\i medication/medication_prescriptions.sql

\echo Medication name
\i medication/medication_name.sql

\echo Medication POE IV
\i medication/medication_poe_iv.sql

\echo Medication ICU
\i medication/medication_icu.sql

-- medication mix generation
\echo Medication mix
\i medication/medication_mix.sql