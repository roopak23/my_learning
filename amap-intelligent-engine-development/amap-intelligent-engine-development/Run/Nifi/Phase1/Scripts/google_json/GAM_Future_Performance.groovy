// Final

/**@ ------------------------------------------------------ *
* Script to download reports from Google Ad Manager (GAM)   *
*                                                           *
* To work this script needs 2 variables to be set in the    *
* GAM_Type:                                                 *
* - Reports                                                 *
* - Inventory                                               * 
* - AudienceSegment                                         *
*                                                           *
* Other Variables                                           *
*   + Report_Type = Reports                                 *
*   + Report_Dimensions                                     *
*   + Report_Columns                                        *
*   + Report_DataRange                                      *
* ---------------------------------------------------------**/

// Google Libs 
@Grapes([
  @Grab(group='com.google.api-ads', module='ads-lib', version='4.15.0'),
  @Grab(group='com.google.api-ads', module='dfp-axis', version='4.15.0')
])

// Utilities
import java.nio.charset.StandardCharsets
import org.joda.time.*
import org.joda.time.format.*

// Google Imports - General
import com.google.api.ads.admanager.lib.client.AdManagerSession
import com.google.api.ads.admanager.axis.factory.AdManagerServices
import com.google.api.ads.admanager.axis.v202108.ApiError
import com.google.api.ads.admanager.axis.v202108.ApiException
import com.google.api.ads.common.lib.auth.OfflineCredentials
import com.google.api.ads.common.lib.auth.OfflineCredentials.Api
import com.google.api.ads.common.lib.conf.ConfigurationLoadException
import com.google.api.ads.common.lib.exception.OAuthException
import com.google.api.ads.common.lib.exception.ValidationException
import com.google.api.client.auth.oauth2.Credential

// Google Imports - Common
import com.google.common.io.Resources

// Google Imports - Reporting
import com.google.api.ads.admanager.axis.v202108.Dimension
import com.google.api.ads.admanager.axis.v202108.Column
import com.google.api.ads.admanager.axis.v202108.DateRangeType
import com.google.api.ads.admanager.axis.v202108.ReportQueryAdUnitView
import com.google.api.ads.admanager.axis.v202108.ReportQuery
import com.google.api.ads.admanager.axis.v202108.ReportJob
import com.google.api.ads.admanager.axis.v202108.ExportFormat
import com.google.api.ads.admanager.axis.v202108.ReportDownloadOptions
import com.google.api.ads.admanager.axis.utils.v202108.ReportDownloader
import com.google.api.ads.admanager.axis.v202108.ReportServiceInterface
import com.google.api.ads.admanager.lib.utils.ReportCallback

// Google Imports - Inventory
import com.google.api.ads.admanager.axis.v202108.AdUnit
import com.google.api.ads.admanager.axis.v202108.AdUnitPage
import com.google.api.ads.admanager.axis.utils.v202108.StatementBuilder
import com.google.api.ads.admanager.axis.v202108.InventoryServiceInterface

// Google Imports - Audience
import com.google.api.ads.admanager.axis.v202108.AudienceSegment;
import com.google.api.ads.admanager.axis.v202108.AudienceSegmentPage;
import com.google.api.ads.admanager.axis.v202108.AudienceSegmentServiceInterface;


// Google Imports - LineItems
import com.google.api.ads.admanager.axis.v202108.LineItem;
import com.google.api.ads.admanager.axis.v202108.LineItemPage;
import com.google.api.ads.admanager.axis.v202108.LineItemServiceInterface;
import com.google.api.ads.admanager.axis.v202108.AdUnitTargeting

// Google Imports - Forecast
import com.google.api.ads.admanager.axis.v202108.DeliveryForecast;
import com.google.api.ads.admanager.axis.v202108.DeliveryForecastOptions;
import com.google.api.ads.admanager.axis.v202108.ForecastServiceInterface;
import com.google.api.ads.admanager.axis.v202108.LineItemDeliveryForecast;

import java.util.Date; 

