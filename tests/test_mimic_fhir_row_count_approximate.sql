WITH expected_counts AS
( 
    SELECT   5006884 AS n_row_expected, 'condition' AS table_name UNION ALL
    SELECT    946692 AS n_row_expected, 'condition_ed' AS table_name  UNION ALL
    SELECT    454324 AS n_row_expected, 'encounter' AS table_name  UNION ALL
    SELECT    447712 AS n_row_expected, 'encounter_ed' AS table_name  UNION ALL
    SELECT     76943 AS n_row_expected, 'encounter_icu' AS table_name  UNION ALL
    SELECT        39 AS n_row_expected, 'location' AS table_name  UNION ALL
    SELECT     20075 AS n_row_expected, 'medication' AS table_name  UNION ALL
    SELECT  29128087 AS n_row_expected, 'medication_administration' AS table_name  UNION ALL
    SELECT   9442345 AS n_row_expected, 'medication_administration_icu' AS table_name  UNION ALL
    SELECT  13350281 AS n_row_expected, 'medication_dispense' AS table_name  UNION ALL
    SELECT   1670590 AS n_row_expected, 'medication_dispense_ed' AS table_name  UNION ALL
    SELECT      6461 AS n_row_expected, 'medication_mix' AS table_name  UNION ALL
    SELECT  16217713 AS n_row_expected, 'medication_request' AS table_name  UNION ALL
    SELECT   2733573 AS n_row_expected, 'medication_statement_ed' AS table_name  UNION ALL
    SELECT   7477876 AS n_row_expected, 'observation_datetimeevents' AS table_name  UNION ALL
    SELECT   4637088 AS n_row_expected, 'observation_ed' AS table_name  UNION ALL
    SELECT    304527 AS n_row_expected, 'observation_micro_org' AS table_name  UNION ALL
    SELECT   1163623 AS n_row_expected, 'observation_micro_susc' AS table_name  UNION ALL
    SELECT   2297709 AS n_row_expected, 'observation_micro_test' AS table_name  UNION ALL
    SELECT   4450049 AS n_row_expected, 'observation_outputevents' AS table_name  UNION ALL
    SELECT  10473440 AS n_row_expected, 'observation_vital_signs' AS table_name  UNION ALL
    SELECT         1 AS n_row_expected, 'organization' AS table_name  UNION ALL
    SELECT    315460 AS n_row_expected, 'patient' AS table_name  UNION ALL
    SELECT    704124 AS n_row_expected, 'procedure' AS table_name  UNION ALL
    SELECT   2094688 AS n_row_expected, 'procedure_ed' AS table_name  UNION ALL
    SELECT    731788 AS n_row_expected, 'procedure_icu' AS table_name  UNION ALL
    SELECT   1670188 AS n_row_expected, 'specimen' AS table_name  UNION ALL
    SELECT  14081306 AS n_row_expected, 'specimen_lab' AS table_name  UNION ALL
    SELECT 124342638 AS n_row_expected, 'observation_labevents' AS table_name UNION ALL
    SELECT 329822254 AS n_row_expected, 'observation_chartevents' AS table_name
)
-- TODO: deal with small tables
SELECT c.relname AS table_name
-- for smaller tables, we do an exact count
, CASE
    WHEN c.relname = 'location' THEN (SELECT COUNT(*) FROM mimic_fhir.location)
    WHEN c.relname = 'organization' THEN (SELECT COUNT(*) FROM mimic_fhir.organization)
    -- approximate estimate is c.reltuples
    ELSE CAST(c.reltuples AS INTEGER) AS n_row_estimate
, e.n_row_expected
, CASE
    WHEN c.reltuples BETWEEN (0.97*n_row_expected) AND (1.03*n_row_expected) THEN 'PASS'
ELSE 'FAIL' END AS test_status
FROM pg_class c
INNER JOIN expected_counts e
ON c.relname = e.table_name
ORDER BY table_name;