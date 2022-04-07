-- Create Medication resources from the prescriptions table based on gsn. 
-- Pulling in only gsn values if the ndc is not present

WITH prescriptions_gsn AS (
    SELECT DISTINCT 
        NULL AS pr_NDC
        , pr.gsn AS pr_GSN
        , pr.drug AS pr_DRUG
        , pr.formulary_drug_cd AS pr_FORMULARY_DRUG_CD        
        , uuid_generate_v5(ns_medication.uuid, pr.gsn) AS gsn_UUID        
    FROM 
        mimic_hosp.prescriptions pr
        LEFT JOIN fhir_etl.uuid_namespace ns_medication
            ON ns_medication.name  = 'MedicationGSN'
    WHERE
        (pr.ndc IS NULL OR pr.ndc = '0' OR pr.ndc = '') -- WHEN ndc IS NOT present
        AND gsn IS NOT NULL 
        AND gsn != ''
)
INSERT INTO mimic_fhir.medication
SELECT 
    gsn_UUID AS id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Medication'
        , 'id', gsn_UUID
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication'
            )
        ) 
        , 'identifier', fn_build_medication_identifier(pr_NDC,pr_GSN,pr_FORMULARY_DRUG_CD, pr_DRUG)
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-gsn'  
                , 'code', pr_GSN
            ))
        )   
    )) AS fhir 
FROM
    prescriptions_gsn