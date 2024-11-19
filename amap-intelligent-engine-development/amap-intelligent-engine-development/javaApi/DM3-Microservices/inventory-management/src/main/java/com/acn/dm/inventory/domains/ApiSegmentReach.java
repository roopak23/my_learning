package com.acn.dm.inventory.domains;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.io.Serializable;



import org.hibernate.annotations.Immutable;

import com.acn.dm.inventory.domains.pk.ApiSegmentReachPK;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Entity
@Immutable
@NoArgsConstructor
@AllArgsConstructor
@Table(name = ApiSegmentReach.TABLE_NAME)
public class ApiSegmentReach implements Serializable{
	
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	public static final String TABLE_NAME = "api_segment_reach";
	
	@EmbeddedId
	private ApiSegmentReachPK id;
	
	@Column(name="adserver_target_name")
	private String adserverTargetName;	
	
	@Column(name="reach")
	private Integer reach;
	
	@Column(name="impression")
	private Integer impression;
	
	@Column(name="spend")
	private Double spend;
	
}
