-- Lab fluid CodeSystem
-- Codes will need to be mapped to something like the Specimen type example-v2 - http://hl7.org/fhir/v2/0487/index.html

DROP TABLE IF EXISTS fhir_trm.cs_lab_fluid;
CREATE TABLE fhir_trm.cs_lab_fluid(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_lab_fluid 
SELECT DISTINCT fluid 
FROM mimic_hosp.d_labitems;
