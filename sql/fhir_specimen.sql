DROP TABLE IF EXISTS mimic_fhir.specimen;
CREATE TABLE mimic_fhir.specimen(
    id          uuid PRIMARY KEY,
    patient_id  uuid NOT NULL,
    fhir        jsonb NOT NULL
);

-- Generate the microbiology specimen, just maps to base fhir Specimen resource
-- There are overlapping ids used in micro and labs but hold different info (ie with different subjects)
-- To deal with this separate namespaces will be used to differentiate micro and lab ids
WITH fhir_specimen AS (
    SELECT
        CAST(mi.micro_specimen_id AS TEXT)  AS mi_MICRO_SPECIMEN_ID
        , CAST(MAX(mi.charttime) AS TIMESTAMPTZ) AS mi_CHARTTIME
        , MAX(spec_itemid) AS mi_SPEC_ITEMID
        , MAX(spec_type_desc) AS mi_SPEC_TYPE_DESC

        , uuid_generate_v5(ns_specimen.uuid, CAST(mi.micro_specimen_id AS TEXT)) AS uuid_SPECIMEN
        , uuid_generate_v5(ns_patient.uuid, CAST(MAX(mi.subject_id) AS TEXT)) as uuid_SUBJECT_ID
    FROM
        mimic_hosp.microbiologyevents mi
        INNER JOIN fhir_etl.subjects sub
            ON mi.subject_id = sub.subject_id
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_specimen
            ON ns_specimen.name = 'SpecimenMicro'
    GROUP BY
        micro_specimen_id
        , ns_specimen.uuid
        , ns_patient.uuid
)

INSERT INTO mimic_fhir.specimen
SELECT 
    uuid_SPECIMEN  AS id
    , uuid_SUBJECT_ID AS patient_id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Specimen'
        , 'id', uuid_SPECIMEN
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-specimen'
            )
        )
        , 'identifier',   jsonb_build_array(jsonb_build_object(
            'value', mi_MICRO_SPECIMEN_ID
            , 'system', 'http://fhir.mimic.mit.edu/identifier/specimen-micro'
        ))
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'collection', jsonb_build_object(
            'collectedDateTime', mi_CHARTTIME
        )
        , 'type', CASE WHEN mi_SPEC_TYPE_DESC IS NOT NULL AND mi_SPEC_TYPE_DESC != '' THEN
            jsonb_build_object(
                'coding', jsonb_build_array(jsonb_build_object(
                    'code', mi_SPEC_ITEMID
                    , 'display', mi_SPEC_TYPE_DESC
                    , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/spec-type-desc'
                ))
            )
        ELSE NULL END
    )) AS fhir
FROM
    fhir_specimen;
