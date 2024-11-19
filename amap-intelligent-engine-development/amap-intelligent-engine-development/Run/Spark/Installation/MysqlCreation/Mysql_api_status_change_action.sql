-- data_activation.api_status_change_action definition

CREATE TABLE IF NOT EXISTS data_activation.api_status_change_action (
  previous_status varchar(255) NOT NULL,
  current_status varchar(255) NOT NULL,
  book_ind varchar(1) NOT NULL,
  action_mapped varchar(255) NOT NULL,
  PRIMARY KEY (previous_status,current_status,book_ind)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

TRUNCATE TABLE data_activation.api_status_change_action;
-- ADD_RESERVED ditribute  qty to reserved
-- REMOVE_FROM_RESERVED - remove reserved_qty based on the data avaialable in api_reserved_history(previously reserved qty)
-- REMOVE_FROM_BOOKED - remove booked_qty based on the data available in api_reserved_history(previously booked qty)
-- REMOVE_BOOKED_RESERVED - remove reserved_qty and booked qty  based on the data avaialable in api_reserved_history(previously reserved/booked qty)
-- MOVE_FROM_RESERVED_TO_BOOKED - remove reserved qty based on api_reserved_history(previous reserved qty) and add to booked qty from the request
-- MOVE_RESERVED_BOOKED_TO_BOOKED - remove presiously booked and reserved qty based on api_inventory_history and ditribute to  booked based on qty requested in payload
-- RESERVE_BOOKED - remove previously reserved qty based on api_reserved_history, caclulate delta between qty from payload and previously booked qty. distributed delta to reserved qty
INSERT INTO data_activation.api_status_change_action 
(previous_status,current_status,book_ind,action_mapped) 
VALUES 
	('NA', 'PCA','N','ADD_RESERVED'),
	('NA', 'PIA', 'N', 'ADD_RESERVED'),
	('NA', 'APPROVED', 'N', 'ADD_RESERVED'),
	--
	('DRAFT', 'PCA','N','ADD_RESERVED'),
	('DRAFT', 'PIA','N','ADD_RESERVED'),
	('DRAFT', 'APPROVED', 'N', 'ADD_RESERVED'),
	('PIA', 'DRAFT', 'N', 'REMOVE_FROM_RESERVED'),
	('PCA', 'DRAFT', 'N', 'REMOVE_FROM_RESERVED'),
	--
	('PIA', 'PCA', 'N', 'UPDATE_RESERVED'),
	--
	('PIA', 'RETRACTED', 'N', 'REMOVE_FROM_RESERVED'),
	('PCA', 'RETRACTED', 'N', 'REMOVE_FROM_RESERVED'),
	('APPROVED', 'RETRACTED', 'N', 'REMOVE_FROM_RESERVED'),
	('RETRACTED', 'PIA', 'N', 'ADD_RESERVED'),
	('RETRACTED', 'PCA', 'N', 'ADD_RESERVED'),
	('RETRACTED', 'APPROVED', 'N', 'ADD_RESERVED'),
	--
	('PIA', 'CANCELLED', 'N', 'REMOVE_FROM_RESERVED'),
	('PCA', 'CANCELLED', 'N', 'REMOVE_FROM_RESERVED'),
	('APPROVED', 'CANCELLED', 'N', 'REMOVE_FROM_RESERVED'),
	--
	('PIA', 'READY', 'N', 'MOVE_FROM_RESERVED_TO_BOOKED'),
	('PCA', 'READY', 'N', 'MOVE_FROM_RESERVED_TO_BOOKED'),
	('APPROVED', 'READY', 'N', 'MOVE_FROM_RESERVED_TO_BOOKED'),
	--
	('DRAFT', 'PCA', 'Y', 'RESERVE_BOOKED'),
	('DRAFT', 'PIA', 'Y', 'RESERVE_BOOKED'),
	('DRAFT', 'APPROVED', 'Y', 'RESERVE_BOOKED'),
	('PIA', 'DRAFT', 'Y', 'REMOVE_BOOKED_RESERVED'),
	('PCA', 'DRAFT', 'Y', 'REMOVE_BOOKED_RESERVED'),
	('APPROVED', 'DRAFT', 'Y', 'REMOVE_BOOKED_RESERVED'),
	--
	('PIA', 'PCA', 'Y', 'UPDATE_RESERVED_BOOKED'),
	('APPROVED', 'APPROVED', 'Y', 'UPDATE_RESERVED_BOOKED'),
	--
	('PIA', 'RETRACTED', 'Y', 'REMOVE_FROM_RESERVED'),
	('PCA', 'RETRACTED', 'Y', 'REMOVE_FROM_RESERVED'),
	('APPROVED', 'RETRACTED', 'Y', 'REMOVE_FROM_RESERVED'),
	('RETRACTED', 'PIA', 'Y', 'RESERVE_BOOKED'),
	('RETRACTED', 'PCA', 'Y', 'RESERVE_BOOKED'),
	('RETRACTED', 'APPROVED', 'Y', 'RESERVE_BOOKED'),
	--
	('PIA', 'CANCELLED', 'Y', 'REMOVE_BOOKED_RESERVED'),
	('PCA', 'CANCELLED', 'Y', 'REMOVE_BOOKED_RESERVED'),
	('APPROVED', 'CANCELLED', 'Y', 'REMOVE_BOOKED_RESERVED'),
	('RETRACTED', 'CANCELLED', 'Y', 'REMOVE_BOOKED_RESERVED'),
	--
	('PIA', 'READY', 'Y', 'MOVE_RESERVED_BOOKED_TO_BOOKED'),
	('PCA', 'READY', 'Y', 'MOVE_RESERVED_BOOKED_TO_BOOKED'),
	('APPROVED', 'READY', 'Y', 'MOVE_RESERVED_BOOKED_TO_BOOKED'),
	('READY', 'PIA', 'Y', 'RESERVE_BOOKED'),
	('READY', 'PCA', 'Y', 'RESERVE_BOOKED'),
	('READY', 'APPROVED', 'Y', 'RESERVE_BOOKED'),
	('READY', 'CANCELLED', 'Y', 'REMOVE_BOOKED_RESERVED'),
	('READY', 'DRAFT', 'Y', 'REMOVE_BOOKED_RESERVED');




