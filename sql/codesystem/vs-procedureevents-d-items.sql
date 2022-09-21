-- Generate unique item codes for only the procedureevents
-- This is pulled from the d-items CodeSystem


DROP TABLE IF EXISTS fhir_trm.vs_procedureevents_d_items;
CREATE TABLE fhir_trm.vs_procedureevents_d_items(
    system    VARCHAR NOT NULL, 
    code      VARCHAR NOT NULL,
    display   VARCHAR
);

INSERT INTO fhir_trm.vs_procedureevents_d_items
SELECT DISTINCT 
    'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-d-items' AS system
    , itemid AS code
    , label AS display
FROM mimic_icu.d_items 
WHERE linksto = 'procedureevents'
            
