-- Create Medication resources from the prescriptions table. 
-- Set code based on the ordering below
--    1) NDC
--    2) formulary_drug_cd
--    3) drug
-- Grab the code if present, and move on to the next in the list if not
-- Notes:
--    Created distinct medication for every combination of drug, formulary_drug_cd, and ndc 
--    because we want to store the additional information. But we also don't want to assign 
--    values that are not true. Ie a NDC can link to multiple formulary_drug_cd, so can't just create one ndc med

DROP TABLE IF EXISTS mimic_fhir.medication;
CREATE TABLE mimic_fhir.medication(
    id      uuid PRIMARY KEY,
    fhir    jsonb NOT NULL 
);


WITH prescriptions_med AS (
    SELECT DISTINCT 
        CASE WHEN pr.ndc ='' OR pr.ndc ='0' THEN NULL ELSE pr.ndc END AS pr_NDC
        , pr.drug AS pr_DRUG
        , CASE WHEN pr.formulary_drug_cd = '' THEN NULL 
               ELSE pr.formulary_drug_cd 
        END AS pr_FORMULARY_DRUG_CD    
        , uuid_generate_v5(ns_medication.uuid, 
            drug
            || CASE WHEN (formulary_drug_cd IS NOT NULL) AND (formulary_drug_cd != '') 
                    THEN '--' || formulary_drug_cd ELSE '' END    
            || CASE WHEN (ndc IS NOT NULL) AND (ndc !='0') AND (ndc != '') 
                    THEN '--' || ndc ELSE '' END            
        ) AS med_UUID        
    FROM 
        mimic_hosp.prescriptions pr
        LEFT JOIN fhir_etl.uuid_namespace ns_medication
            ON ns_medication.name = 'MedicationPrescriptions'
)
INSERT INTO mimic_fhir.medication
SELECT 
    med_UUID AS id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Medication'
        , 'id', med_UUID
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://mimic.mit.edu/fhir/StructureDefinition/mimic-medication'
            )
        ) 
        , 'status', 'active'
        , 'identifier', fhir_etl.fn_build_medication_identifier(pr_NDC,pr_FORMULARY_DRUG_CD, pr_DRUG)
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(
                fhir_etl.fn_prescriptions_medication_code(pr_NDC, pr_FORMULARY_DRUG_CD, pr_DRUG)
            )
        )   
    )) AS fhir 
FROM
    prescriptions_med
    