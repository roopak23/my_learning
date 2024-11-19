DROP PROCEDURE IF EXISTS CheckOrderLineProcess;

CREATE PROCEDURE IF NOT EXISTS CheckOrderLineProcess(
    IN in_market_order_id VARCHAR(100),
    IN in_marker_order_line_details_id VARCHAR(100),
    IN in_message_seq_no INT,
    OUT out_status VARCHAR(20),
    OUT out_wait_time  INT
)
BEGIN


   
	DECLARE l_mold_process_status VARCHAR(255);
	DECLARE l_batch_status VARCHAR(255);
    DECLARE l_mesage_status VARCHAR(255);
    DECLARE l_message_seq_no int;
    DECLARE l_attempt_count int;
    DECLARE l_max_attempts int ;
    DECLARE l_mo_in_progress int ;
    DECLARE out_massage VARCHAR(255);
    
	DECLARE EXIT HANDLER FOR 3572 -- ER_LOCK_NOWAIT error code
    BEGIN
	    
	      UPDATE api_order_message_queue aomq
			 set aomq.attempt_count = coalesce(aomq.attempt_count,0) + 1,
                 aomq.update_datetime = CURRENT_TIMESTAMP(),
				 aomq.error_message = CONCAT('HANDLER FOR 3572: ',out_massage)
		   WHERE aomq.`id` =  in_message_seq_no;
		 
	    COMMIT;
        SELECT CONCAT('Status: ',out_status,'Message: ',out_massage); 
      
    END;
   
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN 
	    SET out_status = 'ERROR';
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
   
   	START TRANSACTION;

	SET autocommit = 0;
	SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED ;


   	SELECT status 
	 INTO l_batch_status
   	FROM batch_status LIMIT 1;

  
   	IF coalesce(l_batch_status,'RUNNING') THEN

		SET out_status = "BATCH_RUNNING";
		SET out_massage = "ETL is in progress. Abort";
		SET out_wait_time = 0;

		UPDATE api_order_message_queue aomq
		   SET aomq.error_message = out_massage
          WHERE aomq.`id` = in_message_seq_no;

   	ELSE 
  
		SET out_status = "WAITMESSAGE";
		SET out_massage = "Message is alrady processed in another thread. Abort";
		SET out_wait_time = 0;

		SELECT aomq.status,
				aomq.attempt_count,
				aomq.max_attempts
			INTO l_mesage_status,
				l_attempt_count,
				l_max_attempts
			FROM api_order_message_queue aomq
			WHERE aomq.`id` = in_message_seq_no
			-- FOR UPDATE NOWAIT
			;
			
		-- review this for max attemtps count(1)
		IF l_attempt_count >= l_max_attempts THEN
		
			SET out_status = "TIMEOUT";
			SET out_massage = "Max Attempts Reached. Abort";
			SET out_wait_time = 0;
							
		ELSE   

			SET out_status = "WAITMOLD";
			SET out_massage = "Market Order Line is alrady processed in another thread. Wait and restart process";
			SET out_wait_time = 30000;
			
			SELECT aops.status  
				INTO l_mold_process_status 
				FROM api_order_process_state aops
				WHERE aops.market_order_details_id  = in_marker_order_line_details_id
				AND aops.market_order_id = in_market_order_id 
				-- FOR UPDATE  NOWAIT
				;
				
			
			IF l_mold_process_status = 'IN_PROGRESS' THEN
			
				
				SET out_status = "WAITMOLD";
				SET out_massage = "Market Order Line is alrady processed in another thread. Wait and restart process";
				SET out_wait_time = 30000;

				UPDATE api_order_message_queue aomq
					set aomq.attempt_count = coalesce(aomq.attempt_count,0) + 1,
						aomq.update_datetime =  CURRENT_TIMESTAMP(),
						aomq.error_message = out_massage
				WHERE  aomq.`id` =  in_message_seq_no;
				
	
				
			ELSE
			
				IF l_mold_process_status in( 'NEW','COMPLETED','ERROR') THEN  -- check if MO is not procesed by another thread
						
					SET out_status = "WAITMO";
					SET out_massage = "Market Order is already processed in another thread. Wait and restart process";
					SET out_wait_time = 30000; 
						
					SELECT COALESCE(MAX(CASE WHEN  aops.status in ('IN_PROGRESS') THEN 1 ELSE 0 END),0) mo_in_progress  
						INTO l_mo_in_progress 
						FROM api_order_process_state aops
					WHERE aops.market_order_id = in_market_order_id
					--	 FOR UPDATE  NOWAIT
						;

					SET l_mo_in_progress = 0;	
						
					IF  l_mo_in_progress = 0  THEN  -- MOLD&MO  are not processed by other messages, check if this is the oldest MOLD message to be processed
					
						SELECT coalesce(min(aomq.`id`),in_message_seq_no) 
						INTO l_message_seq_no
						FROM api_order_message_queue  aomq 	  
						WHERE aomq.market_order_details_id  = in_marker_order_line_details_id
						 AND  aomq.market_order_id = in_market_order_id  
						 AND  aomq.STATUS NOT IN ('COMPLETED','VERROR','REJECTED');
						
						IF coalesce(l_message_seq_no,in_message_seq_no) <>  in_message_seq_no THEN
			
							SET out_status = "WAITMOLD";
							SET out_massage = "This is not the oldest MOLD message";
							SET out_wait_time = 30000;

							UPDATE api_order_message_queue aomq
								set aomq.attempt_count = coalesce(aomq.attempt_count,0) + 1,
									aomq.update_datetime =  CURRENT_TIMESTAMP(),
									aomq.error_message =  out_massage
							 WHERE  aomq.`id` =  in_message_seq_no;
							

							
						ELSE   
							-- message is ready for process
							UPDATE api_order_message_queue aomq
							   SET aomq.attempt_count = coalesce(aomq.attempt_count,0) + 1,
									aomq.status = 'IN_PROGRESS',
									aomq.update_datetime =  CURRENT_TIMESTAMP()
							 WHERE aomq.`id` =  in_message_seq_no;

								UPDATE api_order_process_state aps
								   SET aps.status = 'IN_PROGRESS',
									   aps.update_datetime =  CURRENT_TIMESTAMP()
								 WHERE aps.market_order_details_id = in_marker_order_line_details_id
								   AND aps.market_order_id = in_market_order_id;
								
							SET out_status = "OK";
							SET out_massage = "Message Can be processed";
							SET out_wait_time = 0;    
					
						END IF;
						
					ELSE
					
						SET out_status = "WAITMO";
						SET out_massage = "Market Order is already processed in another thread. Wait and restart process";
						SET out_wait_time = 30000; 

						UPDATE api_order_message_queue aomq
						   SET aomq.attempt_count = coalesce(aomq.attempt_count, 0) + 1,
						       aomq.update_datetime = CURRENT_TIMESTAMP(),
							   aomq.error_message = out_massage
						 WHERE aomq.`id` = in_message_seq_no;
						
					END IF;
				ELSE 

				     SET out_status = "WAITMESSAGE";
					 SET out_massage = "Uknow Status Aborting";
					 SET out_wait_time = 0;
				
					UPDATE api_order_message_queue aomq
					   SET aomq.attempt_count = coalesce(aomq.attempt_count,0) + 1,
							aomq.update_datetime =  CURRENT_TIMESTAMP(),
                            aomq.error_message = out_massage
					 WHERE aomq.`id` =  in_message_seq_no;
				
					
						
				END IF;
				
			END IF;
			
		END IF;

	END IF;
  
   	COMMIT;
  
   	SELECT CONCAT('Status: ',out_massage,'Message: ',out_massage); 
  
END;