DROP TABLE IF EXISTS mimic_fhir_log.pat_everything_pass;
CREATE TABLE mimic_fhir_log.pat_everything_pass (
  logtime TIMESTAMP,
  patient_id STRING(36),
  page_num INT,
  resource_types STRING(255),
  gcp_filename STRING(200)
);
