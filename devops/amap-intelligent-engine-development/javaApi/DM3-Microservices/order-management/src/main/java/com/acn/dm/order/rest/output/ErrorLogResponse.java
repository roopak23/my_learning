package com.acn.dm.order.rest.output;

import java.io.Serializable;
import java.time.LocalDateTime;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class ErrorLogResponse implements Serializable {

    String id;
    private String message;
    private String timestamp;


    public ErrorLogResponse(String id, String message, LocalDateTime timestamp) {
        this.id = id;
        this.message = message;
        this.timestamp = timestamp.toString();
    }
}
