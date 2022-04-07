-- Medication formulary drug codes CodeSystem
-- Codes will need to be mapped in future to a standard medication system (ie using rxnorm)

WITH formulary_drug_cd AS (
    -- prescription names are fully captured in pharmacy currently, but keeping incase this changes in future
    SELECT DISTINCT formulary_drug_cd AS code FROM mimic_hosp.prescriptions p     
    UNION    
    SELECT DISTINCT product_code AS  code FROM mimic_hosp.emar_detail ed 
), fhir_medication_name AS (
    SELECT
        fdc.code AS fdc_CODE
        , uuid_generate_v5(ns_medication.uuid, fdc.code) AS code_UUID        
    FROM 
        formulary_drug_cd fdc
        LEFT JOIN fhir_etl.uuid_namespace ns_medication
            ON ns_medication.name = 'MedicationFormularyDrugCd'
    WHERE fdc.code IS NOT NULL 
) 
INSERT INTO mimic_fhir.medication
SELECT 
    code_UUID AS id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Medication'
        , 'id', code_UUID
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication'
            )
        ) 
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-formulary-drug-cd'  
                , 'code', code_UUID
            ))
        )   
    )) AS fhir 
FROM
    fhir_medication_name;

