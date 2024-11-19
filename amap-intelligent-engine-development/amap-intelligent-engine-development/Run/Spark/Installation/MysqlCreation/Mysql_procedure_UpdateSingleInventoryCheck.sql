CREATE PROCEDURE IF NOT EXISTS `data_activation`.`UpdateSingleInventoryCheck`(
    IN p_forecastedImpressions DECIMAL(20,2),
    IN p_countOfRecords DECIMAL(10,2),
    IN p_overwrittenImpression DECIMAL(20, 2),
    IN p_percentageOverwritten DECIMAL(10,2),
    IN p_overwrittenReason VARCHAR(255),
    IN p_useOverwrite VARCHAR(255),
    IN p_updatedBy VARCHAR(255),
    IN p_expiryDate DATETIME,
    IN p_event VARCHAR(255),
    IN p_dates LONGTEXT 
)
BEGIN      
 
      
    UPDATE api_inventorycheck ai
    SET
        ai.overwritten_impressions = CASE
            WHEN p_forecastedImpressions = 0 THEN ((1 / p_countOfRecords) * p_overwrittenImpression)
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
    WHERE ai.event = p_event
    AND ai.date = p_dates ;
    
END;