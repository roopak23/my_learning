package com.acn.dm.common.lov;

/**
 * @author Shivani Chaudhary
 */
public enum InventoryCheckStatus {

	OK("OK"), KO("KO"),
	AVAILABLE("Requested quantity is available"),
	UNAVAILABLE("Requested quantity is unavailable"),
    NOT_FOUND("No results for the selected dimensions"),
    CLASH(" (clash occurred)");


	private InventoryCheckStatus(final String status) {
		this.status=status;
	}
    // internal state
    private String status;

    public String getStatus() {
        return status;
    }

}
