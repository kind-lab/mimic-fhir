-- Discharge disposition CodeSystem
-- Codes will need to be mapped to match DischargeDisposition- http://hl7.org/fhir/R4/valueset-encounter-discharge-disposition.html

DROP TABLE IF EXISTS fhir_trm.cs_discharge_disposition;
CREATE TABLE fhir_trm.cs_discharge_disposition(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_discharge_disposition
SELECT DISTINCT discharge_location  
FROM mimic_hosp.admissions
WHERE discharge_location IS NOT NULL
