SET @overwritten_impression_number = #overwritten_impression_number#;
SET @level1 = #level1#;
SET @level2 = #level2#;
SET @level3 = #level3#;
SET @level4 = #level4#;
SET @level5 = #level5#;
SET @event  = #event#;
SET @startDate = #startDate#;
SET @endDate = #endDate#;
SET @Use_Overwrite = #Use_Overwrite#;
SET @Overwriting_reason = #Overwriting_reason#;

SET @randomNumber = FLOOR(RAND() * 100); 
SET @timestamp = DATE_FORMAT(NOW(), '%Y%m%d_%H%i%s');
SET @tempTableName = CONCAT('TempTable_', @timestamp, '_', @randomNumber); 

SET @sql = CONCAT(
    'CREATE TABLE ', @tempTableName, ' AS ',
    'SELECT ai.* FROM api_inventorycheck ai FORCE INDEX (api_inventorycheck_I1) ',
    'INNER JOIN STG_SA_Ad_Slot s FORCE INDEX (STG_SA_Ad_Slot_I1, STG_SA_Ad_Slot_status_IDX) ',
    'ON ai.adserver_adslot_id = s.adserver_adslot_id ',
    'WHERE s.status = \'ACTIVE\' ',
    'AND (', IF(@level1 IS NULL, '1=1', CONCAT('s.Level1 = \'', @level1, '\'')), ') ',
    'AND (', IF(@level2 IS NULL, '1=1', CONCAT('s.Level2 = \'', @level2, '\'')), ') ',
    'AND (', IF(@level3 IS NULL, '1=1', CONCAT('s.Level3 = \'', @level3, '\'')), ') ',
    'AND (', IF(@level4 IS NULL, '1=1', CONCAT('s.Level4 = \'', @level4, '\'')), ') ',
    'AND (', IF(@level5 IS NULL, '1=1', CONCAT('s.Level5 = \'', @level5, '\'')), ') ',
    'AND (', IF(@event IS NULL, '1=1', CONCAT('ai.event = \'', @event, '\'')), ') ',
    'AND ai.date BETWEEN \'', @startDate, '\' AND \'', @endDate, '\';'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sum_future_capacity = 0;
SET @sql_sum = CONCAT('SELECT @sum_future_capacity := SUM(future_capacity) FROM ', @tempTableName, ';');

PREPARE stmt_sum FROM @sql_sum;
EXECUTE stmt_sum;
DEALLOCATE PREPARE stmt_sum;

SET @sql_update_distribution = CONCAT('UPDATE ', @tempTableName, ' SET overwritten_impressions =  CAST((future_capacity / ', @sum_future_capacity, 
    ') * ', @overwritten_impression_number, ' AS UNSIGNED);');

PREPARE stmt_update_distribution FROM @sql_update_distribution;
EXECUTE stmt_update_distribution;
DEALLOCATE PREPARE stmt_update_distribution;

SET @total_distributed = 0;
SET @sql_sum_distributed = CONCAT('SELECT @sum_overwritten_impressions := SUM(overwritten_impressions) FROM ', @tempTableName, ';');

PREPARE stmt_sum_distributed FROM @sql_sum_distributed;
EXECUTE stmt_sum_distributed;
DEALLOCATE PREPARE stmt_sum_distributed;

SET @difference = @overwritten_impression_number - @sum_overwritten_impressions;
select @difference ;

SET @last_adslot_id = CONCAT( 'SELECT @last_adslot_id_from_tmp := id FROM', ' ' , @tempTableName , ' ', 'ORDER BY overwritten_impressions DESC LIMIT 1;');

PREPARE stmt_last_adslotid FROM @last_adslot_id ;
EXECUTE stmt_last_adslotid;
DEALLOCATE PREPARE stmt_last_adslotid;

SET @sql_update_adjust = CONCAT('UPDATE ', @tempTableName, ' ','SET overwritten_impressions = overwritten_impressions + ',' ', @difference ,' ','WHERE id = ', @last_adslot_id_from_tmp, ' AND ',@difference,' != 0;');

PREPARE stmt_updt_difference FROM @sql_update_adjust;
EXECUTE stmt_updt_difference;
DEALLOCATE PREPARE stmt_updt_difference;

SET @sql_update_api_inventorycheck = CONCAT('UPDATE api_inventorycheck AS a FORCE INDEX (PRIMARY) ', 'JOIN ', @tempTableName, ' AS t ON a.id = t.id ', 'SET a.overwritten_impressions = t.overwritten_impressions, ', 'a.overwriting_reason = "', IF(@Overwriting_reason IS NULL, CONCAT('BE-', @tempTableName), @Overwriting_reason), '", ','a.use_overwrite = "', IF(@Use_Overwrite IS NULL, 'N', @Use_Overwrite), '", ', 'a.Updated_By = "Backend-Utility";');

PREPARE stmt_update_api_inventorycheck FROM @sql_update_api_inventorycheck;
EXECUTE stmt_update_api_inventorycheck;
DEALLOCATE PREPARE stmt_update_api_inventorycheck;

SET @sql_drop = CONCAT('DROP TABLE IF EXISTS ', @tempTableName, ';');

PREPARE stmt_drop FROM @sql_drop;
EXECUTE stmt_drop;
DEALLOCATE PREPARE stmt_drop;

select @tempTableName;
select @last_adslot_id_from_tmp;
SELECT @sum_future_capacity AS TotalFutureCapacity;

SET @summary_sql = CONCAT(
    'SELECT ',
    'ai.use_overwrite, ai.overwriting_reason, ai.Updated_By, ',
    'SUM(ai.future_capacity) AS future_capacity_total, SUM(ai.overwritten_impressions) AS overwritten_impressions_total ',
    'FROM api_inventorycheck ai ',
    'WHERE ai.adserver_adslot_id IN (SELECT s.adserver_adslot_id FROM STG_SA_Ad_Slot s ',
    'WHERE s.status = \'ACTIVE\' ',
    'AND (', IF(@level1 IS NULL, '1=1', CONCAT('s.Level1 = \'', @level1, '\'')), ') ',
    'AND (', IF(@level2 IS NULL, '1=1', CONCAT('s.Level2 = \'', @level2, '\'')), ') ',
    'AND (', IF(@level3 IS NULL, '1=1', CONCAT('s.Level3 = \'', @level3, '\'')), ') ',
    'AND (', IF(@level4 IS NULL, '1=1', CONCAT('s.Level4 = \'', @level4, '\'')), ') ',
    'AND (', IF(@level5 IS NULL, '1=1', CONCAT('s.Level5 = \'', @level5, '\'')), ')) ',
    'AND (', IF(@event IS NULL, '1=1', CONCAT('ai.event = \'', @event, '\'')), ') ',
    'AND ai.date BETWEEN \'', @startDate, '\' AND \'', @endDate, '\' ',
    'GROUP BY ai.use_overwrite, ai.overwriting_reason, ai.Updated_By;'
);

PREPARE stmt_summary_sql FROM @summary_sql;
EXECUTE stmt_summary_sql;
DEALLOCATE PREPARE stmt_summary_sql;