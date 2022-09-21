-- Purpose: Generate a FHIR Location resource for each distinct careunit in transfers
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.location;
CREATE TABLE mimic_fhir.location(
    id          uuid PRIMARY KEY,
    fhir        jsonb NOT NULL 
);

WITH fhir_location AS (
    SELECT DISTINCT 
        careunit AS tfr_CAREUNIT
        , uuid_generate_v5(ns_location.uuid, careunit) AS uuid_CAREUNIT 
        , uuid_generate_v5(ns_organization.uuid, 'http://hl7.org/fhir/sid/us-npi/1194052720') AS bidmc_UUID
    FROM
        mimic_hosp.transfers tfr
        LEFT JOIN fhir_etl.uuid_namespace ns_location
            ON ns_location.name = 'Location'
        LEFT JOIN fhir_etl.uuid_namespace ns_organization
            ON ns_organization.name = 'Organization'
    WHERE careunit IS NOT NULL 
)
INSERT INTO mimic_fhir.location
SELECT 
    uuid_CAREUNIT as id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Location'
        , 'id', uuid_CAREUNIT
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-location'
            )
        ) 
        , 'name', tfr_CAREUNIT
        , 'physicalType', jsonb_build_object(
            'coding', jsonb_build_array(json_build_object(
                'system', 'http://terminology.hl7.org/CodeSystem/location-physical-type'
                , 'code', 'wa'
                , 'display', 'Ward'
            ))
        )
        , 'status', 'active'
        , 'managingOrganization', jsonb_build_object('reference', 'Organization/' || bidmc_UUID)
    )) as fhir
FROM 
    fhir_location
