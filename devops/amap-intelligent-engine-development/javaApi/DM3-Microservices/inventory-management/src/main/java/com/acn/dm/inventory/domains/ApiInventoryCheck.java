package com.acn.dm.inventory.domains;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.io.Serializable;


import java.time.LocalDateTime;
import org.hibernate.annotations.Immutable;


import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Entity
@Immutable
@NoArgsConstructor
@AllArgsConstructor
@Table(name = ApiInventoryCheck.TABLE_NAME)
public class ApiInventoryCheck implements Serializable{

  /**
   *
   */
  private static final long serialVersionUID = 1L;

  public static final String TABLE_NAME = "api_inventorycheck";

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  private LocalDateTime date;

  @Column(name="adserver_id")
  private String adserverId;

  @Column(name="metric")
  private String metric;

  @Column(name="adserver_adslot_id")
  private String adserverAdslotId;

  @Column(name = "city")
  private String city;

  @Column(name = "state")
  private String state;

  @Column(name = "event")
  private String event;

  @Column(name="audience_name")
  private String audienceName;

  @Column(name = "pod_position")
  private String podPosition;

  @Column(name = "video_position")
  private String videoPosition;

  @Column(name="adserver_adslot_name")
  private String adServerAdslotName;

  @Column(name = "future_capacity")
  private Integer futureCapacity;

  @Column(name = "reserved")
  private Integer reserved;

  @Column(name = "booked")
  private Integer booked;

  @Column(name = "missing_forecast")
  private String missingForecast;

  @Column(name = "missing_segment")
  private String missingSegment;

  @Column(name = "overwriting")
  private String overwriting;

  @Column(name = "percentage_of_overwriting")
  private String percentageOfOverwriting;

  @Column(name = "overwritten_impressions")
  private Integer overwrittenImpressions;

  @Column(name = "overwriting_reason")
  private String overwritingReason;

  @Column(name = "use_overwrite")
  private String useOverwrite;

  @Column(name = "overwritten_expiry_date")
  private LocalDateTime overwrittenExpiryDate;

  @Column(name = "updated_by")
  private String updatedBy;

  @Version
  private Long version;

}
