-- Specimen type labs CodeSystem
-- Codes will need to be mapped to something like the Specimen type example-v2 - http://terminology.hl7.org/ValueSet/v2-0487

DROP TABLE IF EXISTS fhir_trm.cs_spec_type_desc;
CREATE TABLE fhir_trm.cs_spec_type_desc(
    code      VARCHAR NOT NULL,
    display   VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_spec_type_desc
SELECT DISTINCT 
    spec_itemid AS code
    , spec_type_desc AS display
FROM mimiciv_hosp.microbiologyevents
WHERE spec_type_desc != '';
