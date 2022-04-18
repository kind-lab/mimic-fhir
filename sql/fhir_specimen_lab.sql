DROP TABLE IF EXISTS mimic_fhir.specimen_lab;
CREATE TABLE mimic_fhir.specimen_lab(
    id          uuid PRIMARY KEY,
    patient_id  uuid NOT NULL,
    fhir        jsonb NOT NULL 
);

-- Lab specimen
WITH fhir_specimen_lab AS (
    SELECT 
        CAST(lab.specimen_id AS TEXT) AS lab_SPECIMEN_ID
        , CAST(MAX(lab.charttime) AS TIMESTAMPTZ) AS lab_CHARTTIME
        , MAX(dlab.fluid) AS dlab_FLUID

        , uuid_generate_v5(ns_specimen.uuid, CAST(lab.specimen_id AS TEXT)) AS uuid_SPECIMEN
        , uuid_generate_v5(ns_patient.uuid, CAST(MAX(lab.subject_id) AS TEXT)) as uuid_SUBJECT_ID 
    FROM 
        mimic_hosp.labevents lab
        INNER JOIN fhir_etl.subjects sub
            ON lab.subject_id = sub.subject_id 
        LEFT JOIN mimic_hosp.d_labitems dlab 
            ON lab.itemid = dlab.itemid
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_specimen
            ON ns_specimen.name = 'SpecimenLab'
    GROUP BY 
        specimen_id 
        , ns_specimen.uuid
        , ns_patient.uuid
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
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-specimen'
            )
        ) 
        , 'identifier',   jsonb_build_array(jsonb_build_object(
            'value', lab_SPECIMEN_ID
            , 'system', 'http://fhir.mimic.mit.edu/identifier/specimen-lab'
        ))      
        , 'type', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'code', dlab_FLUID
                , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/lab-fluid'
            ))
        )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'collection', jsonb_build_object(
            'collectedDateTime', lab_CHARTTIME
        ) 
    )) AS fhir
FROM
    fhir_specimen_lab;
