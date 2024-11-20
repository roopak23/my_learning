SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED


UPDATE api_inventorycheck 
SET use_overwrite = 'N',
    Updated_By = Null
where DATE(overwritten_expiry_date) <= CURRENT_DATE()
  and use_overwrite = 'Y';
