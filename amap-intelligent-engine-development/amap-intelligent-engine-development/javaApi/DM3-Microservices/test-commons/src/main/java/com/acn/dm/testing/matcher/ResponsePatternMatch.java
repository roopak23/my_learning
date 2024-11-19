package com.acn.dm.testing.matcher;

import java.util.regex.Pattern;

import org.hamcrest.BaseMatcher;
import org.hamcrest.Description;

public final class ResponsePatternMatch extends BaseMatcher<String> {

	private final Pattern pattern;

	public ResponsePatternMatch(String pattern) {
		super();
		this.pattern     = Pattern.compile(pattern);
	}

	@Override
	public boolean matches(Object item) {
		return pattern.matcher(item.toString()).find();
	}

	@Override
	public void describeTo(Description description) {
		description.appendText("Pattern Match");	
	}

}