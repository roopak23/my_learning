package com.acn.dm.inventory.domains.pk;

import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.MappedSuperclass;
import java.io.Serializable;
import java.time.LocalDateTime;



import com.acn.dm.inventory.domains.converter.LocalDateTimeToStringConverter;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

/**
 * @author Shivani Chaudhary
 */
@Data
@MappedSuperclass
@EqualsAndHashCode
@NoArgsConstructor
@AllArgsConstructor
public abstract class ApiCommonPK implements Serializable {

	private static final long serialVersionUID = 1L;

//	@Column(columnDefinition = "TIMESTAMP")
	@Convert(converter = LocalDateTimeToStringConverter.class)
	private LocalDateTime date;

	@Column(insertable = false , updatable = false)
	private String adserverAdslotId;

	@Column(insertable = false, updatable = false)
	private String metric;

	@Column(insertable = false, updatable = false)
	private String marketOrderLineDetailsId;

	@Column(insertable = false, updatable = false)
	private String sitepage;

	@Column(insertable = false, updatable = false)
	private String adserverTargetRemoteId;

	@Column(insertable = false, updatable = false)
	private String adserverId;

}
