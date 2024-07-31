WITH expected AS
(
    SELECT 'condition' AS tbl,                          4756326 AS row_count UNION ALL
    SELECT 'condition_ed' AS tbl,                       899050 AS row_count UNION ALL
    SELECT 'encounter' AS tbl,                          431231 AS row_count UNION ALL
    SELECT 'encounter_ed' AS tbl,                       425087 AS row_count UNION ALL
    SELECT 'encounter_icu' AS tbl,                      73181 AS row_count UNION ALL
    SELECT 'location' AS tbl,                           39 AS row_count UNION ALL
    SELECT 'medication' AS tbl,                         19689 AS row_count UNION ALL
    SELECT 'medication_administration' AS tbl,          27754178 AS row_count UNION ALL
    SELECT 'medication_administration_icu' AS tbl,      8978893 AS row_count UNION ALL
    SELECT 'medication_dispense' AS tbl,                12689766 AS row_count UNION ALL
    SELECT 'medication_dispense_ed' AS tbl,             1586053 AS row_count UNION ALL
    SELECT 'medication_mix' AS tbl,                     6338 AS row_count UNION ALL
    SELECT 'medication_request' AS tbl,                 15416901 AS row_count UNION ALL
    SELECT 'medication_statement_ed' AS tbl,            2598365 AS row_count UNION ALL
    SELECT 'observation_chartevents' AS tbl,            313645032 AS row_count UNION ALL
    SELECT 'observation_datetimeevents' AS tbl,         7112999 AS row_count UNION ALL
    SELECT 'observation_ed' AS tbl,                     4404481 AS row_count UNION ALL
    SELECT 'observation_labevents' AS tbl,              118171367 AS row_count UNION ALL
    SELECT 'observation_micro_org' AS tbl,              289928 AS row_count UNION ALL
    SELECT 'observation_micro_susc' AS tbl,             1107278 AS row_count UNION ALL
    SELECT 'observation_micro_test' AS tbl,             2184371 AS row_count UNION ALL
    SELECT 'observation_outputevents' AS tbl,           4234967 AS row_count UNION ALL
    SELECT 'observation_vital_signs' AS tbl,            9948485 AS row_count UNION ALL
    SELECT 'organization' AS tbl,                       1 AS row_count UNION ALL
    SELECT 'patient' AS tbl,                            299712 AS row_count UNION ALL
    SELECT 'procedure' AS tbl,                          669186 AS row_count UNION ALL
    SELECT 'procedure_ed' AS tbl,                       1989697 AS row_count UNION ALL
    SELECT 'procedure_icu' AS tbl,                      696092 AS row_count UNION ALL
    SELECT 'specimen' AS tbl,                           1587215 AS row_count UNION ALL
    SELECT 'specimen_lab' AS tbl,                       13376689 AS row_count
), observed as
(
    SELECT 'condition' AS tbl, count(*) AS row_count FROM mimic_fhir.condition UNION ALL
    SELECT 'condition_ed' AS tbl, count(*) AS row_count FROM mimic_fhir.condition_ed UNION ALL
    SELECT 'encounter' AS tbl, count(*) AS row_count FROM mimic_fhir.encounter UNION ALL
    SELECT 'encounter_ed' AS tbl, count(*) AS row_count FROM mimic_fhir.encounter_ed UNION ALL
    SELECT 'encounter_icu' AS tbl, count(*) AS row_count FROM mimic_fhir.encounter_icu UNION ALL
    SELECT 'location' AS tbl, count(*) AS row_count FROM mimic_fhir.location UNION ALL
    SELECT 'medication' AS tbl, count(*) AS row_count FROM mimic_fhir.medication UNION ALL
    SELECT 'medication_administration' AS tbl, count(*) AS row_count FROM mimic_fhir.medication_administration UNION ALL
    SELECT 'medication_administration_icu' AS tbl, count(*) AS row_count FROM mimic_fhir.medication_administration_icu UNION ALL
    SELECT 'medication_dispense' AS tbl, count(*) AS row_count FROM mimic_fhir.medication_dispense UNION ALL
    SELECT 'medication_dispense_ed' AS tbl, count(*) AS row_count FROM mimic_fhir.medication_dispense_ed UNION ALL
    SELECT 'medication_mix' AS tbl, count(*) AS row_count FROM mimic_fhir.medication_mix UNION ALL
    SELECT 'medication_request' AS tbl, count(*) AS row_count FROM mimic_fhir.medication_request UNION ALL
    SELECT 'medication_statement_ed' AS tbl, count(*) AS row_count FROM mimic_fhir.medication_statement_ed UNION ALL
    SELECT 'observation_chartevents' AS tbl, count(*) AS row_count FROM mimic_fhir.observation_chartevents UNION ALL
    SELECT 'observation_datetimeevents' AS tbl, count(*) AS row_count FROM mimic_fhir.observation_datetimeevents UNION ALL
    SELECT 'observation_ed' AS tbl, count(*) AS row_count FROM mimic_fhir.observation_ed UNION ALL
    SELECT 'observation_labevents' AS tbl, count(*) AS row_count FROM mimic_fhir.observation_labevents UNION ALL
    SELECT 'observation_micro_org' AS tbl, count(*) AS row_count FROM mimic_fhir.observation_micro_org UNION ALL
    SELECT 'observation_micro_susc' AS tbl, count(*) AS row_count FROM mimic_fhir.observation_micro_susc UNION ALL
    SELECT 'observation_micro_test' AS tbl, count(*) AS row_count FROM mimic_fhir.observation_micro_test UNION ALL
    SELECT 'observation_outputevents' AS tbl, count(*) AS row_count FROM mimic_fhir.observation_outputevents UNION ALL
    SELECT 'observation_vital_signs' AS tbl, count(*) AS row_count FROM mimic_fhir.observation_vital_signs UNION ALL
    SELECT 'organization' AS tbl, count(*) AS row_count FROM mimic_fhir.organization UNION ALL
    SELECT 'patient' AS tbl, count(*) AS row_count FROM mimic_fhir.patient UNION ALL
    SELECT 'procedure' AS tbl, count(*) AS row_count FROM mimic_fhir.procedure UNION ALL
    SELECT 'procedure_ed' AS tbl, count(*) AS row_count FROM mimic_fhir.procedure_ed UNION ALL
    SELECT 'procedure_icu' AS tbl, count(*) AS row_count FROM mimic_fhir.procedure_icu UNION ALL
    SELECT 'specimen' AS tbl, count(*) AS row_count FROM mimic_fhir.specimen UNION ALL
    SELECT 'specimen_lab' AS tbl, count(*) AS row_count FROM mimic_fhir.specimen_lab
)
SELECT
    exp.tbl
    , exp.row_count AS expected_count
    , obs.row_count AS observed_count
    , CASE
        WHEN exp.row_count = obs.row_count
        THEN 'PASSED'
        ELSE 'FAILED'
    END AS ROW_COUNT_CHECK
FROM expected exp
INNER JOIN observed obs
  ON exp.tbl = obs.tbl
ORDER BY exp.tbl
;
