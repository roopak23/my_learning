package com.acn.dm.order.utils;

import static org.junit.Assert.assertNotNull;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.Objects;

/**
 * @author Shivani Chaudhary
 */
public class Utils {

	public static <T extends Enum<T>> T getEnumFromString(Class<T> c, String string) {
		assertNotNull("Invalid enum class", c);
		assertNotNull("Invalid enum value", string);
		return Enum.valueOf(c, string.trim());
	}

	public static LocalDateTime atStartOfDay(LocalDate date) {
		return Objects.isNull(date) ? null : date.atStartOfDay();
	}

	public static LocalDateTime atEndOfDay(LocalDate date) {
		return Objects.isNull(date) ? null : date.atTime(23, 59, 59);
	}

	public static boolean isEmptyOrNull(Collection<?> collection) {
		return (collection == null || collection.isEmpty());
	}

	public static boolean isNotEmptyOrNull(Collection<?> collection) {
		return !isEmptyOrNull(collection);
	}

}