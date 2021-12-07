DROP TABLE IF EXISTS mimic_fhir.organization;
CREATE TABLE mimic_fhir.organization(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

INSERT INTO mimic_fhir.organization
SELECT 
	uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'Organization'), 'MIMIC Hospital') as id
	, jsonb_build_object(
      	'resourceType', 'Organization',
        'identifier', jsonb_build_array(json_build_object(
          	'system', 'fhir.mimic-iv.ca/Organization/',
            'value', 'hospital'
         )),
         'type', jsonb_build_array(jsonb_build_object(
           	'coding', jsonb_build_array(jsonb_build_object(
               'system', 'http://terminology.hl7.org/CodeSystem/organization-type',
               'code', 'prov',
               'display', 'Healthcare Provider'
            ))
         )), 
         'name', 'MIMIC Hospital',
         'id', uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'Organization'), 'MIMIC Hospital')
      ) as fhir
 