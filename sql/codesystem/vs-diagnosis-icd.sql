-- Diagnosis ICD Valueset
-- Combine the ICD9 and ICD10 codesystems into one Valueset 

DROP TABLE IF EXISTS fhir_trm.vs_diagnosis_icd;
CREATE TABLE fhir_trm.vs_diagnosis_icd(
    system      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.vs_diagnosis_icd (system)
VALUES
    ('http://fhir.mimic.mit.edu/CodeSystem/diagnosis-icd9')
    , ('http://fhir.mimic.mit.edu/CodeSystem/diagnosis-icd10');
