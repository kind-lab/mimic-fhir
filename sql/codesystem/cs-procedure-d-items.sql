-- Generate unique item codes for only the procedureevents

SELECT 
    DISTINCT di.itemid, di.label
FROM 
    mimic_icu.procedureevents pe
    LEFT JOIN mimic_icu.d_items di 
        ON pe.itemid = di.itemid
            
