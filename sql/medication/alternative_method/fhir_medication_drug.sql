-- Create Medication resources from the prescriptions table based on drug name. 
-- Pulling in only formulary drug codes only if the ndc, gsn, or formulary_drug_cd are not present

WITH prescriptions_drug AS (
    SELECT DISTINCT 
        NULL AS pr_NDC
        , NULL AS pr_GSN
        , NULL AS pr_FORMULARY_DRUG_CD  
        , pr.drug AS pr_DRUG              
        , uuid_generate_v5(ns_medication.uuid, pr.drug) AS drug_UUID        
    FROM 
        mimic_hosp.prescriptions pr
        LEFT JOIN fhir_etl.uuid_namespace ns_medication
            ON ns_medication.name  = 'MedicationName'
    WHERE
        (pr.ndc IS NULL OR pr.ndc = '0' OR pr.ndc = '') -- WHEN ndc IS NOT present
        AND (gsn IS NULL OR gsn = '') -- WHEN gsn IS NOT present
        AND (formulary_drug_cd IS NULL OR formulary_drug_cd = '')
)
INSERT INTO mimic_fhir.medication
SELECT 
    drug_UUID AS id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Medication'
        , 'id', drug_UUID
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication'
            )
        ) 
        , 'identifier', fn_build_medication_identifier(pr_NDC,pr_GSN,pr_FORMULARY_DRUG_CD, pr_DRUG)
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-name'  
                , 'code', pr_DRUG
            ))
        )   
    )) AS fhir 
FROM
    prescriptions_drug
    
    