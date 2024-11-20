package com.acn.dm.common.rest.input.inventory;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class Target {

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    private String targetName;

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    private String targetRemoteName;

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    private String targetType;

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    private String targetRemoteId;

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    private String targetCategory;

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    private String targetCode;

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    private String position;

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    private String positionPod;

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    private Boolean exclude = false;


}
