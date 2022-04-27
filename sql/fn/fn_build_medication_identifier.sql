CREATE OR REPLACE FUNCTION fhir_etl.fn_build_medication_identifier(ndc VARCHAR(25), gsn_string VARCHAR(255), formulary_drug_cd VARCHAR(120), drug VARCHAR(255))
  returns jsonb
  language 'plpgsql'
as
$$
declare
    medication_identifier jsonb;
begin
    SELECT  
       '['                                                                          
        || CASE WHEN ndc IS NOT NULL AND ndc != '0' AND ndc != ''
            THEN jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-ndc'
                , 'value', ndc
            )::text
            ELSE '' 
        END 
        || CASE WHEN (ndc IS NOT NULL AND ndc != '0' AND ndc != '') AND (MIN(gsn.code) IS NOT NULL AND MIN(gsn.code) != '') 
                THEN ',' ELSE '' END
        || CASE WHEN MIN(gsn.code) IS NOT NULL OR MIN(gsn.code) != '' THEN 
            string_agg(jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-gsn'
                , 'value', gsn.code
            )::TEXT, ',')
        ELSE '' END
        || CASE WHEN ((ndc IS NOT NULL AND ndc != '0' AND ndc != '') OR (MIN(gsn.code) IS NOT NULL AND MIN(gsn.code) != '')) 
                       AND (formulary_drug_cd IS NOT NULL AND formulary_drug_cd != '') 
                THEN ',' ELSE '' END
        || CASE WHEN formulary_drug_cd IS NOT NULL AND formulary_drug_cd != ''
            THEN jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-formulary-drug-cd'
                , 'value', formulary_drug_cd
            )::text
            ELSE '' 
        END 
        || CASE WHEN ((ndc IS NOT NULL AND ndc != '0' AND ndc != '') 
                        OR (MIN(gsn.code) IS NOT NULL AND MIN(gsn.code) != '') 
                        OR (formulary_drug_cd IS NOT NULL AND formulary_drug_cd != ''))
                        AND drug != ''
                THEN ',' ELSE '' END
        -- drug name is never NULL, so just set the name here
        || CASE WHEN drug != ''  
            THEN jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-name'
                , 'value', drug
            )::TEXT
           ELSE ''
        END
    
        || ']' AS output_value      
        
    INTO medication_identifier
    FROM 
        (SELECT '') t1--ensure at least one row is returned. 
        --LATERAL JOIN needed for gsn, but can't be only table or when gsn is missing nothing is returned
        LEFT JOIN LATERAL UNNEST(STRING_TO_ARRAY(TRIM(gsn_string),' ')) gsn(code)
            ON gsn_string IS NOT NULL AND gsn_string != ''
    GROUP BY
        ndc 
        , formulary_drug_cd
        , drug;       
    
    return medication_identifier;
end;
$$;
