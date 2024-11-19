SELECT 
	`common_sales_area`, 
	`content_partner`, 
	`platfor_name`,
	`adserver_adslot_name_1`,
	`adserver_adslot_name_2`,
	`adserver_adslot_name_3`,
	`adserver_adslot_name_4`,
	`adserver_adslot_name_5`,
	`adserver_adslot_id_1`,
	`adserver_adslot_id_2`,
	`adserver_adslot_id_3`,
	`adserver_adslot_id_4`,
	`adserver_adslot_id_5`
from stg_sa_cp_csa_adunitmapping 
WHERE partition_date = (SELECT MAX(partition_date) FROM stg_sa_cp_csa_adunitmapping)