package com.acn.dm.common.rest.input.inventory;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.Objects;
import lombok.Data;
import lombok.NoArgsConstructor;


@Data
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class AdSlots {

  @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
  private String adslotRemoteId;

  @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
  private String adslotName;

  @Schema(requiredMode = Schema.RequiredMode.NOT_REQUIRED)
  private boolean excludeChilds = true;

  public AdSlots(String adslotRemoteId) {
    this.adslotRemoteId = adslotRemoteId;
  }
  public AdSlots(String adslotRemoteId, String adslotName) {
    this.adslotRemoteId = adslotRemoteId;
    this.adslotName = adslotName;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    AdSlots adSlots = (AdSlots) o;
    return adslotRemoteId.equals(adSlots.adslotRemoteId) && Objects.equals(adslotName, adSlots.adslotName);
  }

  @Override
  public int hashCode() {
    return Objects.hash(adslotRemoteId, adslotName);
  }
}
