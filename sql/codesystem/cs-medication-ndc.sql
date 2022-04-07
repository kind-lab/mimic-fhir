-- Medication NDC CodeSystem
-- National Drug Codes will need to be mapped in future to a standard medication system (ie using rxnorm)

DROP TABLE IF EXISTS fhir_trm.cs_medication_ndc;
CREATE TABLE fhir_trm.cs_medication_ndc(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_medication_ndc 
SELECT DISTINCT ndc AS code
FROM mimic_hosp.prescriptions 
WHERE 
    ndc IS NOT NULL;
