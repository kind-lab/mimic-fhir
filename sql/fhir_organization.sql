DROP TABLE IF EXISTS mimic_fhir.organization;
CREATE TABLE mimic_fhir.organization(
   id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

INSERT INTO mimic_fhir.organization
SELECT 
   uuid_generate_v5(ns_organization.uuid, 'Beth Israel Deaconess Medical Center') AS id
	, jsonb_build_object(
      	'resourceType', 'Organization',
        'identifier', jsonb_build_array(json_build_object(
          	'system', 'http://hl7.org/fhir/sid/us-npi',
            'value', '1194052720'
         )),
         'type', jsonb_build_array(jsonb_build_object(
           	'coding', jsonb_build_array(jsonb_build_object(
               'system', 'http://terminology.hl7.org/CodeSystem/organization-type',
               'code', 'prov',
               'display', 'Healthcare Provider'
            ))
         )), 
         'name', 'Beth Israel Deaconess Medical Center',
         'id', uuid_generate_v5(ns_organization.uuid, 'http://hl7.org/fhir/sid/us-npi/1194052720')
   ) AS fhir
FROM fhir_etl.uuid_namespace ns_organization 
WHERE name = 'Organization'
 