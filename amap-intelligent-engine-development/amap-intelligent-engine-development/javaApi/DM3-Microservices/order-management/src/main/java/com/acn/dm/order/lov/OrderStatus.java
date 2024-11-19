package com.acn.dm.order.lov;

import java.util.NoSuchElementException;
import java.util.Objects;

import org.apache.logging.log4j.util.Strings;

/**
 * @author Shivani Chaudhary
 *
 */
public enum OrderStatus {

	NULL(null),
	NA("NA"),
	DRAFT("Draft"),
	APPROVED("Approved"),
	READY("Ready"),
	INFLIGHT("Inflight"),
	PAUSED("Paused"),
	CANCELLED("Cancelled"),
	DELETED("Deleted"),
	COMPLETED("Completed"),
	;

	OrderStatus(String text) {
		value = text;
	}
	
	private final String value;

	public String getValue() {
		return value;
	}
	
	public static OrderStatus fromString(String value) {
		if(Strings.isBlank(value)) return NULL;
		for(OrderStatus e : OrderStatus.values()) {
			if(Objects.isNull(e.value)) {
				continue;
			}
			if(e.value.equals(value)) {
				return e;
			}
		}
		throw new NoSuchElementException(value + " not found");
	}

}
