package com.acn.dm.inventory.domains.pk;


import java.time.LocalDateTime;



import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApiInventoryCheckPK
{
	private LocalDateTime date;
	private String adserverId;
	private String metric;
	private String adserverAdslotId;
	private String city;
	private String state;
	private String event;
	private String audienceName;
	private String podPosition;
	private String videoPosition;

}