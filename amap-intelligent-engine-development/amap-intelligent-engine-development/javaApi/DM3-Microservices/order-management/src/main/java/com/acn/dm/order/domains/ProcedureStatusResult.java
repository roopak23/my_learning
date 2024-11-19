package com.acn.dm.order.domains;

import com.acn.dm.order.lov.ProcedureStatus;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ProcedureStatusResult {

    private ProcedureStatus procedureStatus;
    private Integer waitTime;

}
