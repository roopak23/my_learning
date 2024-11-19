package com.acn.dm.common.utils.rest;

import java.io.Serializable;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * @author Shivani Chaudhary
 *
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class GeneratedQueryResult implements Serializable {

	private static final long serialVersionUID = 1L;
	private String query;

}
