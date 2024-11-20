SET hive.auto.convert.join= FALSE;

INSERT OVERWRITE TABLE AUD_STG_UserMatching partition(partition_date = {{ params.ENDDATE }})
SELECT 
    mask_hash(krux_userid) as userid,
	krux_userid,
	NULL as adserver_userid,
	NULL as firstparty_userid
from STG_DMP_SiteUserData
where partition_date = {{ params.ENDDATE }}
group by krux_userid;
