package com.acn.dm.order.domains.pk;

import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.time.LocalDateTime;



import com.acn.dm.order.domains.converter.LocalDateTimeToStringConverter;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

/**
 * @author Shivani Chaudhary
 */
@Data
@Embeddable
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode
public class APIReservedHistoryPK implements Serializable{

	private static final long serialVersionUID = 1L;
	
	@Convert(converter = LocalDateTimeToStringConverter.class)
	@Column(name ="date")
	private LocalDateTime date;

	@Column(name = "market_order_line_details_id")
	private String moldId;
	
	@Column(name = "adserver_adslot_id")
	private String adserverAdslotId;

	@Column(name = "city")
	private String city;

	@Column(name = "state")
	private String state;

	@Column(name = "event")
	private String event;

	@Column(name = "pod_position")
	private String podPosition;

	@Column(name = "video_position")
	private String videoPosition;

}
