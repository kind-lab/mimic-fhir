WITH table_counts AS
(          SELECT COUNT(*) AS n_row_observed,    5006884 AS n_row_expected, 'condition' AS table_name FROM mimic_fhir.condition
    UNION ALL SELECT COUNT(*) AS n_row_observed,     946692 AS n_row_expected, 'condition_ed' AS table_name FROM mimic_fhir.condition_ed
    UNION ALL SELECT COUNT(*) AS n_row_observed,     454324 AS n_row_expected, 'encounter' AS table_name FROM mimic_fhir.encounter
    UNION ALL SELECT COUNT(*) AS n_row_observed,     447712 AS n_row_expected, 'encounter_ed' AS table_name FROM mimic_fhir.encounter_ed
    UNION ALL SELECT COUNT(*) AS n_row_observed,      76943 AS n_row_expected, 'encounter_icu' AS table_name FROM mimic_fhir.encounter_icu
    UNION ALL SELECT COUNT(*) AS n_row_observed,         39 AS n_row_expected, 'location' AS table_name FROM mimic_fhir.location
    UNION ALL SELECT COUNT(*) AS n_row_observed,      20075 AS n_row_expected, 'medication' AS table_name FROM mimic_fhir.medication
    UNION ALL SELECT COUNT(*) AS n_row_observed,   29128087 AS n_row_expected, 'medication_administration' AS table_name FROM mimic_fhir.medication_administration
    UNION ALL SELECT COUNT(*) AS n_row_observed,    9442345 AS n_row_expected, 'medication_administration_icu' AS table_name FROM mimic_fhir.medication_administration_icu
    UNION ALL SELECT COUNT(*) AS n_row_observed,   13350281 AS n_row_expected, 'medication_dispense' AS table_name FROM mimic_fhir.medication_dispense
    UNION ALL SELECT COUNT(*) AS n_row_observed,    1670590 AS n_row_expected, 'medication_dispense_ed' AS table_name FROM mimic_fhir.medication_dispense_ed
    UNION ALL SELECT COUNT(*) AS n_row_observed,       6461 AS n_row_expected, 'medication_mix' AS table_name FROM mimic_fhir.medication_mix
    UNION ALL SELECT COUNT(*) AS n_row_observed,   16217713 AS n_row_expected, 'medication_request' AS table_name FROM mimic_fhir.medication_request
    UNION ALL SELECT COUNT(*) AS n_row_observed,    2733573 AS n_row_expected, 'medication_statement_ed' AS table_name FROM mimic_fhir.medication_statement_ed
    UNION ALL SELECT COUNT(*) AS n_row_observed,    7477876 AS n_row_expected, 'observation_datetimeevents' AS table_name FROM mimic_fhir.observation_datetimeevents
    UNION ALL SELECT COUNT(*) AS n_row_observed,    4637088 AS n_row_expected, 'observation_ed' AS table_name FROM mimic_fhir.observation_ed
    UNION ALL SELECT COUNT(*) AS n_row_observed,     304527 AS n_row_expected, 'observation_micro_org' AS table_name FROM mimic_fhir.observation_micro_org
    UNION ALL SELECT COUNT(*) AS n_row_observed,    1163623 AS n_row_expected, 'observation_micro_susc' AS table_name FROM mimic_fhir.observation_micro_susc
    UNION ALL SELECT COUNT(*) AS n_row_observed,    2297709 AS n_row_expected, 'observation_micro_test' AS table_name FROM mimic_fhir.observation_micro_test
    UNION ALL SELECT COUNT(*) AS n_row_observed,    4450049 AS n_row_expected, 'observation_outputevents' AS table_name FROM mimic_fhir.observation_outputevents
    UNION ALL SELECT COUNT(*) AS n_row_observed,   10473440 AS n_row_expected, 'observation_vital_signs' AS table_name FROM mimic_fhir.observation_vital_signs
    UNION ALL SELECT COUNT(*) AS n_row_observed,          1 AS n_row_expected, 'organization' AS table_name FROM mimic_fhir.organization
    UNION ALL SELECT COUNT(*) AS n_row_observed,     315460 AS n_row_expected, 'patient' AS table_name FROM mimic_fhir.patient
    UNION ALL SELECT COUNT(*) AS n_row_observed,     704124 AS n_row_expected, 'procedure' AS table_name FROM mimic_fhir.procedure
    UNION ALL SELECT COUNT(*) AS n_row_observed,    2094688 AS n_row_expected, 'procedure_ed' AS table_name FROM mimic_fhir.procedure_ed
    UNION ALL SELECT COUNT(*) AS n_row_observed,     731788 AS n_row_expected, 'procedure_icu' AS table_name FROM mimic_fhir.procedure_icu
    UNION ALL SELECT COUNT(*) AS n_row_observed,    1670188 AS n_row_expected, 'specimen' AS table_name FROM mimic_fhir.specimen
    UNION ALL SELECT COUNT(*) AS n_row_observed,   14081306 AS n_row_expected, 'specimen_lab' 
    AS table_name FROM mimic_fhir.specimen_lab
    -- below are the two largest tables by an order of magnitude
    -- commenting them out reduces query time from ~10 minutes to just ~1 minute
    UNION ALL SELECT COUNT(*) AS n_row_observed, 124342638 AS n_row_expected, 'observation_labevents' AS table_name FROM mimic_fhir.observation_labevents
    UNION ALL SELECT COUNT(*) AS n_row_observed, 329822254 AS n_row_expected, 'observation_chartevents' AS table_name FROM mimic_fhir.observation_chartevents
)
SELECT table_name, n_row_expected, n_row_observed
, CASE WHEN n_row_observed = n_row_expected THEN 'PASS' ELSE 'FAIL' END AS test_status
FROM table_counts
ORDER BY table_name;
