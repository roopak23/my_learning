package com.acn.dm.common.error;

/**
 * @author Shivani Chaudhary
 *
 */
public class ConvertToSQLException extends Exception {

	/**
	 */
	public ConvertToSQLException(String error) {
		super(error);
	}
	
	public ConvertToSQLException() {
		super();
	}

	private static final long serialVersionUID = 1L;

}
