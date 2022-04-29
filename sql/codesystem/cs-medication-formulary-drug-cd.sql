-- Medication formulary drug codes CodeSystem
-- Codes will need to be mapped in future to a standard medication system (ie using rxnorm)

DROP TABLE IF EXISTS fhir_trm.cs_medication_formulary_drug_cd;
CREATE TABLE fhir_trm.cs_medication_formulary_drug_cd(
    code      VARCHAR NOT NULL
);

WITH formulary_drug_cd AS (
    SELECT DISTINCT formulary_drug_cd AS code FROM mimic_hosp.prescriptions p     
    UNION    
    SELECT DISTINCT product_code AS  code FROM mimic_hosp.emar_detail ed 
)
INSERT INTO fhir_trm.cs_medication_formulary_drug_cd 
SELECT code
FROM formulary_drug_cd
WHERE 
    code IS NOT NULL 
    AND code != ''
