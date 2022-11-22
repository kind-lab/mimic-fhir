-- HCPCS CodeSystem
-- Codes will need to be mapped to Snomed-CT: http://snomed.info/sct, 
-- based on the US Core Encounter Type valueset: http://hl7.org/fhir/us/core/ValueSet-us-core-encounter-type.html

DROP TABLE IF EXISTS fhir_trm.cs_hcpcs_cd;
CREATE TABLE fhir_trm.cs_hcpcs_cd(
    code      VARCHAR NOT NULL,
    display   VARCHAR NOT NULL 
);

INSERT INTO fhir_trm.cs_hcpcs_cd 
SELECT DISTINCT  
    hcpcs_cd AS code
    , short_description AS display
FROM mimiciv_hosp.hcpcsevents  
WHERE hcpcs_cd IS NOT NULL;
