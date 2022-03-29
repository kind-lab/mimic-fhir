-- Descriptions for each of the ValueSets

DROP TABLE IF EXISTS fhir_trm.vs_descriptions;
CREATE TABLE fhir_trm.vs_descriptions(
    valueset      VARCHAR NOT NULL,
    description   VARCHAR
);

INSERT INTO fhir_trm.vs_descriptions(valueset, description)
VALUES
  ('admission_class', 'The admission class for MIMIC')
    , ('admission_type', 'The admission type for MIMIC')
    , ('admission_type_icu', 'The admission type for ICU encounters in MIMIC')
    , ('admit_source', 'The admission source for MIMIC')
    , ('bodysite', 'The bodysite codes for MIMIC')
    , ('chartevents_d_items', 'The item codes for chartevents used in MIMIC')   
    , ('d_items', 'The item codes used throughout the ICU in MIMIC')
    , ('d_labitems', 'The lab item codes used in MIMIC')
    , ('datetimeevents_d_items', 'The datetime item codes used in MIMIC')
    , ('diagnosis_icd', 'The diagnosis ICD9 and ICD10 codes for MIMIC')
    , ('discharge_disposition', 'The discharge disposition for MIMIC')
    , ('identifier_type', 'The identifier type for MIMIC')
    , ('lab_flags', 'The lab alarm flags for abnormal lab events in MIMIC')
    , ('lab_priority', 'The priority of the lab item in MIMIC')   
    , ('medadmin_category_icu', 'The medication administration category for the ICU for MIMIC')
    , ('medication_method', 'The medication delivery method for MIMIC')
    , ('medication_route', 'The medication route during administration for MIMIC')
    , ('medication_site', 'The medication site for administration in MIMIC')
    , ('microbiology_antibiotic', 'The microbiology antibiotic being tested on an organism in MIMIC')
    , ('microbiology_interpretation', 'The microbiology result interpretation codes in  MIMIC')
    , ('microbiology_organism', 'The microbiology organism being tested in MIMIC')
    , ('microbiology_test', 'The microbiology test completed in MIMIC')
    , ('observation_category', 'The observation category codes for MIMIC')
    , ('outputevents_d_items', 'The item codes for outputevents used in MIMIC')  
    , ('procedure_category', 'The procedure category codes for MIMIC')
    , ('procedure_icd', 'The procedure ICD9 and ICD10 codes for MIMIC')
    , ('procedureevents_d_items', 'The procedure item codes used in the ICU for MIMIC')
    , ('units', 'The units used throughout MIMIC')
