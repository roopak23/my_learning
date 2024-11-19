CREATE  PROCEDURE IF NOT EXISTS `data_activation`.`UpdateSingleInventoryProductDateSet`(
    IN p_forecastedImpressions DECIMAL(20,2),
    IN p_countOfRecords DECIMAL(10,2),
    IN p_overwrittenImpression DECIMAL(20, 2),
    IN p_percentageOverwritten DECIMAL(10,2),
    IN p_overwrittenReason VARCHAR(255),
    IN p_useOverwrite VARCHAR(255),
    IN p_updatedBy VARCHAR(255),
    IN p_expiryDate DATETIME,
    IN p_level1 VARCHAR(255),
    IN p_level2 VARCHAR(255),
    IN p_level3 VARCHAR(255),
    IN p_level4 VARCHAR(255),
    IN p_level5 VARCHAR(255),
    IN p_dates LONGTEXT 
)
BEGIN
     UPDATE api_inventorycheck ai
    SET
        ai.overwritten_impressions = CASE
            WHEN p_forecastedImpressions = 0 THEN (1 / p_countOfRecords) * p_overwrittenImpression
            ELSE (ai.future_capacity / p_forecastedImpressions) * p_overwrittenImpression
        END,
        ai.percentage_of_overwriting = p_percentageOverwritten,
        ai.overwriting_reason = p_overwrittenReason,
        ai.use_overwrite = p_useOverwrite,
        ai.updated_by = p_updatedBy,
        ai.overwritten_expiry_date = CASE
            WHEN p_expiryDate IS NOT NULL THEN p_expiryDate
            ELSE ai.overwritten_expiry_date
        END
    WHERE EXISTS (
        SELECT 1
        FROM STG_SA_Ad_Slot s
        WHERE s.adserver_adslot_id = ai.adserver_adslot_id
          AND s.status = 'ACTIVE'
          AND (p_level1 IS NULL OR s.Level1 = p_level1)
          AND (p_level2 IS NULL OR s.Level2 = p_level2)
          AND (p_level3 IS NULL OR s.Level3 = p_level3)
          AND (p_level4 IS NULL OR s.Level4 = p_level4)
          AND (p_level5 IS NULL OR s.Level5 = p_level5)
         )
    AND  ai.date >= p_dates AND ai.date < p_dates + INTERVAL 1 DAY ;
   END;