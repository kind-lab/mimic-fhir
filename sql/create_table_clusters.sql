CLUSTER mimic_fhir.condition USING idx_condition_patient_id;
CLUSTER mimic_fhir.condition_ed USING idx_condition_ed_patient_id;
CLUSTER mimic_fhir.encounter USING idx_encounter_patient_id;
CLUSTER mimic_fhir.encounter_ed USING idx_encounter_ed_patient_id;
CLUSTER mimic_fhir.medication_administration USING idx_medication_administration_patient_id;
CLUSTER mimic_fhir.medication_administration_icu USING idx_medication_administration_icu_patient_id;
CLUSTER mimic_fhir.medication_dispense USING idx_medication_dispense_patient_id;
CLUSTER mimic_fhir.medication_dispense_ed USING idx_medication_dispense_ed_patient_id;
CLUSTER mimic_fhir.medication_request USING idx_medication_request_patient_id;
CLUSTER mimic_fhir.medication_statement_ed USING idx_medication_statement_ed_patient_id;
CLUSTER mimic_fhir.observation_chartevents USING idx_observation_chartevents_patient_id;
CLUSTER mimic_fhir.observation_datetimeevents USING idx_observation_datetimeevents_patient_id;
CLUSTER mimic_fhir.observation_ed USING idx_observation_ed_patient_id;
CLUSTER mimic_fhir.observation_labevents USING idx_observation_labevents_patient_id;
CLUSTER mimic_fhir.observation_micro_org USING idx_observation_micro_org_patient_id;
CLUSTER mimic_fhir.observation_micro_susc USING idx_observation_micro_susc_patient_id;
CLUSTER mimic_fhir.observation_micro_test USING idx_observation_micro_test_patient_id;
CLUSTER mimic_fhir.observation_outputevents USING idx_observation_outputevents_patient_id;
CLUSTER mimic_fhir.observation_vital_signs USING idx_observation_vital_signs_patient_id;
CLUSTER mimic_fhir.procedure USING idx_procedure_patient_id;
CLUSTER mimic_fhir.procedure_ed USING idx_procedure_ed_patient_id;
CLUSTER mimic_fhir.procedure_icu USING idx_procedure_icu_patient_id;
CLUSTER mimic_fhir.specimen USING idx_specimen_patient_id;
CLUSTER mimic_fhir.specimen_lab USING idx_specimen_lab_patient_id;


