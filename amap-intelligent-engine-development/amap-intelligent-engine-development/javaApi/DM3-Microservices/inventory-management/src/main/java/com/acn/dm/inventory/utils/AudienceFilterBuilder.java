package com.acn.dm.inventory.utils;

import java.util.List;
import java.util.Objects;

import org.springframework.data.jpa.domain.Specification;

import com.acn.dm.inventory.domains.ApiSegmentReach;
import com.acn.dm.inventory.domains.ApiSegmentReach_;
import com.acn.dm.inventory.domains.pk.ApiSegmentReachPK_;

/**
 * @author Shivani Chaudhary
 *
 */
public abstract class AudienceFilterBuilder {

	
	protected static Specification<ApiSegmentReach> withAudienceIn(List<String> audiences) {
		if (audiences.isEmpty())
			return null;
		return (root, query, cb) -> cb.and(cb.in(root.get(ApiSegmentReach_.id).get(ApiSegmentReachPK_.COMMERCIAL_AUDIENCE_NAME)).value(audiences));
	}
	
	protected static Specification<ApiSegmentReach> withAdserverIds(List<String> adseverIds) {
		if (adseverIds.isEmpty())
			return null;
		return (root, query, cb) -> cb.and(cb.in(root.get(ApiSegmentReach_.id).get(ApiSegmentReachPK_.ADSERVER_ID)).value(adseverIds));
	}
	
	protected static Specification<ApiSegmentReach> concatInAnd(List<Specification<ApiSegmentReach>> filters) {
		return filters.stream().filter(AudienceFilterBuilder::isNotNullFilter)
				.reduce(Specification.where((oneEqualsToOne())), (a, b) -> a.and(b));
	}

	protected static Specification<ApiSegmentReach> oneEqualsToOne() {
		return (root, query, cb) -> cb.equal(cb.literal(1), 1);
	}

	private static boolean isNotNullFilter(Specification<ApiSegmentReach> filter) {
		return !Objects.isNull(filter);
	}
}
