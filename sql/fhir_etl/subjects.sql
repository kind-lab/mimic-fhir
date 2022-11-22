DROP TABLE IF EXISTS fhir_etl.subjects;
CREATE TABLE fhir_etl.subjects(
  	subject_id INT NOT NULL
);


INSERT INTO fhir_etl.subjects(subject_id)
SELECT   
    pat.subject_id
FROM  
    mimiciv_hosp.patients pat
    INNER JOIN mimiciv_icu.icustays ie 
        ON pat.subject_id = ie.subject_id
WHERE  
    anchor_age > 0
    AND anchor_year_group IN ('2011 - 2013', '2014 - 2016')
GROUP BY 
    pat.subject_id
ORDER BY 
    pat.subject_id
LIMIT 100;
