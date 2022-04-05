-- Medication name CodeSystem
-- Medication names from the pharmacy and prescriptions table, used when no other identifier is available

DROP TABLE IF EXISTS fhir_trm.cs_medication_name;
CREATE TABLE fhir_trm.cs_medication_name(
    code      VARCHAR NOT NULL
);

WITH medication_name AS (
    -- prescription names are fully captured in pharmacy currently, but keeping incase this changes in future
    SELECT DISTINCT TRIM(REGEXP_REPLACE(drug, '\s+', ' ', 'g')) AS code 
    FROM mimic_hosp.prescriptions 
    WHERE formulary_drug_cd IS NULL
    
    UNION    
    
    SELECT DISTINCT TRIM(REGEXP_REPLACE(medication, '\s+', ' ', 'g')) AS  code 
    FROM mimic_hosp.pharmacy
    
    UNION 
    
    SELECT 
        DISTINCT TRIM(REGEXP_REPLACE(medication, '\s+', ' ', 'g')) AS code
    FROM 
        mimic_hosp.emar_detail emd 
        LEFT JOIN mimic_hosp.emar em
            ON emd.emar_id = em.emar_id
    WHERE 
        emd.product_code IS NULL
)

INSERT INTO fhir_trm.cs_medication_name
SELECT code
FROM medication_name
WHERE 
    code IS NOT NULL 
    AND code != ''

