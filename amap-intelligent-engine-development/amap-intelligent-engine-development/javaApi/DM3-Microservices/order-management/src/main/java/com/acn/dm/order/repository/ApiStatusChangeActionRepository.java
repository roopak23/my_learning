package com.acn.dm.order.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.acn.dm.order.domains.ApiStatusChangeAction;
import com.acn.dm.order.domains.pk.ApiStatusChangeActionPK;

@Repository
public interface ApiStatusChangeActionRepository extends JpaRepository<ApiStatusChangeAction, ApiStatusChangeActionPK>, JpaSpecificationExecutor<ApiStatusChangeAction> {

	@Query(value = "SELECT action_mapped FROM data_activation.api_status_change_action u WHERE u.previous_status IN (:fromStatus) and u.current_status IN (:toStatus)" +
			"AND (:gam IS NULL OR u.book_ind = :gam)", nativeQuery = true)
	List<String> findActionMappedByStatus(@Param ("fromStatus") String fromStatus
			, @Param ("toStatus") String toStatus
			, @Param ("gam") String gam);

	@Query(value = "SELECT d FROM ApiStatusChangeAction d WHERE d.apiStatusChangeActionPK.previousStatus IN (:fromStatus) " +
			"AND d.apiStatusChangeActionPK.currentStatus IN (:toStatus)" +
			"AND (:gam IS NULL OR d.apiStatusChangeActionPK.bookInd = :gam)")
	List<ApiStatusChangeAction> findActionMappedByStatusForValid(@Param ("fromStatus") String fromStatus
			, @Param ("toStatus") String toStatus
			, @Param ("gam") String gam);
	
}
