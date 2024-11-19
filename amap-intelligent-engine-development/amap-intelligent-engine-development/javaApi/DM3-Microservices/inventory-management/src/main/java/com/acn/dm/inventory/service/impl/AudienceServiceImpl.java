package com.acn.dm.inventory.service.impl;

import com.acn.dm.common.lov.Constants;
import com.acn.dm.inventory.domains.ApiSegmentReach;
import com.acn.dm.inventory.domains.ApiSegmentReach_;
import com.acn.dm.inventory.domains.pk.ApiSegmentReachPK_;
import com.acn.dm.inventory.projection.AudienceProjection;
import com.acn.dm.inventory.rest.input.AudienceSegmentRequest;
import com.acn.dm.inventory.rest.output.AudienceReachResponse;
import com.acn.dm.inventory.rest.output.AudienceReachResponseWrapper;
import com.acn.dm.inventory.service.AudienceService;
import com.acn.dm.inventory.utils.AudienceReachFilterBuilder;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.TypedQuery;
import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.CriteriaQuery;
import jakarta.persistence.criteria.Expression;
import jakarta.persistence.criteria.Root;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;
import org.hibernate.jpa.HibernateHints;
import org.springframework.stereotype.Service;

/**
 * @author Shivani Chaudhary
 */
@Slf4j
@Service
public class AudienceServiceImpl implements AudienceService {

	@PersistenceContext
	private EntityManager em;

	@Override
	public AudienceReachResponseWrapper segment(AudienceSegmentRequest request) {

		List<AudienceReachResponse> audienceResponse = new ArrayList<>();

		CriteriaBuilder criteriaBuilder = em.getCriteriaBuilder();
		CriteriaQuery<AudienceProjection> cquery = criteriaBuilder.createQuery(AudienceProjection.class);
		Root<ApiSegmentReach> root = cquery.from(ApiSegmentReach.class);

		cquery.multiselect(audienceName(root), criteriaBuilder.sum(reach(root)), criteriaBuilder.sum(impression(root)),
				criteriaBuilder.sum(spend(root)));
		cquery.groupBy(audienceName(root));

		cquery.where(AudienceReachFilterBuilder.build(request).toPredicate(root, cquery, criteriaBuilder));
		TypedQuery<AudienceProjection> sql = em.createQuery(cquery);
		sql.setHint(HibernateHints.HINT_READ_ONLY, true);

		List<AudienceProjection> audience = sql.getResultList();
		log.debug("Audience Projection: {}", audience);
		if (audience.isEmpty()) {

			audienceResponse = request.getAudienceName().stream()
					.map(aud -> AudienceReachResponse.builder().reach(Constants.ZERO.getType())
							.impression(Constants.ZERO.getType()).spend(Constants.ZERO.getType()).audienceName(aud)
							.build())
					.toList();
		} else {
			TypedQuery<AudienceProjection> sqlAud = em.createQuery(cquery);
			sqlAud.setHint(HibernateHints.HINT_READ_ONLY, true);

		// @formatter:off
			audienceResponse =
				sqlAud.getResultList()
				.parallelStream()
				.map( aud -> AudienceReachResponse.builder()
				.reach(String.valueOf(aud.getReach()))
				.impression(aud.getImpression() == null ? Constants.ZERO.getType() : String.valueOf(aud.getImpression()))
				.spend(aud.getSpend() == null ? Constants.ZERO.getType() : String.valueOf(aud.getSpend()))
				.audienceName(aud.getAudienceName())
				.build())
				.collect(Collectors.toList());
		// @formatter:on
		}
		return AudienceReachResponseWrapper.builder().audience(audienceResponse).build();
	}

	private static Expression<Integer> reach(Root<ApiSegmentReach> root) {
		return root.get(ApiSegmentReach_.REACH);
	}

	private static Expression<Integer> impression(Root<ApiSegmentReach> root) {
		return root.get(ApiSegmentReach_.IMPRESSION);
	}

	private static Expression<Double> spend(Root<ApiSegmentReach> root) {
		return root.get(ApiSegmentReach_.SPEND);
	}

	private static Expression<String> audienceName(Root<ApiSegmentReach> root) {
		return root.get(ApiSegmentReach_.id).get(ApiSegmentReachPK_.COMMERCIAL_AUDIENCE_NAME);
	}

}
