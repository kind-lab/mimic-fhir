-- Create Medication resources from the prescriptions table based on ndc. 
-- Pulling in only gsn values if the ndc is not present. NDC is the primary identifier

WITH prescriptions_ndc AS (
    SELECT DISTINCT 
        pr.ndc AS pr_NDC
        , pr.gsn AS pr_GSN
        , pr.drug AS pr_DRUG
        , pr.formulary_drug_cd AS pr_FORMULARY_DRUG_CD        
        , uuid_generate_v5(ns_medication.uuid, CONCAT(pr.ndc,'-', pr.gsn,'-',pr.formulary_drug_cd, '-', pr.drug)) AS med_UUID        
    FROM 
        mimic_hosp.prescriptions pr
        LEFT JOIN fhir_etl.uuid_namespace ns_medication
            ON ns_medication.name = 'MedicationNDC'
)
--INSERT INTO mimic_fhir.medication
SELECT 
    med_UUID AS id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Medication'
        , 'id', med_UUID
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication'
            )
        ) 
        , 'identifier', fn_build_medication_identifier(pr_NDC,pr_GSN,pr_FORMULARY_DRUG_CD, pr_DRUG)
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(
                fn_prescriptions_medication_code(pr_NDC, pr_GSN, pr_FORMULARY_DRUG_CD, pr_DRUG)
            )
        )   
    )) AS fhir 
FROM
    prescriptions_ndc
    