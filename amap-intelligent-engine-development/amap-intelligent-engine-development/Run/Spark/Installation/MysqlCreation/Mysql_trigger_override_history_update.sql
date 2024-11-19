DROP TRIGGER IF EXISTS override_history_update;
CREATE TRIGGER IF NOT EXISTS override_history_update 

AFTER UPDATE

ON api_inventorycheck

FOR EACH ROW

BEGIN

    DECLARE fixed_datetime DATETIME;


 
    IF NEW.Updated_By IS NOT NULL THEN

        SET fixed_datetime = CURRENT_TIMESTAMP();

        INSERT INTO data_activation.override_update_history(

            id, `date`, adserver_id, adserver_adslot_id, adserver_adslot_name, audience_name, metric, state, city, event, pod_position, video_position, future_capacity, booked, reserved, missing_forecast, missing_segment, overwriting, percentage_of_overwriting, overwritten_impressions, overwriting_reason, use_overwrite, update_date_time, Updated_By, active_record_status,overwritten_expiry_date)

        VALUES(

            NEW.id, NEW.`date`, NEW.adserver_id, NEW.adserver_adslot_id, NEW.adserver_adslot_name, NEW.audience_name, NEW.metric, NEW.state, NEW.city, NEW.event, NEW.pod_position, NEW.video_position, NEW.future_capacity, NEW.booked, NEW.reserved, NEW.missing_forecast, NEW.missing_segment, NEW.overwriting, NEW.percentage_of_overwriting, NEW.overwritten_impressions, NEW.overwriting_reason, NEW.use_overwrite, fixed_datetime, NEW.Updated_By, 'ACTIVE',NEW.overwritten_expiry_date);

    END IF;

END
