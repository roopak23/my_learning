package com.acn.dm.order.models;

import java.time.LocalDateTime;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QuantityAndPeriod {

	private LocalDateTime day;
	private Boolean clash;
	private TargetAndQuantityPerAdslot targetPerSlots;
}
