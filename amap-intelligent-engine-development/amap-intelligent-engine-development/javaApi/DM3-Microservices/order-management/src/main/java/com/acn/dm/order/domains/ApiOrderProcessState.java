package com.acn.dm.order.domains;

import com.acn.dm.order.domains.pk.ApiOrderProcessStatePK;
import com.acn.dm.order.lov.QueueStatus;
import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = ApiOrderProcessState.TABLE_NAME)
public class ApiOrderProcessState implements Serializable {

    private static final long serialVersionUID = 1L;
    public static final String TABLE_NAME = "api_order_process_state";

    @EmbeddedId
    ApiOrderProcessStatePK apiOrderProcessStatePK;

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private QueueStatus status;

    @Column(name = "update_datetime")
    private LocalDateTime updateDatetime;

    @Column(name = "create_datetime")
    private LocalDateTime createDatetime;

    @PrePersist
    protected void onCreate() {
        createDatetime = LocalDateTime.now();
        updateDatetime = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updateDatetime = LocalDateTime.now();
    }

}
