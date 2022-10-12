DROP TABLE IF EXISTS mimic_fhir_log.bundle_pass;
CREATE TABLE mimic_fhir_log.bundle_pass (
  logtime TIMESTAMP,
  patient_id STRING(36),
  bundle_group STRING(100),
  bundle_id STRING(100),
  bundle_run STRING(100),
  starttime TIMESTAMP,
  endtime TIMESTAMP
);
