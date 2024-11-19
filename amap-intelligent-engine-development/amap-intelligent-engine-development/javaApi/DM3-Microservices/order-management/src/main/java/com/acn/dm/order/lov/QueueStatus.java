package com.acn.dm.order.lov;

public enum QueueStatus {

    VERROR("VERROR"),
    NEW("NEW"),
    ERROR("ERROR"),
    BATCH_RUNNING("BATCH_RUNNING"),
    IN_PROGRESS("IN_PROGRESS"),
    COMPLETED("COMPLETED");

    private final String status;

    QueueStatus(String status) {
        this.status = status;
    }

    public String getValue() {
        return status;
    }

}
