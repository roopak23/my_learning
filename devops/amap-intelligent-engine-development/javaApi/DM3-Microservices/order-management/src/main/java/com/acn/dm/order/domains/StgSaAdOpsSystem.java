
package com.acn.dm.order.domains;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.io.Serializable;



import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * @author Shivani Chaudhary
 */
@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = StgSaAdOpsSystem.TABLE_NAME)
public class StgSaAdOpsSystem implements Serializable {

	private static final long serialVersionUID = 1L;
	public static final String TABLE_NAME = "stg_sa_ad_ops_system";

	public interface COLUMNS {

		public static final String ADSERVER_ID = "adserver_id";
		public static final String ADSERVER_NAME = "adserver_name";
		public static final String ADSERVER_TYPE = "adserver_type";
		public static final String DATASOURCE = "datasource";

	}
	@Id
	@Column(name = COLUMNS.ADSERVER_ID)
	private String adserverId;

	@Column(name = COLUMNS.ADSERVER_NAME)
	private String adserverName;

	@Column(name = COLUMNS.ADSERVER_TYPE)
	private String adserverType;

	@Column(name = COLUMNS.DATASOURCE)
	private String datasource;

}
