DROP INDEX IF EXISTS labevents_idx02;
CREATE INDEX labevents_idx02
  ON mimic_hosp.labevents (specimen_id);
  
DROP INDEX IF EXISTS labevents_idx03;
CREATE INDEX labevents_idx03
  ON mimic_hosp.labevents (itemid);
  
  