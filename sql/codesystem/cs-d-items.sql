-- Generate codesystem for icu item codes
-- Will be referenced by chartevents, datetimeevents, and outputevents

SELECT DISTINCT itemid, label FROM mimic_icu.d_items di 