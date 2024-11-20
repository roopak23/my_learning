package com.acn.dm.inventory.rest.input;

import lombok.Data;

@Data
public class FrequencyCap {

    private String timeUnit;
    private Integer numTimeUnits;
    private Integer maxImpressions;

}
