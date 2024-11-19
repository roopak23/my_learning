package com.acn.dm.order.domains;

import com.acn.dm.order.domains.pk.ApiMoldDataPK;
import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.time.LocalDate;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.DynamicUpdate;
import org.hibernate.annotations.Immutable;

@Data
@Entity
@Immutable
@NoArgsConstructor
@AllArgsConstructor
@DynamicUpdate
@Table(name = ApiMoldData.TABLE_NAME)
public class ApiMoldData implements Serializable {

    private static final long serialVersionUID = 7792042286379553579L;
    protected static final String TABLE_NAME = "api_mold_attrib";

    @EmbeddedId
    private ApiMoldDataPK id;

    @CreationTimestamp
    @Column(name = "create_date", updatable = false)
    private LocalDate createDate;

    @Column(name = "update_date")
    private LocalDate updateDate;

    @Column(name = "market_order_id")
    private String marketOrderId;

    @PrePersist
    protected void onCreate() {
        this.createDate = LocalDate.now();
        this.updateDate = LocalDate.now();
    }

    @PreUpdate
    protected void onUpdate() {
        this.updateDate = LocalDate.now();
    }

    public ApiMoldData(ApiMoldDataPK id, String marketOrderId) {
        this.id = id;
        this.marketOrderId = marketOrderId;
    }
}