//// Google Imports - Order
//import com.google.api.ads.admanager.axis.v202108.Order;
//import com.google.api.ads.admanager.axis.v202108.OrderPage;
//import com.google.api.ads.admanager.axis.v202108.OrderServiceInterface;
//
//// Google Imports - Placement
//import com.google.api.ads.admanager.axis.v202108.Placement;
//import com.google.api.ads.admanager.axis.v202108.PlacementPage;
//import com.google.api.ads.admanager.axis.v202108.PlacementServiceInterface;
//// Google Imports - Targeting
//import com.google.api.ads.admanager.axis.v202108.InventoryTargeting;
//import com.google.api.ads.admanager.axis.v202108.TargetingPresetServiceInterface;
////Google Imports - CustomTargeting
//import com.google.api.ads.admanager.axis.v202108.CustomTargetingKey;
//import com.google.api.ads.admanager.axis.v202108.CustomTargetingKeyPage;
//import com.google.api.ads.admanager.axis.v202108.CustomTargetingServiceInterface;

// The Main
log.info("Starting Execution")

// Create new Flow File
def flowFile = session.get()
if(!flowFile) return

// Get main variable
String gam_type = GAM_Type.evaluateAttributeExpressions().getValue().toUpperCase()
def audienceSegmentIdsString = flowFile.getAttribute('Audience_Segment_Ids')
def lineItemIdsString = flowFile.getAttribute('Line_Item_Ids')

log.info("Startging $gam_type report")

try {
    // Get Connection
    def adSession =  getConnection()
    def report = ''
    def lineItemIds = []

    switch (gam_type) {

        case "LINEITEM":
            report = downloadLineitemID(adSession,lineItemIds,audienceSegmentIdsString)
            break
        case "DELIVERYFORECAST":
            report = downloadForecast(adSession,lineItemIdsString)
            break

        default:
            log.error("No known report times selected - Will exit")
            return
    }

    // FlowFile Management
    flowFile = session.write(flowFile, {outStream ->
        // Write to file
        log.info("Writing results to file")
        outStream.write(report.toString().getBytes(StandardCharsets.UTF_8))
    } as OutputStreamCallback)

    // Add Name of the final file
    flowFile = session.putAttribute(flowFile, 'Line_Item_Ids', lineItemIds.join(",")) 
    flowFile = session.putAttribute(flowFile, 'tablename', context.getName())

    // Transfer the file out
    session.transfer(flowFile, REL_SUCCESS)

} catch (java.lang.IllegalArgumentException ex) {
    log.error("A Dimension or column is invalid, please check")

} catch (Exception ex) {
    log.error("$ex")

    // Transfer the file out
    session.transfer(flowFile, REL_FAILURE)

} finally {
    session.commit()
}

// Support functions
AdManagerSession getConnection() {
    // GAM Variables - To be changed if environment changes
    def jsonKeyFilePath = JsonKey_Path.evaluateAttributeExpressions().getValue()
    def applicationName = Application_Name.evaluateAttributeExpressions().getValue()
    def networkCode = Network_Code.evaluateAttributeExpressions().getValue()

    Credential googleCredential = new OfflineCredentials.Builder()
        .forApi(Api.AD_MANAGER)
        .withJsonKeyFilePath(jsonKeyFilePath)
        .build()
        .generateCredential()

    // Construct an AdManagerSession.
    AdManagerSession adManagerSession = new AdManagerSession.Builder()
        .withOAuth2Credential(googleCredential)
        .withApplicationName(applicationName)
        .withNetworkCode(networkCode)
        .build()

    log.info("Session created")

    return adManagerSession
}


