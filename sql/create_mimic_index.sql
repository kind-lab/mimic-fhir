DROP INDEX IF EXISTS labevents_idx02;
CREATE INDEX labevents_idx02
  ON mimic_hosp.labevents (specimen_id);
  
DROP INDEX IF EXISTS labevents_idx03;
CREATE INDEX labevents_idx03
  ON mimic_hosp.labevents (itemid);
  
DROP INDEX IF EXISTS d_labitems_idx01;
CREATE INDEX d_labitems_idx01
  ON mimic_hosp.d_labitems (itemid);
  
DROP INDEX IF EXISTS pharmacy_idx01;
CREATE INDEX pharmacy_idx01
  ON mimic_hosp.pharmacy (pharmacy_id);
  
  
DROP INDEX IF EXISTS prescriptions_idx01;
CREATE INDEX prescriptions_idx01
  ON mimic_hosp.prescriptions (pharmacy_id);
  
  
DROP INDEX IF EXISTS emar_idx01;
CREATE INDEX emar_idx01
  ON mimic_hosp.emar (pharmacy_id);
  
DROP INDEX IF EXISTS emar_idx02;
CREATE INDEX emar_idx02
  ON mimic_hosp.emar (poe_id);
  
DROP INDEX IF EXISTS poe_idx01;
CREATE INDEX poe_idx01
  ON mimic_hosp.poe (poe_id);
