package com.acn.dm.common.utils.rest;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;

/**
 * @author Shivani Chaudhary
 *
 */
public class ResponseEntityUtils {
	
	public static final String COUNT_NUMBER_IN_HEADER = "X-Total-Count";

	public static String numberOfElementToString(Page<?> page) {
		return String.valueOf(getTotalElements(page));
	}
	
	public static Long getTotalElements(Page<?> page) {
		return page.getTotalElements();
	}

	public static boolean isEmpty(Page<?> page) {
		return page.getTotalElements() < 1;
	}
	
	public static <E> ResponseEntity<List<E>> toResult(Page<E> page){
		return ResponseEntity.ok()
				.header(COUNT_NUMBER_IN_HEADER, numberOfElementToString(page))
				.header("Access-Control-Expose-Headers", COUNT_NUMBER_IN_HEADER)
				.body(page.getContent());
	}

	public static <E> ResponseEntity<E> getOrNotFound(Optional<E> item){
		if(item.isPresent())
			return ResponseEntity.ok(item.get());
		return ResponseEntity.notFound().build();
	}
}
