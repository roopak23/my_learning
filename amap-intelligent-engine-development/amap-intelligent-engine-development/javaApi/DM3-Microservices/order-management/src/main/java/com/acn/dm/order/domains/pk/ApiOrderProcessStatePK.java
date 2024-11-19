package com.acn.dm.order.domains.pk;

import jakarta.persistence.Column;
import java.io.Serializable;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApiOrderProcessStatePK implements Serializable {

    private static final long serialVersionUID = 5290348611832553673L;
    @Column(name="market_order_id")
    private String marketOrderId;

    @Column(name="market_order_details_id")
    private String marketOrderDetailId;

}
