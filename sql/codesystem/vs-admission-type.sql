-- Encounter Admission Type Valueset
-- Combine admission type codes across hosp, ICU, and ED

DROP TABLE IF EXISTS fhir_trm.vs_admission_type;
CREATE TABLE fhir_trm.vs_admission_type(
    system      VARCHAR NOT NULL,
    code        VARCHAR NOT NULL
);

INSERT INTO fhir_trm.vs_admission_type (SYSTEM, code)
VALUES
    ('http://mimic.mit.edu/fhir/CodeSystem/mimic-admission-type', '*') -- used for HSOP
    , ('http://snomed.info/sct', '308335008') -- Patient encounter procedure -- used for ED/ICU
