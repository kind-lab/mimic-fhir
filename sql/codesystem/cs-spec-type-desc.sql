-- Specimen type labs CodeSystem
-- Codes will need to be mapped to something like the Specimen type example-v2 - http://hl7.org/fhir/v2/0487/index.html

DROP TABLE IF EXISTS fhir_trm.cs_spec_type_desc;
CREATE TABLE fhir_trm.cs_spec_type_desc(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_spec_type_desc
SELECT DISTINCT spec_type_desc
FROM mimic_hosp.microbiologyevents
WHERE spec_type_desc != '';
