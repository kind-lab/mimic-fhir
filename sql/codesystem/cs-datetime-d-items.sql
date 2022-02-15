-- Generate unique item codes for only the datetime events

SELECT 
    DISTINCT dt.itemid, di.label
FROM 
    mimic_icu.datetimeevents dt
    INNER JOIN mimic_icu.d_items di 
        ON dt.itemid = di.itemid
            
