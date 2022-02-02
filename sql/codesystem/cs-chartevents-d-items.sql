-- Generate unique item codes for only the chartevents

SELECT 
    DISTINCT di.itemid, di.label
FROM 
	mimic_icu.chartevents ce
	LEFT JOIN mimic_icu.d_items di 
	    ON ce.itemid = di.itemid
            
