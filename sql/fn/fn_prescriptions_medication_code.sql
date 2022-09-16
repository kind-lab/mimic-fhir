CREATE OR REPLACE FUNCTION fhir_etl.fn_prescriptions_medication_code(ndc VARCHAR(25), formulary_drug_cd VARCHAR(120), drug VARCHAR(255))
  returns jsonb
  language 'plpgsql'
as
$$
declare
    medication_code jsonb;
begin
    SELECT CASE                                                                   
        WHEN ndc IS NOT NULL AND ndc != '0' AND ndc != '' THEN
            jsonb_build_object(
                'system', 'http://mimic.mit.edu/fhir/CodeSystem/mimic-medication-ndc'  
                , 'code', ndc
            )::TEXT
        WHEN formulary_drug_cd IS NOT NULL AND formulary_drug_cd != '' THEN
            jsonb_build_object(
                'system', 'http://mimic.mit.edu/fhir/CodeSystem/mimic-medication-formulary-drug-cd'  
                , 'code', TRIM(REGEXP_REPLACE(formulary_drug_cd , '\s+', ' ', 'g'))
            )::TEXT
        ELSE
            jsonb_build_object(
                'system', 'http://mimic.mit.edu/fhir/CodeSystem/mimic-medication-name'  
                , 'code', TRIM(REGEXP_REPLACE(drug, '\s+', ' ', 'g'))
            )::TEXT
        END AS output_value      
        
        
    INTO medication_code;   
    
    
    return medication_code;
end;
$$;
