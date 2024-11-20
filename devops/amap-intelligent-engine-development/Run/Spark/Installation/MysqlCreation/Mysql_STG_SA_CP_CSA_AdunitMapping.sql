-- data_activation.STG_SA_CP_CSA_AdunitMapping definition

CREATE TABLE IF NOT EXISTS `STG_SA_CP_CSA_AdunitMapping` (
  `common_sales_area` varchar(70) ,
  `content_partner` varchar(70),
  `platform_name` varchar(50),
  `adserver_adslot_name_1` varchar(100),
  `adserver_adslot_name_2` varchar(100),
  `adserver_adslot_name_3` varchar(100),
  `adserver_adslot_name_4` varchar(100),
  `adserver_adslot_name_5` varchar(100),
  `adserver_adslot_id_1` varchar(50),
  `adserver_adslot_id_2` varchar(50),
  `adserver_adslot_id_3` varchar(50),
  `adserver_adslot_id_4` varchar(50),
  `adserver_adslot_id_5` varchar(50)  
) ;
