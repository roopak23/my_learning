package com.acn.dm.order.domains;

import com.acn.dm.order.domains.pk.APIReservedHistoryPK;
import com.acn.dm.order.lov.CalcType;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;


import java.io.Serializable;
import java.time.LocalDate;
import org.hibernate.annotations.DynamicUpdate;

/**
 * @author Shivani Chaudhary
 */
@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@DynamicUpdate
@Table(name = ApiReservedHistory.TABLE_NAME)
public class ApiReservedHistory implements Serializable {

  private static final long serialVersionUID = 1L;
  public static final String TABLE_NAME = "api_reserved_history";

  @JsonIgnore
  @EmbeddedId
  @Builder.Default
  private APIReservedHistoryPK id = new APIReservedHistoryPK();

  public interface COLUMNS {

    public static final String MARKET_ORDER_LINE_DETAILS_NAME = "market_order_line_details_name";
    public static final String TECH_LINE_ID = "tech_line_id";
    public static final String TECH_LINE_NAME = "tech_line_name";
    public static final String TECH_LINE_REMOTE_ID = "tech_line_remote_id";
    public static final String START_DATE = "start_date";
    public static final String END_DATE = "end_date";
    public static final String STATUS = "status";
    public static final String MEDIA_TYPE = "media_type";
    public static final String COMMERCIAL_AUDIENCE = "commercial_audience";
    public static final String QUANTITY = "quantity";
    public static final String UNIT_TYPE = "unit_type";
    public static final String UNIT_PRICE = "unit_price";
    public static final String UNIT_NET_PRICE = "unit_net_price";
    public static final String TOTAL_PRICE = "total_price";
    public static final String LENGTH = "length";
    public static final String FORMAT_ID = "format_id";
    public static final String PRICE_ITEM = "price_item";
    public static final String BREADCRUMB = "breadcrumb";
    public static final String ADVERTISER_ID = "advertiser_id";
    public static final String BRAND_NAME = "brand_name";
    public static final String MARKET_ORDER_ID = "market_order_id";
    public static final String MARKET_ORDER_NAME = "market_order_name";
    public static final String FREQUENCY_CAP = "frequency_cap";
    public static final String DAY_PART = "day_part";
    public static final String PRIORITY = "priority";
    public static final String AD_FORMAT_ID = "ad_format_id";
    public static final String ADSERVER_ID = "adserver_id";
    public static final String MARKET_PRODUCT_TYPE_ID = "market_product_type_id";
    public static final String CALC_TYPE = "calc_type";
    public static final String VIDEO_DURATION = "video_duration";
    public static final String ADSERVER_ADSLOT_NAME = "adserver_adslot_name";
    public static final String QUANTITY_RESERVED = "quantity_reserved";
    public static final String QUANTITY_BOOKED = "quantity_booked";
    public static final String AUDIENCE_NAME = "audience_name";

  }

  @Column(name = COLUMNS.MARKET_ORDER_LINE_DETAILS_NAME)
  private String moldName;

  @Column(name = COLUMNS.TECH_LINE_ID)
  private String techLineId;

  @Column(name = COLUMNS.TECH_LINE_NAME)
  private String techLineName;

  @Column(name = COLUMNS.TECH_LINE_REMOTE_ID)
  private String techLineRemoteId;

  @Column(name = COLUMNS.START_DATE)
  private LocalDate startDate;

  @Column(name = COLUMNS.END_DATE)
  private LocalDate endDate;

  @Column(name = COLUMNS.STATUS)
  private String status;

  @Column(name = COLUMNS.MEDIA_TYPE)
  private String mediaType;

  @Column(name = COLUMNS.COMMERCIAL_AUDIENCE)
  private String commercialAudience;

  @Column(name = COLUMNS.QUANTITY)
  private Integer quantity;

  @Column(name = COLUMNS.UNIT_TYPE)
  private String unitType;

  @Column(name = COLUMNS.UNIT_PRICE)
  private Double unitPrice;

  @Column(name = COLUMNS.UNIT_NET_PRICE)
  private Double unitNetPrice;

  @Column(name = COLUMNS.TOTAL_PRICE)
  private Double totalPrice;

  @Column(name = COLUMNS.LENGTH)
  private Integer length;

  @Column(name = COLUMNS.FORMAT_ID)
  private String formatId;

  @Column(name = COLUMNS.PRICE_ITEM)
  private String priceItem;

  @Column(name = COLUMNS.BREADCRUMB)
  private String breadcrumb;

  @Column(name = COLUMNS.ADVERTISER_ID)
  private String advertiserId;

  @Column(name = COLUMNS.BRAND_NAME)
  private String brandName;

  @Column(name = COLUMNS.MARKET_ORDER_ID)
  private String marketOrderId;

  @Column(name = COLUMNS.MARKET_ORDER_NAME)
  private String marketOrderName;

  @Column(name = COLUMNS.FREQUENCY_CAP)
  private Integer frequencyCap;

  @Column(name = COLUMNS.DAY_PART)
  private String daypart;

  @Column(name = COLUMNS.PRIORITY)
  private String priority;

  @Column(name = COLUMNS.AD_FORMAT_ID)
  private String adFormatId;

  @Column(name = COLUMNS.ADSERVER_ID)
  private String adserverId;

  @Column(name = COLUMNS.MARKET_PRODUCT_TYPE_ID)
  private String marketProductTypeId;

  @Column(name = COLUMNS.CALC_TYPE)
  private String calcType = CalcType.LINEAR.getValue();

  @Column(name = COLUMNS.VIDEO_DURATION)
  private Integer videoDuration;

  @Column(name = COLUMNS.ADSERVER_ADSLOT_NAME)
  private String adServerAdslotName;

  @Column(name = COLUMNS.QUANTITY_RESERVED)
  private int quantityReserved;

  @Column(name = COLUMNS.QUANTITY_BOOKED)
  private int quantityBooked;

  @Column(name = COLUMNS.AUDIENCE_NAME)
  private String audienceName;

}
