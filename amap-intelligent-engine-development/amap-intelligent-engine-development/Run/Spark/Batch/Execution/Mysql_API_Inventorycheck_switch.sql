


-- Renaming Tables  15 min > 200 000 000 
-- this has to be set based on ETL execution time
SET @yyyy_mm_dd = DATE_FORMAT(now(), '%Y%m%d');
-- Backup api_invnetorycheck
SET @stm_reaname_table_bkp = CONCAT(
	'RENAME TABLE data_activation.api_inventorycheck TO data_activation.bkp_api_inventorycheck_',
	@yyyy_mm_dd
);

PREPARE stmt_raname
FROM @stm_reaname_table_bkp;
EXECUTE stmt_raname;
DEALLOCATE PREPARE stmt_raname;
-- Rename api_invnetorycheck_upd to  api_invnetorycheck
SET @stm_create_orig_table = 'RENAME TABLE data_activation.api_inventorycheck_upd TO data_activation.api_inventorycheck';
PREPARE stmt_orig
from @stm_create_orig_table;
EXECUTE stmt_orig;
DEALLOCATE PREPARE stmt_orig;