String downloadLineitemID(AdManagerSession session, ArrayList lineItemIds, String audienceSegmentIds) {
    // Construct a Google Ad Manager service factory
    log.info("Starting downloadLineitemID")
    AdManagerServices adManagerServices = new AdManagerServices()

    // Get LineItem Service
    LineItemServiceInterface lineItemservice = adManagerServices.get(session, LineItemServiceInterface.class)

    // Build statement
    StatementBuilder statementBuilder = new StatementBuilder()
    .where("lineItemType = :lineItemType AND status = :status")
    .limit(500)
    .withBindVariableValue("lineItemType", "STANDARD")
    .withBindVariableValue("status", "DELIVERING")
    //.withBindVariableValue("costType", "CPC")
    //StatementBuilder statementBuilder = new StatementBuilder().orderBy("id ASC").limit(StatementBuilder.SUGGESTED_PAGE_LIMIT)
    Date now = new Date()
    // Default for total result set size.
    def totalResultSetSize = 0
    def audienceSegmentIdsList = audienceSegmentIds.tokenize(',[]')*.toLong()
    // Initialize Empty Report
    def report = ''
    def startloop=true
    def stringformat='''%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s \n'''
    report =String.format(stringformat,"tech_line_id","tech_order_id","enddate","delivery_rate_type","lineitem_type","selling_type","expected_delivery","actual_delivery","impressions_delivered","clicks_delivered","status")

    

     log.info(">>>>>>>>> The LineItemDownload >>>>>>>>>>>>>>>")
     while (startloop==true){
        LineItemPage page = lineItemservice.getLineItemsByStatement(statementBuilder.toStatement())
        if (page.getResults() != null) {
            totalResultSetSize = page.getTotalResultSetSize()
            log.info("The totalResultSetSize is ==>>>>> $totalResultSetSize")
            int i = page.getStartIndex()
            for (LineItem lineItem : page.getResults()) {
            def lineItemDate = lineItem.getEndDateTime().getDate().getYear()+"/"+lineItem.getEndDateTime().getDate().getMonth()+"/"+lineItem.getEndDateTime().getDate().getDay()
            def lineItemDateStart = lineItem.getStartDateTime().getDate().getYear()+"/"+lineItem.getStartDateTime().getDate().getMonth()+"/"+lineItem.getStartDateTime().getDate().getDay()
            Date parsedDate= Date.parse("yyyy/MM/dd", lineItemDate)
            Date parsedDateStart= Date.parse("yyyy/MM/dd", lineItemDateStart)
            if(parsedDateStart < now){
                if (lineItem.getStats() != null && lineItem.getDeliveryIndicator() != null) {
                    report = report + String.format(stringformat,lineItem.getId(),lineItem.getOrderId(),lineItem.getEndDateTime().getDate().getYear()+"/"+lineItem.getEndDateTime().getDate().getMonth()+"/"+lineItem.getEndDateTime().getDate().getDay(),lineItem.getDeliveryRateType(),lineItem.getLineItemType(),lineItem.getCostType(),lineItem.getDeliveryIndicator().getExpectedDeliveryPercentage(),lineItem.getDeliveryIndicator().getActualDeliveryPercentage(),lineItem.getStats().getImpressionsDelivered(),lineItem.getStats().getClicksDelivered(),lineItem.getStatus())
                } else if (lineItem.getStats() == null && lineItem.getDeliveryIndicator() != null){
                    report = report + String.format(stringformat,lineItem.getId(),lineItem.getOrderId(),lineItem.getEndDateTime().getDate().getYear()+"/"+lineItem.getEndDateTime().getDate().getMonth()+"/"+lineItem.getEndDateTime().getDate().getDay(),lineItem.getDeliveryRateType(),lineItem.getLineItemType(),lineItem.getCostType(),lineItem.getDeliveryIndicator().getExpectedDeliveryPercentage(),lineItem.getDeliveryIndicator().getActualDeliveryPercentage(),"0","0",lineItem.getStatus())
                } else if (lineItem.getStats() != null && lineItem.getDeliveryIndicator() == null){
                    report = report + String.format(stringformat,lineItem.getId(),lineItem.getOrderId(),lineItem.getEndDateTime().getDate().getYear()+"/"+lineItem.getEndDateTime().getDate().getMonth()+"/"+lineItem.getEndDateTime().getDate().getDay(),lineItem.getDeliveryRateType(),lineItem.getLineItemType(),lineItem.getCostType(),"0","0",lineItem.getStats().getImpressionsDelivered(),lineItem.getStats().getClicksDelivered(),lineItem.getStatus())
                } else {
                    report = report + String.format(stringformat,lineItem.getId(),lineItem.getOrderId(),lineItem.getEndDateTime().getDate().getYear()+"/"+lineItem.getEndDateTime().getDate().getMonth()+"/"+lineItem.getEndDateTime().getDate().getDay(),lineItem.getDeliveryRateType(),lineItem.getLineItemType(),lineItem.getCostType(),"0","0","0","0",lineItem.getStatus())
                }

                if(parsedDate > now){
                    if(lineItem.getEnvironmentType() == 'VIDEO_PLAYER'){
                        if(lineItem.getVideoMaxDuration > 0){
                            if(lineItem.getTargeting().getCustomTargeting() != null){
                                def checkLastType = lineItem.getTargeting().getCustomTargeting().getChildren()[0].getChildren().last().class.toString().split(" ")[1]
                                if(checkLastType.contains("AudienceSegmentCriteria")){
                                    def aid = lineItem.getTargeting().getCustomTargeting().getChildren()[0].getChildren().last().getAudienceSegmentIds()
                                    if(audienceSegmentIdsList.containsAll(aid.toList())){
                                        lineItemIds.add(lineItem.getId())
                                    }
                                } else {
                                    lineItemIds.add(lineItem.getId())
                                }
                            }
                        }

                    } else {
                        if(lineItem.getTargeting().getCustomTargeting() != null){
                            def checkLastType = lineItem.getTargeting().getCustomTargeting().getChildren()[0].getChildren().last().class.toString().split(" ")[1]
                            if(checkLastType.contains("AudienceSegmentCriteria")){
                                def aid = lineItem.getTargeting().getCustomTargeting().getChildren()[0].getChildren().last().getAudienceSegmentIds()
                                if(audienceSegmentIdsList.containsAll(aid.toList())){
                                    lineItemIds.add(lineItem.getId())
                                }
                            } else {
                                lineItemIds.add(lineItem.getId())
                            }
                        }
                    }
                }

            }
            log.info(">>>>>>>>>>>>>>>>>>>>>>  $i out of $totalResultSetSize>>>>>> " + lineItem.getId())
            i++

        }
     }

      statementBuilder.increaseOffsetBy(StatementBuilder.SUGGESTED_PAGE_LIMIT)
      if (statementBuilder.getOffset() >= totalResultSetSize){
          break;
      }
    }

    return report
}

