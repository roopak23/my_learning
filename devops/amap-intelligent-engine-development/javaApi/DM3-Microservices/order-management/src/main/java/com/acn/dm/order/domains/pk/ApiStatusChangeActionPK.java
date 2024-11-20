package com.acn.dm.order.domains.pk;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;



import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * @author Shivani Chaudhary
 */
@Data
@Embeddable
@NoArgsConstructor
@AllArgsConstructor
public class ApiStatusChangeActionPK implements Serializable{
	
	private static final long  serialVersionUID = 1L;
	
	@Column(name = "previous_status")
	private String previousStatus;

	@Column(name = "current_status")
	private String currentStatus;

	@Column(name = "book_ind")
	private String bookInd;
}
