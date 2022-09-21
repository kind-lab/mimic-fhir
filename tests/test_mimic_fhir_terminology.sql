WITH table_counts AS
(             SELECT 'CodeSystem' AS resource, 'Administration' AS category, COUNT(*) AS n_row_observed, 9 AS n_row_expected, 'AdmissionType' AS table_name FROM fhir_trm.cs_admission_type
    UNION ALL SELECT 'CodeSystem' AS resource, 'Administration' AS category, COUNT(*) AS n_row_observed, 16 AS n_row_expected, 'AdmitSource' AS table_name FROM fhir_trm.cs_admit_source
    UNION ALL SELECT 'CodeSystem' AS resource, 'Administration' AS category, COUNT(*) AS n_row_observed, 20 AS n_row_expected, 'DischargeDisposition' AS table_name FROM fhir_trm.cs_discharge_disposition
    UNION ALL SELECT 'CodeSystem' AS resource, 'Administration' AS category, COUNT(*) AS n_row_observed, 2202 AS n_row_expected, 'HcpcsCd' AS table_name FROM fhir_trm.cs_hcpcs_cd
    UNION ALL SELECT 'CodeSystem' AS resource, 'Administration' AS category, COUNT(*) AS n_row_observed, 19 AS n_row_expected, 'Services' AS table_name FROM fhir_trm.cs_services
    
    UNION ALL SELECT 'CodeSystem' AS resource, 'Charted Observation' AS category, COUNT(*) AS n_row_observed, 2982 AS n_row_expected, 'CharteventsDItems' AS table_name FROM fhir_trm.cs_chartevents_d_items
    UNION ALL SELECT 'CodeSystem' AS resource, 'Charted Observation' AS category, COUNT(*) AS n_row_observed, 434 AS n_row_expected, 'DItems' AS table_name FROM fhir_trm.cs_d_items
    UNION ALL SELECT 'CodeSystem' AS resource, 'General' AS category, COUNT(*) AS n_row_observed, 683 AS n_row_expected, 'Units' AS table_name FROM fhir_trm.cs_units
    
    UNION ALL SELECT 'CodeSystem' AS resource, 'Medication' AS category, COUNT(*) AS n_row_observed, 16 AS n_row_expected, 'MedAdminCategoryICU' AS table_name FROM fhir_trm.cs_medadmin_category_icu
    UNION ALL SELECT 'CodeSystem' AS resource, 'Medication' AS category, COUNT(*) AS n_row_observed, 1208 AS n_row_expected, 'MedicationEtc' AS table_name FROM fhir_trm.cs_medication_etc
    UNION ALL SELECT 'CodeSystem' AS resource, 'Medication' AS category, COUNT(*) AS n_row_observed, 4128 AS n_row_expected, 'MedicationFormularyDrugCd' AS table_name FROM fhir_trm.cs_medication_formulary_drug_cd
    UNION ALL SELECT 'CodeSystem' AS resource, 'Medication' AS category, COUNT(*) AS n_row_observed, 163 AS n_row_expected, 'MedicationFrequency' AS table_name FROM fhir_trm.cs_medication_frequency
    UNION ALL SELECT 'CodeSystem' AS resource, 'Medication' AS category, COUNT(*) AS n_row_observed, 9430 AS n_row_expected, 'MedicationGsn' AS table_name FROM fhir_trm.cs_medication_gsn    
    UNION ALL SELECT 'CodeSystem' AS resource, 'Medication' AS category, COUNT(*) AS n_row_observed, 474 AS n_row_expected, 'MedicationICU' AS table_name FROM fhir_trm.cs_medication_icu
    UNION ALL SELECT 'CodeSystem' AS resource, 'Medication' AS category, COUNT(*) AS n_row_observed, 70 AS n_row_expected, 'MedicationMethod' AS table_name FROM fhir_trm.cs_medication_method
    UNION ALL SELECT 'CodeSystem' AS resource, 'Medication' AS category, COUNT(*) AS n_row_observed, 5 AS n_row_expected, 'MedicationMethodICU' AS table_name FROM fhir_trm.cs_medication_method_icu
    UNION ALL SELECT 'CodeSystem' AS resource, 'Medication' AS category, COUNT(*) AS n_row_observed, 10198 AS n_row_expected, 'MedicationName' AS table_name FROM fhir_trm.cs_medication_name
    UNION ALL SELECT 'CodeSystem' AS resource, 'Medication' AS category, COUNT(*) AS n_row_observed, 5745 AS n_row_expected, 'MedicationNdc' AS table_name FROM fhir_trm.cs_medication_ndc
    UNION ALL SELECT 'CodeSystem' AS resource, 'Medication' AS category, COUNT(*) AS n_row_observed, 2 AS n_row_expected, 'MedicationPoeIV' AS table_name FROM fhir_trm.cs_medication_poe_iv
    UNION ALL SELECT 'CodeSystem' AS resource, 'Medication' AS category, COUNT(*) AS n_row_observed, 106 AS n_row_expected, 'MedicationRoute' AS table_name FROM fhir_trm.cs_medication_route
    UNION ALL SELECT 'CodeSystem' AS resource, 'Medication' AS category, COUNT(*) AS n_row_observed, 379 AS n_row_expected, 'MedicationSite' AS table_name FROM fhir_trm.cs_medication_site
    
    UNION ALL SELECT 'CodeSystem' AS resource, 'Orders' AS category, COUNT(*) AS n_row_observed, 18450 AS n_row_expected, 'DiagnosisICD10' AS table_name FROM fhir_trm.cs_diagnosis_icd10
    UNION ALL SELECT 'CodeSystem' AS resource, 'Orders' AS category, COUNT(*) AS n_row_observed, 9463 AS n_row_expected, 'DiagnosisICD9' AS table_name FROM fhir_trm.cs_diagnosis_icd9
    UNION ALL SELECT 'CodeSystem' AS resource, 'Orders' AS category, COUNT(*) AS n_row_observed, 14 AS n_row_expected, 'ProcedureCategory' AS table_name FROM fhir_trm.cs_procedure_category
    UNION ALL SELECT 'CodeSystem' AS resource, 'Orders' AS category, COUNT(*) AS n_row_observed, 10233 AS n_row_expected, 'ProcedureICD10' AS table_name FROM fhir_trm.cs_procedure_icd10
    UNION ALL SELECT 'CodeSystem' AS resource, 'Orders' AS category, COUNT(*) AS n_row_observed, 2555 AS n_row_expected, 'ProcedureICD9' AS table_name FROM fhir_trm.cs_procedure_icd9
    
    
    UNION ALL SELECT 'CodeSystem' AS resource, 'Specimen Observation' AS category, COUNT(*) AS n_row_observed, 109 AS n_row_expected, 'BodySite' AS table_name FROM fhir_trm.cs_bodysite
    UNION ALL SELECT 'CodeSystem' AS resource, 'Specimen Observation' AS category, COUNT(*) AS n_row_observed, 1623 AS n_row_expected, 'DLabItems' AS table_name FROM fhir_trm.cs_d_labitems    
    UNION ALL SELECT 'CodeSystem' AS resource, 'Specimen Observation' AS category, COUNT(*) AS n_row_observed, 12 AS n_row_expected, 'LabFluid' AS table_name FROM fhir_trm.cs_lab_fluid
    UNION ALL SELECT 'CodeSystem' AS resource, 'Specimen Observation' AS category, COUNT(*) AS n_row_observed, 27 AS n_row_expected, 'MicrobiologyAntibiotic' AS table_name FROM fhir_trm.cs_microbiology_antibiotic
    UNION ALL SELECT 'CodeSystem' AS resource, 'Specimen Observation' AS category, COUNT(*) AS n_row_observed, 4 AS n_row_expected, 'MicrobiologyInterpretation' AS table_name FROM fhir_trm.cs_microbiology_interpretation
    UNION ALL SELECT 'CodeSystem' AS resource, 'Specimen Observation' AS category, COUNT(*) AS n_row_observed, 651 AS n_row_expected, 'MicrobiologyOrganism' AS table_name FROM fhir_trm.cs_microbiology_organism
    UNION ALL SELECT 'CodeSystem' AS resource, 'Specimen Observation' AS category, COUNT(*) AS n_row_observed, 177 AS n_row_expected, 'MicrobiologyTest' AS table_name FROM fhir_trm.cs_microbiology_test
    UNION ALL SELECT 'CodeSystem' AS resource, 'Specimen Observation' AS category, COUNT(*) AS n_row_observed, 104 AS n_row_expected, 'SpecTypeDesc' AS table_name FROM fhir_trm.cs_spec_type_desc

    
    UNION ALL SELECT 'ValueSet' AS resource, 'Administration' AS category, COUNT(*) AS n_row_observed, 3 AS n_row_expected, 'AdmissionClass' AS table_name FROM fhir_trm.vs_admission_class
    UNION ALL SELECT 'ValueSet' AS resource, 'Administration' AS category, COUNT(*) AS n_row_observed, 2 AS n_row_expected, 'AdmissionType' AS table_name FROM fhir_trm.vs_admission_type
    UNION ALL SELECT 'ValueSet' AS resource, 'Administration' AS category, COUNT(*) AS n_row_observed, 2 AS n_row_expected, 'EncounterType' AS table_name FROM fhir_trm.vs_encounter_type
    
    UNION ALL SELECT 'ValueSet' AS resource, 'Charted Observation' AS category, COUNT(*) AS n_row_observed, 188 AS n_row_expected, 'DatetimeeventsDItems' AS table_name FROM fhir_trm.vs_datetimeevents_d_items
    UNION ALL SELECT 'ValueSet' AS resource, 'Charted Observation' AS category, COUNT(*) AS n_row_observed, 77 AS n_row_expected, 'OutputeventsDItems' AS table_name FROM fhir_trm.vs_outputevents_d_items
    UNION ALL SELECT 'ValueSet' AS resource, 'Charted Observation' AS category, COUNT(*) AS n_row_observed, 169 AS n_row_expected, 'ProcedureEventsDItems' AS table_name FROM fhir_trm.vs_procedureevents_d_items

    
    UNION ALL SELECT 'ValueSet' AS resource, 'Medication' AS category, COUNT(*) AS n_row_observed, 5 AS n_row_expected, 'Medication' AS table_name FROM fhir_trm.vs_medication    
    UNION ALL SELECT 'ValueSet' AS resource, 'Orders' AS category, COUNT(*) AS n_row_observed, 2 AS n_row_expected, 'DiagnosisICD' AS table_name FROM fhir_trm.vs_diagnosis_icd
    UNION ALL SELECT 'ValueSet' AS resource, 'Orders' AS category, COUNT(*) AS n_row_observed, 2 AS n_row_expected, 'ProcedureICD' AS table_name FROM fhir_trm.vs_procedure_icd
    UNION ALL SELECT 'ValueSet' AS resource, 'Specimen Observation' AS category, COUNT(*) AS n_row_observed, 2 AS n_row_expected, 'SpecimenType' AS table_name FROM fhir_trm.vs_specimen_type
    
    )
SELECT resource, category, table_name, n_row_expected, n_row_observed
, CASE WHEN n_row_observed = n_row_expected THEN 'PASS' ELSE 'FAIL' END AS test_status
FROM table_counts
ORDER BY resource, category, table_name;