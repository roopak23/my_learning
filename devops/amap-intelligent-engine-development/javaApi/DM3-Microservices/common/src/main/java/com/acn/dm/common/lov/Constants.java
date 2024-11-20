package com.acn.dm.common.lov;

/**
 * @author Shivani Chaudhary
 */
public enum Constants {
	
	ZERO("0") , NA("NA"), ALL("All"), NULL("");
	
	private Constants(final String type) {	
		this.type=type;
	}
    // internal type
    private String type;
 
    public String getType() {
        return type;
    }

}
