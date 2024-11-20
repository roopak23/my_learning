package com.acn.dm.common.utils.rest.output.error;





import org.springframework.http.HttpHeaders;

import com.netflix.hystrix.exception.HystrixBadRequestException;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class FeignBadResponseWrapper extends HystrixBadRequestException {
	
	 /**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	private final int status;
	    private final HttpHeaders headers;
	    private final String body;

	    public FeignBadResponseWrapper(int status, HttpHeaders httpHeaders, String body) {
	        super("Bad request");
	        this.status = status;
	        this.headers = httpHeaders;
	        this.body = body;
	    }

}
