DROP TABLE IF EXISTS mimic_fhir_log.bundle_error;
CREATE TABLE mimic_fhir_log.bundle_error(
  logtime TIMESTAMP,
  patient_id STRING(36),
  bundle_group STRING(100),
  bundle_id STRING(100),
  bundle_run STRING(100),
  error_text STRING(255),
  error_diagnostics STRING(255),
  error_expression STRING(255)
);
