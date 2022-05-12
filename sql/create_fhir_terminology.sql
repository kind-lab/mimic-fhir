-- Generate all terminology tables
-- These tables will be used to generate CodeSystems/ValueSets in FHIR
DROP SCHEMA IF EXISTS fhir_trm CASCADE;
CREATE SCHEMA IF NOT EXISTS fhir_trm;

-- Encounter CodeSystems
\echo =========================== fhir_trm CodeSystems ====================================
\echo Admission Class
\i codesystem/cs-admission-class.sql

\echo Admission Type
\i codesystem/cs-admission-type.sql

\echo Admission Type ICU
\i codesystem/cs-admission-type-icu.sql

\echo Admit Source
\i codesystem/cs-admit-source.sql

\echo Discharge Disposition
\i codesystem/cs-discharge-disposition.sql

-- Lab CodeSystems
\echo Lab Flags
\i codesystem/cs-lab-flags.sql

\echo D Lab Items
\i codesystem/cs-d-labitems.sql

\echo Lab Fluid
\i codesystem/cs-lab-fluid.sql

\echo Lab Priority
\i codesystem/cs-lab-priority.sql

-- Medication CodeSystems
\echo Medication ICU
\i codesystem/cs-medication-icu.sql

\echo Medication Formulary Drug Cd
\i codesystem/cs-medication-formulary-drug-cd.sql

\echo Medication Mix
\i codesystem/cs-medication-mix.sql

\echo Medication Name
\i codesystem/cs-medication-name.sql

\echo Medication NDC
\i codesystem/cs-medication-ndc.sql

\echo Medication POE IV
\i codesystem/cs-medication-poe-iv.sql

-- Medication Related CodeSystems
\echo Medadmin Category ICU
\i codesystem/cs-medadmin-category-icu.sql

\echo Medication Method
\i codesystem/cs-medication-method.sql

\echo Medication Method ICU
\i codesystem/cs-medication-method-icu.sql

\echo Medication Route
\i codesystem/cs-medication-route.sql

\echo Medication Site
\i codesystem/cs-medication-site.sql

\echo BodySite
\i codesystem/cs-bodysite.sql

\echo Identifier Type
\i codesystem/cs-identifier-type.sql


-- Microbiology CodeSystems
\echo Microbiology Antibiotic
\i codesystem/cs-microbiology-antibiotic.sql

\echo Microbiology Interpretation
\i codesystem/cs-microbiology-interpretation.sql

\echo Microbiology Organism
\i codesystem/cs-microbiology-organism.sql

\echo Microbiology Test
\i codesystem/cs-microbiology-test.sql

\echo Specimen Type Desc
\i codeystem/cs-spec-type-desc.sql


-- ICD CodeSystems procedure/diagnosis
\echo Diagnosis ICD9
\i codesystem/cs-diagnosis-icd9.sql

\echo Procedure ICD9
\i codesystem/cs-procedure-icd9.sql

\echo Procedure ICD10
\i codesystem/cs-procedure-icd10.sql

\echo Procedure Category
\i codesystem/cs-procedure-category.sql


-- ICU CodeSystems
\echo D Items
\i codesystem/cs-d-items.sql

-- create separate chartevents since it won't load properly from valueset in hapi
\echo Chartevents D Items
\i codesystem/cs-chartevents-d-items.sql


-- General CodeSystems
\echo Observation Category
\i codesystem/cs-observation-category.sql

\echo Units
\i codesystem/cs-units.sql


-- ValueSets
\echo =========================== fhir_trm ValueSets ===================================

\echo Datetimeevents D Items
\i codesystem/vs-datetimeevents-d-items.sql

\echo Outputevents D Items
\i codesystem/vs-outputevents-d-items.sql

\echo Procedureevents D Items
\i codesystem/vs-procedureevents-d-items.sql

-- Medication
\echo Medication ValueSet
\i codesystem/vs-medication.sql

--Specimen
\echo Specimen Type 
\i codesystem/vs-specimen-type.sql

-- ICD Valuesets
\echo Diagnosis ICD
\i codesystem/vs-diagnosis-icd.sql

\echo Procedure ICD
\i codesystem/vs-procedure-icd.sql


-- Terminology Descriptions
\echo CodeSystem Descriptions
\i codesystem/cs-descriptions.sql

\echo ValueSet Descriptions
\i codesystem/vs-descriptions.sql
