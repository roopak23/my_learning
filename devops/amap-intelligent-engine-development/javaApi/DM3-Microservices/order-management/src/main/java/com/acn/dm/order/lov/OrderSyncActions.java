package com.acn.dm.order.lov;

/**
 * Represent all possible action for a order sync
 * 
 * @author Shivani Chaudhary
 *
 */
public enum OrderSyncActions {
	
	NO_ACTION,
	ADD_BOOKED,
	ADD_RESERVED,
	MOVE_FROM_RESERVED_TO_BOOKED,
	REMOVE_FROM_BOOKED,
	REMOVE_FROM_RESERVED,
	UPDATE_BOOKED,
	UPDATE_RESERVED,
	NO_CHANGE_OF_QUANTITY,
	RESERVE_BOOKED,
	MOVE_RESERVED_BOOKED_TO_BOOKED,
	REMOVE_BOOKED_RESERVED,
	UPDATE_RESERVED_BOOKED,
	NONE
}