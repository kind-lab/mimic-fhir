-- Descriptions for each of the CodeSystems

DROP TABLE IF EXISTS fhir_trm.cs_descriptions;
CREATE TABLE fhir_trm.cs_descriptions(
    codesystem    VARCHAR NOT NULL,
    description   VARCHAR 
);

INSERT INTO fhir_trm.cs_descriptions(codesystem, description)
VALUES  
      ('admission_class', 'The admission class for MIMIC')
    , ('admission_type', 'The admission type for MIMIC')
    , ('admission_type_icu', 'The admission type for ICU encounters in MIMIC')
    , ('admit_source', 'The admission source for MIMIC')
    , ('bodysite', 'The bodysite codes for MIMIC')
    , ('d_items', 'The item codes used throughout the ICU in MIMIC')
    , ('d_labitems', 'The lab item codes used in MIMIC')
    , ('diagnosis_icd9', 'The diagnosis ICD9 codes for MIMIC')
    , ('discharge_disposition', 'The discharge disposition for MIMIC')
    , ('identifier_type', 'The identifier type for MIMIC')
    , ('lab_flags', 'The lab alarm flags for abnormal lab events in MIMIC')
    , ('lab_fluid', 'The lab fluid that is captured for the specimen')
    , ('lab_priority', 'The priority of the lab item in MIMIC')    
    , ('medadmin_category_icu', 'The medication administration category for the ICU for MIMIC')
    , ('medication_formulary_drug_cd', 'Medication formulary drug codes for use in prescriptions and emar')
    , ('medication_icu', 'All medication found in the ICU, derived from mimic_icu.d_items')   
    , ('medication_method', 'The medication delivery method for MIMIC')
    , ('medication_method_icu', 'The medication delivery method used in the ICU for MIMIC')
    , ('medication_name', 'The standard medication name used in MIMIC. Used in pharmacy, prescriptions, and emar')
    , ('medication_ndc', 'Medication National Drug Codes (NDC) for use in prescriptions') 
    , ('medication_poe_iv', 'The IV medication that is ordered through POE')
    , ('medication_route', 'The medication route during administration for MIMIC')
    , ('medication_site', 'The medication site for administration in MIMIC')
    , ('microbiology_antibiotic', 'The microbiology antibiotic being tested on an organism in MIMIC')
    , ('microbiology_interpretation', 'The microbiology result interpretation codes in  MIMIC')
    , ('microbiology_organism', 'The microbiology organism being tested in MIMIC')
    , ('microbiology_test', 'The microbiology test completed in MIMIC')
    , ('observation_category', 'The observation category codes for MIMIC')
    , ('procedure_category', 'The procedure category codes for MIMIC')
    , ('procedure_icd9', 'The procedure ICD9 codes for MIMIC')
    , ('procedure_icd10', 'The procedure ICD10 codes for MIMIC')
    , ('spec_type_desc', 'The specimen type codes for microbiologyevents')
    , ('units', 'The units used throughout MIMIC')
