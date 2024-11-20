package com.acn.dm.inventory.rest.input;

import com.acn.dm.inventory.config.InventoryProperties;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class Target {

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    @Size(min = 0, max = InventoryProperties.STRING_MAX_LIMIT)
    private String targetRemoteName;

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    @Size(min = 0, max = InventoryProperties.STRING_MAX_LIMIT)
    private String targetName;

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    @Size(min = 0, max = InventoryProperties.STRING_MAX_LIMIT)
    private String targetType;

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    @Size(min = 0, max = InventoryProperties.STRING_MAX_LIMIT)
    private String targetRemoteId;

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    @Size(min = 0, max = InventoryProperties.STRING_MAX_LIMIT)
    private String targetCategory;

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    @Size(min = 0, max = InventoryProperties.STRING_MAX_LIMIT)
    private String targetCode;

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    @Size(min = 0, max = InventoryProperties.STRING_MAX_LIMIT)
    private String position;

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    @Size(min = 0, max = InventoryProperties.STRING_MAX_LIMIT)
    private String positionPod;

    @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
    private Boolean exclude = false;


}
