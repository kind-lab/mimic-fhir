CREATE OR REPLACE FUNCTION fhir_etl.fn_patient_extension(race VARCHAR(30), ethnicity VARCHAR(50), birthsex VARCHAR(10))
  RETURNS jsonb
  LANGUAGE 'plpgsql'
AS
$$
DECLARE
    fhir_extension jsonb;
BEGIN
    SELECT
        CASE WHEN (race IS NOT NULL) OR (map_eth.fhir_ethnicity_code IS NOT NULL) OR (birthsex IS NOT NULL) THEN '[' END
        || CASE WHEN race IS NOT NULL
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
            , 'url', 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race' )::TEXT
            ELSE ''
        END
        || CASE WHEN race IS NOT NULL and map_eth.fhir_ethnicity_code IS NOT NULL THEN ',' ELSE '' END
        || CASE WHEN map_eth.fhir_ethnicity_code IS NOT NULL
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
            , 'url', 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity' )::TEXT
            ELSE ''
        END
        || CASE WHEN (race IS NOT NULL OR map_eth.fhir_ethnicity_code IS NOT NULL) AND birthsex IS NOT NULL THEN ',' ELSE '' END
        || CASE WHEN birthsex IS NOT NULL
            THEN jsonb_build_object(
                'valueCode', birthsex,
                'url', 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex')::TEXT
            ELSE ''
        END
        || CASE WHEN (race IS NOT NULL) OR (ethnicity IS NOT NULL) OR (birthsex IS NOT NULL) THEN ']' END  AS output_value
    INTO fhir_extension
    FROM
        fhir_etl.map_ethnicity map_eth
        LEFT JOIN fhir_etl.map_race_omb map_race
            ON map_race.mimic_race = race
    WHERE map_eth.mimic_ethnicity = ethnicity;      
    
    RETURN fhir_extension;
END;
$$;
