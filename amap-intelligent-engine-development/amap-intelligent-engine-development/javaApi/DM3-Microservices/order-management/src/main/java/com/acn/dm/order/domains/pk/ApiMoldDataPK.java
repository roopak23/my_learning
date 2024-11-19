package com.acn.dm.order.domains.pk;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

@Embeddable
@Data
@EqualsAndHashCode
@NoArgsConstructor
@AllArgsConstructor
public class ApiMoldDataPK implements Serializable {

    private static final long serialVersionUID = 7792042286379553579L;

    @Column(name = "market_order_line_details_id")
    private String moldId;

    @Column(name = "attrib_type")
    private String attribType;

    @Column(name = "attrib_value")
    private String attribValue;
}
