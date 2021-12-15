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
), fhir_procedure_icu as (
	SELECT
  		pe.ordercategoryname as pe_ORDERCATEGORYNAME
  		, pe.itemid as pe_ITEMID
  		, pe.starttime as pe_STARTTIME
  		, pe.endtime as pe_ENDTIME
  		, pe.storetime as pe_STORETIME
  		, pe.location as pe_LOCATION
  		, di.label as di_LABEL
  
  		-- refernce uuids
  		, uuid_generate_v5(uuid_procedure_icu, 
                           pe.stay_id || '-' || pe.orderid || '-' || pe.itemid) as uuid_PROCEDUREEVENT
  		, uuid_generate_v5(uuid_patient, pe.subject_id::text) as uuid_SUBJECT_ID
  		, uuid_generate_v5(uuid_encounter_icu, pe.stay_id::text) as uuid_STAY_ID
  	FROM
  		mimic_icu.procedureevents pe
  		LEFT JOIN mimic_icu.d_items di
  			ON pe.itemid = di.itemid
  		LEFT JOIN vars ON true
)

INSERT INTO mimic_fhir.procedure_icu
SELECT 
	uuid_PROCEDUREEVENT as id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Procedure'
        , 'id', uuid_PROCEDUREEVENT	 
        , 'status', 'completed'
      	, 'category', jsonb_build_array(jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://fhir.mimic.mit.edu/CodeSystem/observation-category'  
                , 'code', pe_ORDERCATEGORYNAME
            ))
          ))
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
     )) as fhir 
FROM
	fhir_procedure_icu
    WHERE pe_LOCATION IS NOT NULL
LIMIT 10
