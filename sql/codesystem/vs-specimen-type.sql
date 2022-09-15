-- Specimen Type Valueset
-- Combine the specimen type codesystems from microbiology and labs

DROP TABLE IF EXISTS fhir_trm.vs_specimen_type;
CREATE TABLE fhir_trm.vs_specimen_type(
    system      VARCHAR NOT NULL,
    code        VARCHAR NOT NULL
);

INSERT INTO fhir_trm.vs_specimen_type (SYSTEM, code)
VALUES
    ('http://mimic.mit.edu/fhir/CodeSystem/mimic-lab-fluid', '*')
    , ('http://mimic.mit.edu/fhir/CodeSystem/mimic-spec-type-desc', '*')
