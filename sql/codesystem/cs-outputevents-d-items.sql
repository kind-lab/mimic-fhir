-- Generate unique itemid and labels for outputevents. 
-- Use values for CodeSystem outputevents-d-items

SELECT 
    DISTINCT di.itemid, di.label
FROM 
    mimic_icu.outputevents o 
    LEFT JOIN mimic_icu.d_items di 
        ON o.itemid = di.itemid 