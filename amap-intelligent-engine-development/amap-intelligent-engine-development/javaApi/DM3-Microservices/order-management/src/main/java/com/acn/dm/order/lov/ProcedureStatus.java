package com.acn.dm.order.lov;

public enum ProcedureStatus {

    OK ("OK"),
    TIMEOUT ("TIMEOUT"),
    WAITMO ("WAITMO"),
    WAITMOLD ("WAITMOLD"),
    BATCH_RUNNING ("BATCH_RUNNING"),
    WAITMESSAGE ("WAITMESSAGE");

    private final String status;

    ProcedureStatus(String status) {
        this.status = status;
    }

    public String getValue() {
        return status;
    }

}
