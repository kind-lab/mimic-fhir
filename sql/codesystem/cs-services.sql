-- Services CodeSystem
-- Codes will need to be mapped to service-type valueset: http://hl7.org/fhir/R4/valueset-service-type.html 

DROP TABLE IF EXISTS fhir_trm.cs_services;
CREATE TABLE fhir_trm.cs_services(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_services 
SELECT DISTINCT curr_service
FROM mimiciv_hosp.services;
