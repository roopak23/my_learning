-- data_activation.STG_SA_AFSAdSlot definition

CREATE TABLE IF NOT EXISTS `STG_SA_AFSAdSlot` (
  `id` varchar(255) ,
  `afsid` varchar(255) DEFAULT NULL,
  `sa_adslot_id` varchar(255) DEFAULT NULL,
  `datasource` varchar(255) DEFAULT NULL,
  primary key(id)
) ;