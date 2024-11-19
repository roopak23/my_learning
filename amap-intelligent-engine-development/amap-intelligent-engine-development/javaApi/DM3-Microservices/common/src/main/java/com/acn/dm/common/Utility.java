package com.acn.dm.common;

import java.time.ZonedDateTime;
import java.util.Calendar;

import org.slf4j.Logger;

public class Utility {

	public static Calendar localDateToCalendar(ZonedDateTime localDate) {
		Calendar calendar = Calendar.getInstance();
		calendar.clear();
		// assuming start of day
		calendar.set(localDate.getYear(), localDate.getMonthValue() - 1, localDate.getDayOfMonth());
		return calendar;
	}

	public static Calendar localDateTimeToDate(ZonedDateTime zonedDateTime) {
		Calendar calendar = Calendar.getInstance();
		calendar.clear();
		calendar.set(zonedDateTime.getYear(), zonedDateTime.getMonthValue() - 1, zonedDateTime.getDayOfMonth(),
				zonedDateTime.getHour(), zonedDateTime.getMinute(), zonedDateTime.getSecond());
		return calendar;
	}
	
	public static Logger getLogger(Class<?> clazz) {
		return org.slf4j.LoggerFactory.getLogger(clazz);
	}


}
