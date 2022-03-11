-- Identifier Type CodeSystem
-- identifier types are used to differentiate sources of identifiers in MIMIC

DROP TABLE IF EXISTS fhir_trm.identifier_type;
CREATE TABLE fhir_trm.identifier_type(
    code      VARCHAR NOT NULL,
    display   VARCHAR NOT NULL
);

INSERT INTO fhir_trm.identifier_type(code, display)
VALUES  
    ('MEDHOSP', 'Medication Admin in the general hospital')
    , ('MEDICU', 'Medication Admin in the ICU')
    , ('PHID', 'Pharmacy identifier')
    , ('POE', 'Provider Order Entry')


    