/**
 * 
 */
package com.acn.dm.order.domains.converter;

import static java.time.format.DateTimeFormatter.ISO_LOCAL_DATE;
import static java.time.format.DateTimeFormatter.ISO_LOCAL_TIME;


import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.util.Objects;



/**
 * string type in primary raise errors, this converter avoid in some way that error
 * 
 * @author Alberto Riminucci
 *
 */
@Converter
public class LocalDateTimeToStringConverter implements AttributeConverter<LocalDateTime, String> {
	
	private static final DateTimeFormatter formatter = new DateTimeFormatterBuilder()
            .parseCaseInsensitive()
            .append(ISO_LOCAL_DATE)
            .appendLiteral(' ')
            .append(ISO_LOCAL_TIME)
            .toFormatter();

	@Override
	public String convertToDatabaseColumn(LocalDateTime attribute) {
		return Objects.isNull(attribute) ? null : attribute.format(formatter);
	}

	@Override
	public LocalDateTime convertToEntityAttribute(String dbData) {
		if(Objects.isNull(dbData)) return null;
		return Objects.isNull(dbData) ? null : LocalDateTime.parse(dbData, formatter);
	}

}
