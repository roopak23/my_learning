package com.acn.dm.inventory.service;

import com.acn.dm.inventory.rest.input.AudienceSegmentRequest;
import com.acn.dm.inventory.rest.output.AudienceReachResponseWrapper;

/**
 * @author Shivani Chaudhary
 *
 */
public interface AudienceService {
	
	public AudienceReachResponseWrapper segment(AudienceSegmentRequest request);
	
	default public AudienceReachResponseWrapper segmentList(AudienceSegmentRequest request){
		return segment(request);
	}
	
}
