-- Generate unique item codes for only the chartevents

SELECT 
    DISTINCT di.itemid, di.label
FROM 
    mimic_icu.datetimeevents dt
    LEFT JOIN mimic_icu.d_items di 
        ON dt.itemid = di.itemid
            
