-- Lab fluid CodeSystem
-- Codes will need to be mapped to something like the Specimen type example-v2 - http://terminology.hl7.org/ValueSet/v2-0487

DROP TABLE IF EXISTS fhir_trm.cs_lab_fluid;
CREATE TABLE fhir_trm.cs_lab_fluid(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_lab_fluid
SELECT DISTINCT fluid
FROM mimiciv_hosp.d_labitems;
