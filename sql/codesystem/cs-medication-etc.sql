-- Medication ETC CodeSystem (for MIMIC-ED)
-- Enhanced Therapeutic Class codes will need to be mapped in future to a standard medication system (ie using rxnorm)
-- ETC codes pulled in from mimic_ed.medrecon mimic_ed.pyxis

DROP TABLE IF EXISTS fhir_trm.cs_medication_etc;
CREATE TABLE fhir_trm.cs_medication_etc(
    code      VARCHAR NOT NULL
    , display VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_medication_etc
SELECT DISTINCT
    etccode AS code
    , etcdescription AS display
FROM mimic_ed.medrecon 
WHERE 
    etccode IS NOT NULL 
