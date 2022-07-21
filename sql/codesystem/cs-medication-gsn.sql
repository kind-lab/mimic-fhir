-- Medication GSN CodeSystem (for MIMIC-ED)
-- Generic Sequence Number Codes will need to be mapped in future to a standard medication system (ie using rxnorm)
-- GSN codes pulled in from mimic_ed.medrecon mimic_ed.pyxis

DROP TABLE IF EXISTS fhir_trm.cs_medication_gsn;
CREATE TABLE fhir_trm.cs_medication_gsn(
    code      VARCHAR NOT NULL
);

WITH mimic_gsn AS (
    SELECT DISTINCT gsn FROM mimic_ed.medrecon
    UNION
    SELECT DISTINCT gsn FROM mimic_ed.pyxis
)
INSERT INTO fhir_trm.cs_medication_gsn
SELECT gsn AS code
FROM mimic_gsn
WHERE 
    gsn IS NOT NULL 
    AND gsn != '0'
