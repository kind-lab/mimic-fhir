-- Medication Valueset
-- This is the primary medication valueset used in the main hospital medication system
-- combines 6 different codesystems into the one

DROP TABLE IF EXISTS fhir_trm.vs_medication;
CREATE TABLE fhir_trm.vs_medication(
    system      VARCHAR NOT NULL,
    code        VARCHAR NOT NULL
);

INSERT INTO fhir_trm.vs_medication (SYSTEM, code)
VALUES
    ('http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-medication-formulary-drug-cd', '*')
    , ('http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-medication-icu', '*')
    , ('http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-medication-name', '*')
    , ('http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-medication-ndc', '*')
    , ('http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-medication-poe-iv', '*')
