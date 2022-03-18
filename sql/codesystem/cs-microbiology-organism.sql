-- Microbiology Organism CodeSystem


DROP TABLE IF EXISTS fhir_trm.cs_microbiology_organism;
CREATE TABLE fhir_trm.cs_microbiology_organism(
    code      VARCHAR NOT NULL,
    display   VARCHAR
);

INSERT INTO fhir_trm.cs_microbiology_organism
SELECT DISTINCT org_itemid, org_name 
FROM mimic_hosp.microbiologyevents m 
WHERE org_itemid IS NOT NULL