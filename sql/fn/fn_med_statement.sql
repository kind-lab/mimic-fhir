CREATE OR REPLACE FUNCTION fhir_etl.fn_med_statement(med_GSN VARCHAR(60), med_NDC VARCHAR(60), med_ETC_CODES VARCHAR(255))
  RETURNS jsonb
  LANGUAGE 'plpgsql'
AS
$$
DECLARE
    fhir_extension jsonb;
BEGIN
    SELECT
        CASE WHEN (med_GSN != '0') THEN '[' END
        || CASE WHEN med_GSN != '0'
            THEN jsonb_build_object(
                        'code', med_GSN
                        , 'system', 'http://mimic.mit.edu/fhir/CodeSystem/mimic-medication-gsn'
                )::TEXT
            ELSE NULL
        END
        || CASE WHEN med_NDC != '0'
            THEN ',' || 
                jsonb_build_object(
                    'code', med_NDC
                    , 'system', 'http://hl7.org/fhir/sid/ndc'
                )::TEXT
            ELSE ''
        END
        || CASE WHEN med_ETC_CODES != '[null]'
            THEN ',' || med_ETC_CODES
            ELSE ''
        END
        || CASE WHEN (med_GSN != '0') THEN ']' END  AS output_value
    INTO fhir_extension; 
    
    RETURN fhir_extension;
END;
$$;
