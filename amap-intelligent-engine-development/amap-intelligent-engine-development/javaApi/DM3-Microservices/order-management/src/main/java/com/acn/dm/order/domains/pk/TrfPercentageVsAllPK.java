package com.acn.dm.order.domains.pk;

import java.io.Serializable;



import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TrfPercentageVsAllPK implements Serializable {

	private static final long serialVersionUID = 1L;
	
	private String adserverId;
	private String adserverAdslotId;
	private String adserverTargetRemoteId;
	
}
