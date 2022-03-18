-- Procedure Category Codesystem
-- Used primarily in the ICU from MIMIC
-- Need to map out to HL7 procedure-category - http://hl7.org/fhir/R4/valueset-procedure-category.html

DROP TABLE IF EXISTS fhir_trm.cs_procedure_category;
CREATE TABLE fhir_trm.cs_procedure_category(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_procedure_category
SELECT DISTINCT ordercategoryname 
FROM mimic_icu.procedureevents p 