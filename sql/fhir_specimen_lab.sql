SELECT fhir_etl.fn_create_table_patient_dependent('specimen_lab');

-- Lab specimen
WITH lab AS (
    SELECT 
        lab.specimen_id
        , MAX(lab.itemid) AS itemid
        , MAX(lab.subject_id) AS subject_id
        , MAX(lab.charttime) AS charttime
    FROM 
        mimic_hosp.labevents lab  
    GROUP BY
        specimen_id        
)
, fhir_specimen_lab AS (
    SELECT
        CAST(lab.specimen_id AS TEXT) AS lab_SPECIMEN_ID
        , CAST(lab.charttime AS TIMESTAMPTZ) AS lab_CHARTTIME
        , dlab.fluid AS dlab_FLUID

        , uuid_generate_v5(ns_specimen.uuid, CAST(lab.specimen_id AS TEXT)) AS uuid_SPECIMEN
        , uuid_generate_v5(ns_patient.uuid, CAST(lab.subject_id AS TEXT)) as uuid_SUBJECT_ID
    FROM 
        lab
        LEFT JOIN mimic_hosp.d_labitems dlab
            ON lab.itemid = dlab.itemid
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_specimen
            ON ns_specimen.name = 'SpecimenLab'
    
)  
  
INSERT INTO mimic_fhir.specimen_lab
SELECT 
    uuid_SPECIMEN  AS id
    , uuid_SUBJECT_ID AS patient_id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Specimen'
        , 'id', uuid_SPECIMEN
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-specimen'
            )
        )
        , 'identifier',   jsonb_build_array(jsonb_build_object(
            'value', lab_SPECIMEN_ID
            , 'system', 'http://mimic.mit.edu/fhir/mimic/identifier/specimen-lab'
        ))
        , 'type', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'code', dlab_FLUID
                , 'system', 'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-lab-fluid'
            ))
        )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'collection', jsonb_build_object(
            'collectedDateTime', lab_CHARTTIME
        ) 
    )) AS fhir
FROM
    fhir_specimen_lab;
