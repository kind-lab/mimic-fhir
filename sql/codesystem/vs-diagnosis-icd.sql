-- Diagnosis ICD Valueset
-- Combine the ICD9 and ICD10 codesystems into one Valueset 

DROP TABLE IF EXISTS fhir_trm.vs_diagnosis_icd;
CREATE TABLE fhir_trm.vs_diagnosis_icd(
    system      VARCHAR NOT NULL,
    code        VARCHAR NOT NULL
);

INSERT INTO fhir_trm.vs_diagnosis_icd (SYSTEM, code)
VALUES
    ('http://mimic.mit.edu/fhir/CodeSystem/mimic-diagnosis-icd9', '*')
    , ('http://mimic.mit.edu/fhir/CodeSystem/mimic-diagnosis-icd10', '*');
