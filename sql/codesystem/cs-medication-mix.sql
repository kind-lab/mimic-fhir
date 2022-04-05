-- Medication mixes CodeSystem
-- Prescriptions with multiple medications needed to be mapped to one medication to fit in fhir

DROP TABLE IF EXISTS fhir_trm.cs_medication_mix;
CREATE TABLE fhir_trm.cs_medication_mix(
    code      VARCHAR NOT NULL
);

WITH medication_mix AS (
    SELECT DISTINCT 
        -- format of medication mixes will be MAIN-BASE-ADDITIVE if all drug_types are present
        -- Multiple additives are allowed, so these are ordered alphabetically 
        STRING_AGG(
            TRIM(REGEXP_REPLACE(formulary_drug_cd , '\s+', ' ', 'g'))
            , '_' ORDER BY drug_type DESC, formulary_drug_cd ASC
        ) AS code  
    FROM 
        mimic_hosp.prescriptions 
    GROUP BY 
        pharmacy_id 
    HAVING 
        COUNT(formulary_drug_cd) > 1
)

INSERT INTO fhir_trm.cs_medication_mix
SELECT code
FROM medication_mix
WHERE code IS NOT NULL 