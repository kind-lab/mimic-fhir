-- Medication GSN CodeSystem
-- GSN Codes will need to be mapped in future to a standard medication system (ie using rxnorm)

DROP TABLE IF EXISTS fhir_trm.cs_medication_gsn;
CREATE TABLE fhir_trm.cs_medication_gsn(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_medication_gsn 
SELECT DISTINCT UNNEST(STRING_TO_ARRAY(TRIM(gsn),' ')) AS code
FROM mimic_hosp.prescriptions 
WHERE 
    gsn IS NOT NULL;
