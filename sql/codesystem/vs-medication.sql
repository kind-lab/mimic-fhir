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
    ('http://fhir.mimic.mit.edu/CodeSystem/mimic-medication-formulary-drug-cd', '*')
    , ('http://fhir.mimic.mit.edu/CodeSystem/mimic-medication-icu', '*')
    , ('http://fhir.mimic.mit.edu/CodeSystem/mimic-medication-name', '*')
    , ('http://fhir.mimic.mit.edu/CodeSystem/mimic-medication-ndc', '*')
    , ('http://fhir.mimic.mit.edu/CodeSystem/mimic-medication-poe-iv', '*')
