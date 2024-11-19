package com.acn.dm.testing.utilities;

import java.util.regex.Pattern;

import org.springframework.core.convert.converter.Converter;

/**
 * @author Alberto Riminucci
 *
 */
public class CleanJson implements Converter<String,String> {
	
	@Override
	public String convert(String event) {
		String req = Pattern.compile("\\s*([}\\]\\[{:,])\\s*").matcher(event).replaceAll("$1").trim().replaceAll("\n", "").replaceAll("\t", "").replaceAll("\\?", "");
		req = Pattern.compile("[^a-zA-Z0-9,{\\[\\]}:\"\\s-\\(\\)]").matcher(req).replaceAll("");
		return req;
	}

}
