-- Encounter Admission Class Valueset
-- Combine admission class codes across hosp, ICU, and ED

DROP TABLE IF EXISTS fhir_trm.vs_admission_class;
CREATE TABLE fhir_trm.vs_admission_class(
    system      VARCHAR NOT NULL,
    code        VARCHAR NOT NULL
);

INSERT INTO fhir_trm.vs_admission_class (SYSTEM, code)
VALUES
    ('http://fhir.mimic.mit.edu/CodeSystem/mimic-admission-class', '*') -- used for HSOP
    , ('http://terminology.hl7.org/CodeSystem/v3-ActCode', 'EMER') -- used for ED
    , ('http://terminology.hl7.org/CodeSystem/v3-ActCode', 'ACUTE') -- used for ICU
