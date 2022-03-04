-- Generate unique item codes for only the chartevents

SELECT 
    DISTINCT ce.itemid, di.label
FROM 
    mimic_icu.chartevents ce
    INNER JOIN mimic_icu.d_items di 
        ON ce.itemid = di.itemid
            
