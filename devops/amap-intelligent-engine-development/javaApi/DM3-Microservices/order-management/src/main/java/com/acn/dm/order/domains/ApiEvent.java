package com.acn.dm.order.domains;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.io.Serializable;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.DynamicUpdate;
import org.hibernate.annotations.Immutable;

@Data
@Entity
@Immutable
@NoArgsConstructor
@AllArgsConstructor
@DynamicUpdate
@Table(name = ApiEvent.TABLE_NAME)
public class ApiEvent implements Serializable {

    private static final long serialVersionUID = 1L;
    public static final String TABLE_NAME = "api_master_events";

    @Id
    private Long id;

    @Column(name = "event_key")
    private String eventKey;

    @Column(name = "event_value")
    private String eventValue;

    public String getCombination() {
        StringBuilder builder = new StringBuilder();
        builder.append(eventKey);
        builder.append("~");
        builder.append(eventValue);
        return builder.toString();
    }

}
