UPDATE STG_SA_Past_Campaign_Performances 
SET report_id = 'Report0'
WHERE report_id is NULL 
AND LENGTH(concat(nvl(`device`,''),nvl(`time_of_day`,''),nvl(`day_of_week`,''),nvl(`time_range`,''),nvl(`gender`,''),nvl(`age`,''),nvl(`family_status`,''),nvl(`first_party_data`,''),nvl(`second_party_data`,''),nvl(`third_party_data`,''),nvl(`income`,''),nvl(`keyword_match_type`,''),nvl(`display_format`,''),nvl(`ad_copy`,''),nvl(`social_placement`,''),nvl(`creative_name`,''),nvl(`placement`,''),nvl(`network_type`,''),nvl(`country`,''),nvl(`state`,''),nvl(`region`,''),nvl(`city`,''),nvl(`ad_slot`,''),nvl(`keyword`,''))) = 0
AND partition_date = {{ params.ENDDATE }};

DELETE FROM STG_SA_Past_Campaign_Performances
WHERE report_id is NULL 
AND LENGTH(concat(nvl(`device`,''),nvl(`time_of_day`,''),nvl(`day_of_week`,''),nvl(`time_range`,''),nvl(`gender`,''),nvl(`age`,''),nvl(`family_status`,''),nvl(`first_party_data`,''),nvl(`second_party_data`,''),nvl(`third_party_data`,''),nvl(`income`,''),nvl(`keyword_match_type`,''),nvl(`display_format`,''),nvl(`ad_copy`,''),nvl(`social_placement`,''),nvl(`creative_name`,''),nvl(`placement`,''),nvl(`network_type`,''),nvl(`country`,''),nvl(`state`,''),nvl(`region`,''),nvl(`city`,''),nvl(`ad_slot`,''),nvl(`keyword`,''))) > 0
AND partition_date = {{ params.ENDDATE }};

UPDATE STG_SA_Past_Campaign_Performances 
SET email_opened = (email_total_sent * unique_open_rate)/100
WHERE partition_date = {{ params.ENDDATE }};

UPDATE STG_SA_Past_Campaign_Performances 
SET email_clicked = (email_total_sent * unique_click_rate)/100
WHERE partition_date = {{ params.ENDDATE }};