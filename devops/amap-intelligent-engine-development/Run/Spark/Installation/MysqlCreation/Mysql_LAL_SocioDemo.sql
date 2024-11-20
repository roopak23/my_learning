-- data_activation.DataMart_LAL_SocioDemo definition

CREATE TABLE if not exists `Datamart_LAL_SocioDemo` (
  `userid` varchar(255) ,
  `age` varchar(255) DEFAULT NULL,
  `gender` varchar(255) DEFAULT NULL,
  `accuracy_age` float DEFAULT NULL,
  `accuracy_gender` float DEFAULT NULL,
   primary key(userid)
) ;