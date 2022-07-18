-- Procedure ICD Valueset
-- Combine the ICD9 and ICD10 codesystems into one Valueset 

DROP TABLE IF EXISTS fhir_trm.vs_procedure_icd;
CREATE TABLE fhir_trm.vs_procedure_icd(
    system      VARCHAR NOT NULL,
    code        VARCHAR NOT NULL
);

INSERT INTO fhir_trm.vs_procedure_icd (SYSTEM, code)
VALUES
    ('http://fhir.mimic.mit.edu/CodeSystem/mimic-procedure-icd9', '*')
    , ('http://fhir.mimic.mit.edu/CodeSystem/mimic-procedure-icd10', '*')
