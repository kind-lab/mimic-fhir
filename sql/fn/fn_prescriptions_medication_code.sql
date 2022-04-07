CREATE OR REPLACE FUNCTION fn_prescriptions_medication_code(ndc VARCHAR(25), gsn VARCHAR(255), formulary_drug_cd VARCHAR(120), drug VARCHAR(255))
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
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-ndc'  
                , 'code', ndc
            )::TEXT
        WHEN gsn IS NOT NULL AND gsn != '' THEN
            jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-gsn'  
                , 'code', gsn
            )::TEXT   
        WHEN formulary_drug_cd IS NOT NULL AND formulary_drug_cd != '' THEN
            jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-formulary-drug-cd'  
                , 'code', formulary_drug_cd
            )::TEXT
        ELSE
            jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-name'  
                , 'code', drug
            )::TEXT
        END AS output_value      
        
        
    INTO medication_code;   
    
    
    return medication_code;
end;
$$;
