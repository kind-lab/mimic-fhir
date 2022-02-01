-- Generate unique item codes for only the datetimeevents

SELECT 
    DISTINCT di.itemid, di.label
FROM 
	mimic_icu.datetimeevents de
	LEFT JOIN mimic_icu.d_items di 
	    ON de.itemid = di.itemid
            
