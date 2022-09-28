-- Compare an estimated row count with the expected row counts.
-- Note the estimated row count uses a statistics table, and it is not
-- an exact measure. As a result, we look for a match with a ~3% tolerance.
WITH expected_counts AS
( 
              SELECT   4506 AS n_row_expected, 'condition' AS table_name
    UNION ALL SELECT    545 AS n_row_expected, 'condition_ed' AS table_name
    UNION ALL SELECT    275 AS n_row_expected, 'encounter' AS table_name
    UNION ALL SELECT    222 AS n_row_expected, 'encounter_ed' AS table_name
    UNION ALL SELECT    140 AS n_row_expected, 'encounter_icu' AS table_name
    UNION ALL SELECT     31 AS n_row_expected, 'location' AS table_name
    UNION ALL SELECT   1480 AS n_row_expected, 'medication' AS table_name
    UNION ALL SELECT  35926 AS n_row_expected, 'medication_administration' AS table_name
    UNION ALL SELECT  20404 AS n_row_expected, 'medication_administration_icu' AS table_name
    UNION ALL SELECT  14293 AS n_row_expected, 'medication_dispense' AS table_name
    UNION ALL SELECT   1082 AS n_row_expected, 'medication_dispense_ed' AS table_name
    UNION ALL SELECT    314 AS n_row_expected, 'medication_mix' AS table_name
    UNION ALL SELECT  15225 AS n_row_expected, 'medication_request' AS table_name
    UNION ALL SELECT   2411 AS n_row_expected, 'medication_statement_ed' AS table_name
    UNION ALL SELECT  15280 AS n_row_expected, 'observation_datetimeevents' AS table_name
    UNION ALL SELECT   2742 AS n_row_expected, 'observation_ed' AS table_name
    UNION ALL SELECT    338 AS n_row_expected, 'observation_micro_org' AS table_name
    UNION ALL SELECT   1036 AS n_row_expected, 'observation_micro_susc' AS table_name
    UNION ALL SELECT   1893 AS n_row_expected, 'observation_micro_test' AS table_name
    UNION ALL SELECT   9362 AS n_row_expected, 'observation_outputevents' AS table_name
    UNION ALL SELECT   6300 AS n_row_expected, 'observation_vital_signs' AS table_name
    UNION ALL SELECT      1 AS n_row_expected, 'organization' AS table_name
    UNION ALL SELECT    100 AS n_row_expected, 'patient' AS table_name
    UNION ALL SELECT    722 AS n_row_expected, 'procedure' AS table_name
    UNION ALL SELECT   1260 AS n_row_expected, 'procedure_ed' AS table_name
    UNION ALL SELECT   1468 AS n_row_expected, 'procedure_icu' AS table_name
    UNION ALL SELECT   1336 AS n_row_expected, 'specimen' AS table_name
    UNION ALL SELECT  11122 AS n_row_expected, 'specimen_lab' AS table_name
    UNION ALL SELECT 107727 AS n_row_expected, 'observation_labevents' AS table_name
    UNION ALL SELECT 668883 AS n_row_expected, 'observation_chartevents' AS table_name
)
-- for smaller tables, we do an exact count as the estimate is always -1
, small_table_counts AS
(
    SELECT 'location' AS table_name, COUNT(*) AS n_row_observed FROM mimic_fhir.location
    UNION ALL
    SELECT 'organization' AS table_name, COUNT(*) AS n_row_observed  FROM mimic_fhir.organization
)
-- for larger tables, pull the estimated count from reltuples
, observed_counts AS
(
    SELECT c.relname AS table_name
    , CAST(c.reltuples AS INTEGER) AS n_row_observed
    FROM pg_class c
    -- only include tables in the expected count CTE
    WHERE c.relname IN (SELECT table_name FROM expected_counts)
    -- exclude small tables with an exact count available, union them after
    AND c.relname NOT IN (SELECT table_name from small_table_counts)
    UNION ALL
    SELECT table_name, n_row_observed
    FROM small_table_counts
)
SELECT c.table_name
, n_row_expected, n_row_observed
, CASE
    WHEN c.n_row_observed BETWEEN (0.97*n_row_expected) AND (1.03*n_row_expected) THEN 'PASS'
ELSE 'FAIL' END AS test_status
FROM observed_counts c
INNER JOIN expected_counts e
    ON c.table_name = e.table_name
ORDER BY table_name;
