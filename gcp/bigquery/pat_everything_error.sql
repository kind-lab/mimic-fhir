DROP TABLE IF EXISTS mimic_fhir_log.pat_everything_error;
CREATE TABLE mimic_fhir_log.pat_everything_error (
  logtime TIMESTAMP,
  patient_id STRING(36),
  page_num INT,
  resource_types STRING(255),
  error_text STRING(255),
  error_diagnostics STRING(255),
);