String downloadForecast(AdManagerSession session, String lineItemIds) {
    // Construct a Google Ad Manager service factory
    log.info("Starting downloadForecast")
    AdManagerServices adManagerServices = new AdManagerServices()

    // Get Forecast Service
    ForecastServiceInterface forecastService = adManagerServices.get(session, ForecastServiceInterface.class)
    // Get LineItem Service

    DeliveryForecastOptions options = new DeliveryForecastOptions()
    log.info(">>>>>>>>> $lineItemIds  >>>>>>>>")
    def lineItemIdsList = lineItemIds.tokenize(',[]')*.toLong()
    log.info(">>>>>>>>> $lineItemIdsList  >>>>>>>>")
    def report = ''
    def stringformat='''%s|%s|%s|%s|%s|%s \n'''
    report =String.format(stringformat,"tech_line_id","tech_order_id","unit_type","predicted_units","quantity_delivered","matched_units")
    def lineItemIdsArray = lineItemIdsList as long[]
    log.info(">>>>>>>>> $lineItemIdsArray  >>>>>>>>")
    log.info(">>>> Number of applicable LineItemIds for the Forecast >>>> " + lineItemIdsList.size)
    log.info(">>>>>>>>> The ForeCastDownload >>>>>>>>>>>>>>>")
    DeliveryForecast forecast = forecastService.getDeliveryForecastByIds(lineItemIdsArray, options)


    if(forecast.getLineItemDeliveryForecasts() != null) {
        log.info("inside if")

        for (LineItemDeliveryForecast lineTDF : forecast.getLineItemDeliveryForecasts()) {
            log.info("inside for")
            log.info(lineTDF.getLineItemId() + "&" + lineTDF.getOrderId())
            report = report + String.format(stringformat,lineTDF.getLineItemId(),lineTDF.getOrderId(), lineTDF.getUnitType(),lineTDF.getPredictedDeliveryUnits(),lineTDF.getDeliveredUnits(),lineTDF.getMatchedUnits())
        }



    }

    
    return report
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
