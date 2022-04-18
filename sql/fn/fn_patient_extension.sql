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
			  'extension', jsonb_build_array(
                	jsonb_build_object(
                        'url', 'ombCategory',
                        'valueCoding', jsonb_build_object(
                            'code', map_race.fhir_race_omb_code,
                            'display', map_race.fhir_race_omb_display,
                            'system', map_race.fhir_system
                         )
                    ),
                    jsonb_build_object(
                    	'url', 'text',
                      	'valueString', map_race.fhir_race_omb_display
                      	
                    )                    
			)	
			, 'url', 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race' )::text
            ELSE '' 
         END 
         || CASE WHEN race is not null and ethnicity is not null THEN ',' ELSE '' END
         || CASE WHEN ethnicity is not NULL 
        	THEN jsonb_build_object(
			  'extension', jsonb_build_array(
                	jsonb_build_object(
                      'url', 'ombCategory',
                      'valueCoding', jsonb_build_object(
                          'code', map_eth.fhir_ethnicity_code,
                          'display', map_eth.fhir_ethnicity_display,
                          'system', map_eth.fhir_system
                        )
                    ),
                	jsonb_build_object(
                    	 'url', 'text',
                      	 'valueString', map_eth.fhir_ethnicity_display
                    )
			)	
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
        
		
    INTO fhir_extension
    FROM 
        fhir_etl.map_ethnicity map_eth
        LEFT JOIN fhir_etl.map_race_omb map_race
            ON map_race.mimic_race = race        
    WHERE map_eth.mimic_ethnicity = ethnicity
    
    ;   
    
    
    return fhir_extension;
end;
$$;
