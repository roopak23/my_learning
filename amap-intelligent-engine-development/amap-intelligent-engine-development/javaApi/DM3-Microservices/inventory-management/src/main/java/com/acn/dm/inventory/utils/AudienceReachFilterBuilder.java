package com.acn.dm.inventory.utils;

import java.util.ArrayList;
import java.util.List;

import org.springframework.data.jpa.domain.Specification;

import com.acn.dm.inventory.domains.ApiSegmentReach;
import com.acn.dm.inventory.rest.input.AudienceSegmentRequest;

/**
 * @author Shivani Chaudhary
 */
public abstract class AudienceReachFilterBuilder extends AudienceFilterBuilder {

	public static Specification<ApiSegmentReach> build(AudienceSegmentRequest request) {

		List<Specification<ApiSegmentReach>> filters = new ArrayList<>();

		filters.add(withAudienceIn(request.getAudienceName()));
		if (!Utils.isEmptyOrNull(request.getAdserverId())) {
			filters.add(withAdserverIds(request.getAdserverId()));
		}
		return concatInAnd(filters);

	}
}
