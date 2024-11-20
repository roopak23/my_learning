package com.acn.dm.order.domains;

import com.acn.dm.order.domains.pk.ApiMoldDataPK;
import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDate;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.DynamicUpdate;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@DynamicUpdate
@Table(name = ApiMoldHistory.TABLE_NAME)
public class ApiMoldHistory {

    public static final String TABLE_NAME = "api_mold_history";

    @Id
    @Column(name = "mold_id")
    private String moldId;

    @Column(name = "status")
    private String status;

    @Column(name = "quantity")
    private long quantity;

    @Column(name = "quantity_reserved")
    private long quantityReserved;

    @Column(name = "quantity_booked")
    private long quantityBooked;

    @Column(name = "book_ind")
    private String bookInd;

}
