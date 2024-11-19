package com.acn.dm.order.domains;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.io.Serializable;



import com.acn.dm.order.domains.pk.ApiStatusChangeActionPK;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.DynamicUpdate;

/**
 * @author Shivani Chaudhary
 */
@Data
@Entity
@Embeddable
@NoArgsConstructor
@AllArgsConstructor
@DynamicUpdate
@Table(name = ApiStatusChangeAction.TABLE_NAME)
public class ApiStatusChangeAction  implements Serializable  {
	
	private static final long  serialVersionUID = 1L;
	public static final String TABLE_NAME = "api_status_change_action";
	
	@EmbeddedId
	private ApiStatusChangeActionPK apiStatusChangeActionPK;

	@Column(name = "action_mapped")
	private String actionMapped;
}
