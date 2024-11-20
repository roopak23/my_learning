package com.acn.dm.inventory.domains.pk;



import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

@Data
@Builder
@Embeddable
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
@AllArgsConstructor
public class ApiSegmentReachPK extends ApiCommonPK {

	private static final long serialVersionUID = 1L;
	
	@Column(name="adserver_id")
	private String adserverId;
	
	@Column(name="adserver_target_remote_id")
	private String adserverTargetRemoteId;	
	
	@Column(name="commercial_audience_name")
	private String commercialAudienceName;
	
}
