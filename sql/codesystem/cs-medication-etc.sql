-- Medication ETC CodeSystem (for MIMIC-ED)
-- Enhanced Therapeutic Class codes will need to be mapped in future to a standard medication system (ie using rxnorm)
-- ETC codes pulled in from mimiciv_ed.medrecon mimiciv_ed.pyxis

DROP TABLE IF EXISTS fhir_trm.cs_medication_etc;
CREATE TABLE fhir_trm.cs_medication_etc(
    code      VARCHAR PRIMARY KEY
    , display VARCHAR NOT NULL
);

WITH cs_medrecon AS (
 SELECT
     NULLIF(TRIM(etccode), '') AS cs_code
    , etcdescription AS cs_display
 FROM mimiciv_ed.medrecon
)
INSERT INTO fhir_trm.cs_medication_etc SELECT
    TRIM(cs_code) AS code
    , MAX(cs_display) AS display -- grab one description
FROM cs_medrecon
WHERE cs_code IS NOT NULL
GROUP BY cs_code

