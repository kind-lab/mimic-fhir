CREATE OR REPLACE FUNCTION fn_patient_extension(race VARCHAR(30), ethnicity VARCHAR(50), birthsex VARCHAR(10))
  returns jsonb
  language 'plpgsql'
as
$$
declare
	fhir_extension jsonb;
begin
	SELECT  
    	CASE WHEN (race is not null) or (ethnicity is not null) or (birthsex is not null) THEN '[' END                                                                   		
        || CASE WHEN race is not NULL 
        	THEN jsonb_build_object(
			  'extension', jsonb_build_array(jsonb_build_object(
					'url', 'ombCategory',
              		'valueCoding', jsonb_build_object(
                      	'display', race,
                        'system', 'urn:oid:2.16.840.1.113883.6.238'
                      )
			))	
			, 'url', 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race' )::text
            ELSE '' 
         END 
         || CASE WHEN race is not null and ethnicity is not null THEN ',' ELSE '' END
         || CASE WHEN ethnicity is not NULL 
        	THEN jsonb_build_object(
			  'extension', jsonb_build_array(jsonb_build_object(
					'url', 'ombCategory',
              		'valueCoding', jsonb_build_object(
                      	'display', ethnicity,
                        'system', 'urn:oid:2.16.840.1.113883.6.238'
                      )
			))	
			, 'url', 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity' )::text 
            ELSE ''
         END  
         || CASE WHEN (race is not null or ethnicity is not null) and birthsex is not null THEN ',' ELSE '' END
         || CASE WHEN birthsex is not NULL 
        	THEN jsonb_build_object(
			  'valueCode', birthsex,	
			  'url', 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex')::text 
            ELSE ''
         END   
         || CASE WHEN (race is not null) or (ethnicity is not null) or (birthsex is not null) THEN ']' END  as output_value      
        
		
    INTO fhir_extension;   
    
    
    return fhir_extension;
end;
$$;
