package com.acn.dm.order.domains;

import java.io.Serializable;



import com.acn.dm.order.domains.pk.TrfPercentageVsAllPK;
import com.google.errorprone.annotations.Immutable;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;


@Data
@NoArgsConstructor
@AllArgsConstructor
public class TrfPercentageVsAll implements Serializable {

	private TrfPercentageVsAllPK id = new TrfPercentageVsAllPK();
	private Double ratio;
}
