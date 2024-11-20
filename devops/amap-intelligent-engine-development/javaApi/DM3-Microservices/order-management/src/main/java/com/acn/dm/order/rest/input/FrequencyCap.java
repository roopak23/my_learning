package com.acn.dm.order.rest.input;

import lombok.Data;

@Data
public class FrequencyCap {

    private String timeUnit;
    private Integer numTimeUnits;
    private Integer maxImpressions;

}
