-- data_activation.commercial_audiance source

CREATE OR REPLACE
ALGORITHM = UNDEFINED VIEW `data_activation`.`commercial_audiance` AS
select
    json_object('Name',
    `data_activation`.`s`.`segment_name`,
    'External_Id',
    `data_activation`.`s`.`segment_id`,
    'Image_Url',
    '',
    'Advertiser',
    json_array(json_object('Advertiser_Id',
    '',
    'Ad_Server_Id',
    'GAM')),
    'Market_Targeting',
    json_array(json_object('Name',
    `data_activation`.`s`.`segment_name`,
    'Type',
    'custom_audiance',
    'Attribute',
    json_array(json_object('attribute_name',
    `data_activation`.`s`.`attribute_name`,
    'attribute_value',
    Replace(`data_activation`.`s`.`attribute_value`, '"','\''))),
    'Technical_Targeting',
    json_array(json_object('Technical_Remote_Id',
    `sd`.`technical_remote_id`,
    'Technical_Remote_Name',
    `sd`.`technical_remote_name`,
    'Type',
    'custom_audiance',
	'Size',
	`s`.`segment_size`,
    'Ad_Server_Id',
    `sd`.`adserver_id`))))) AS `commercial_audiance`
from
    (`data_activation`.`segments` `s`
join `data_activation`.`STG_DP_Adserver_Segment_Mapping` `sd`)
where
    (`data_activation`.`s`.`segment_id` = `sd`.`segment_id`);