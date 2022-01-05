DROP TABLE IF EXISTS mimic_fhir.procedure_icu;
CREATE TABLE mimic_fhir.procedure_icu(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'EncounterICU') as uuid_encounter_icu
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient') as uuid_patient
 		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'ProcedureICU') as uuid_procedure_icu
), fhir_procedure_icu AS (
	SELECT
  		pe.ordercategoryname AS pe_ORDERCATEGORYNAME
  		, CAST(pe.itemid AS TEXT) AS pe_ITEMID
  		, CAST(pe.starttime AS TIMESTAMPTZ) AS pe_STARTTIME
  		, CAST(pe.endtime AS TIMESTAMPTZ) AS pe_ENDTIME
  		, pe.location AS pe_LOCATION
  		, di.label AS di_LABEL
  
  		-- refernce uuids
  		, uuid_generate_v5(uuid_procedure_icu, CONCAT_WS('-', pe.stay_id, pe.orderid, pe.itemid)) AS uuid_PROCEDUREEVENT
  		, uuid_generate_v5(uuid_patient, CAST(pe.subject_id AS TEXT)) AS uuid_SUBJECT_ID
  		, uuid_generate_v5(uuid_encounter_icu, CAST(pe.stay_id AS TEXT)) AS uuid_STAY_ID
  	FROM
  		mimic_icu.procedureevents pe
  		INNER JOIN fhir_etl.subjects sub
  			ON pe.subject_id = sub.subject_id subject_id 
  		LEFT JOIN mimic_icu.d_items di
  			ON pe.itemid = di.itemid
  		LEFT JOIN vars ON TRUE
)

INSERT INTO mimic_fhir.procedure_icu
SELECT 
	uuid_PROCEDUREEVENT AS id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Procedure'
        , 'id', uuid_PROCEDUREEVENT	 
        , 'status', 'completed'
      	, 'category', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://fhir.mimic.mit.edu/CodeSystem/observation-category'  
                , 'code', pe_ORDERCATEGORYNAME
            ))
          )
        , 'code', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://fhir.mimic.mit.edu/CodeSystem/d-items'  
                , 'code', pe_ITEMID
                , 'display', di_LABEL
            ))
          )
      	, 'bodySite', CASE WHEN pe_LOCATION IS NOT NULL THEN
      			jsonb_build_array(jsonb_build_object(
              		'coding', jsonb_build_array(jsonb_build_object(
                        'system', 'http://fhir.mimic.mit.edu/CodeSystem/bodysite'  
                        , 'code', pe_LOCATION
                  ))
                ))
      	  ELSE NULL
      	  END
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter/' || uuid_STAY_ID) 
        , 'performedPeriod', 
      			jsonb_build_object(
                  'start', pe_STARTTIME
                  , 'end', pe_ENDTIME
                )
     )) AS fhir 
FROM
	fhir_procedure_icu
