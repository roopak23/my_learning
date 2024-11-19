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
  @Grab(group='com.google.api-ads', module='ads-lib', version='4.20.0'),
  @Grab(group='com.google.api-ads', module='dfp-axis', version='4.20.0')
])

// Utilities
import java.nio.charset.StandardCharsets
import org.joda.time.*
import org.joda.time.format.*

// Google Imports - General
import com.google.api.ads.admanager.lib.client.AdManagerSession
import com.google.api.ads.admanager.axis.factory.AdManagerServices
import com.google.api.ads.admanager.axis.v202211.ApiError
import com.google.api.ads.admanager.axis.v202211.ApiException
import com.google.api.ads.common.lib.auth.OfflineCredentials
import com.google.api.ads.common.lib.auth.OfflineCredentials.Api
import com.google.api.ads.common.lib.conf.ConfigurationLoadException
import com.google.api.ads.common.lib.exception.OAuthException
import com.google.api.ads.common.lib.exception.ValidationException
import com.google.api.client.auth.oauth2.Credential

// Google Imports - Common
import com.google.common.io.Resources

// Google Imports - Reporting
import com.google.api.ads.admanager.axis.v202211.Dimension
import com.google.api.ads.admanager.axis.v202211.Column
import com.google.api.ads.admanager.axis.v202211.DateRangeType
import com.google.api.ads.admanager.axis.v202211.ReportQueryAdUnitView
import com.google.api.ads.admanager.axis.v202211.ReportQuery
import com.google.api.ads.admanager.axis.v202211.ReportJob
import com.google.api.ads.admanager.axis.v202211.ExportFormat
import com.google.api.ads.admanager.axis.v202211.ReportDownloadOptions
import com.google.api.ads.admanager.axis.utils.v202211.ReportDownloader
import com.google.api.ads.admanager.axis.v202211.ReportServiceInterface
import com.google.api.ads.admanager.lib.utils.ReportCallback

// Google Imports - Inventory
import com.google.api.ads.admanager.axis.v202211.AdUnit
import com.google.api.ads.admanager.axis.v202211.AdUnitPage
import com.google.api.ads.admanager.axis.utils.v202211.StatementBuilder
import com.google.api.ads.admanager.axis.v202211.InventoryServiceInterface

// Google Imports - Audience
import com.google.api.ads.admanager.axis.v202211.AudienceSegment;
import com.google.api.ads.admanager.axis.v202211.AudienceSegmentPage;
import com.google.api.ads.admanager.axis.v202211.AudienceSegmentServiceInterface;


//// Google Imports - LineItems
//import com.google.api.ads.admanager.axis.v202211.LineItem;
//import com.google.api.ads.admanager.axis.v202211.LineItemPage;
//import com.google.api.ads.admanager.axis.v202211.LineItemServiceInterface;
//import com.google.api.ads.admanager.axis.v202211.AdUnitTargeting
//
//// Google Imports - Order
//import com.google.api.ads.admanager.axis.v202211.Order;
//import com.google.api.ads.admanager.axis.v202211.OrderPage;
//import com.google.api.ads.admanager.axis.v202211.OrderServiceInterface;
//
//// Google Imports - Placement
//import com.google.api.ads.admanager.axis.v202211.Placement;
//import com.google.api.ads.admanager.axis.v202211.PlacementPage;
//import com.google.api.ads.admanager.axis.v202211.PlacementServiceInterface;
//// Google Imports - Targeting
//import com.google.api.ads.admanager.axis.v202211.InventoryTargeting;
//import com.google.api.ads.admanager.axis.v202211.TargetingPresetServiceInterface;
////Google Imports - CustomTargeting
//import com.google.api.ads.admanager.axis.v202211.CustomTargetingKey;
//import com.google.api.ads.admanager.axis.v202211.CustomTargetingKeyPage;
//import com.google.api.ads.admanager.axis.v202211.CustomTargetingServiceInterface;

// The Main
log.info("Starting Execution")

// Create new Flow File
def flowFile = session.get()
if(!flowFile) return

// Get main variable
String gam_type = GAM_Type.evaluateAttributeExpressions().getValue().toUpperCase()
//String account_id = Account_ID.evaluateAttributeExpressions().getValue()
//String jsonKey_path = JsonKey_Path.evaluateAttributeExpressions().getValue()
//String application_name = Application_Name.evaluateAttributeExpressions().getValue()
//String network_code = Network_Code.evaluateAttributeExpressions().getValue()
log.info("Startging $gam_type report")

try {
    // Get Connection
    log.info("Creating Session for $gam_type report")
    def adSession =  getConnection()
    def report = ''
    log.info("Session Created for $gam_type report")

    switch (gam_type) {
        case "REPORTS":
            def query = buildQuery()
            report = downloadReport(adSession, query)
            break
        case "INVENTORY":
            report = downloadInventory(adSession)
            log.info("Report Downloaded")
            break
        case "AUDIENCESEGMENT":
            report = downloadAudienceSegments(adSession)
            break
//        case "LINEITEM":
//			report= downloadLineitemID(adSession)
//            break
//        case "CUSTOMTARGETINGKEY":
//			report=downloadCustomTargetingkey(adSession)
//            break
//		case "INVENTORYTARGETING":
//			report=downloadInventoryTargeting(adSession)
//			break
//        case "ORDERSERVICE":
//			report = downloadOrder(adSession)
//            break
//        case "PLACEMENTSERVICE":
//			report = downloadPlacement(adSession)
//            break;
//		case "CUSTOMTARGETINGVALUE":
//			report = downloadCustomTargetingValue(adSession)
//			break;
//		case "GEOTARGETING":
//			report = downloadGeoTargeting(adSession)
//			break;
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


ReportQuery buildQuery() {
    ReportQuery reportQuery = new ReportQuery()

    // Get dimensions and columns
    String[] dimensions_string = Report_Dimensions.evaluateAttributeExpressions().getValue().toUpperCase().split(',')
    String[] columns_string = Report_Columns.evaluateAttributeExpressions().getValue().toUpperCase().split(',')
    String data_range = Report_Range.evaluateAttributeExpressions().getValue().toUpperCase()

    log.info("dimensions -> $dimensions_string")
    log.info("columns -> $columns_string")

    // Convert to Google Format
    Dimension[] dimensions = dimensions_string.collect { Dimension.fromString(it.trim()) }
    Column[] columns = columns_string.collect { Column.fromString(it.trim()) }

    // Add Dim and Col to report
    log.info("Adding dms & cols to query")
    reportQuery.setDimensions(dimensions)
    reportQuery.setColumns(columns)

    // Set the ad unit view to hierarchical
    log.info("Setting adUnitView")
    reportQuery.setAdUnitView(ReportQueryAdUnitView.FLAT)

    // Set the dynamic date range type or a custom start and end date
    reportQuery.setDateRangeType(DateRangeType.fromString(data_range))

    log.info("query -> $reportQuery")
    return reportQuery
}


String downloadReport(AdManagerSession session, ReportQuery reportQuery) {
    // Construct a Google Ad Manager service factory
    AdManagerServices adManagerServices = new AdManagerServices()

    // Get reporting service
    ReportServiceInterface reportService = adManagerServices.get(session, ReportServiceInterface.class)

    // Create the Report Job
    ReportJob reportJob = new ReportJob()
    reportJob.setReportQuery(reportQuery)

    // Submit the report
    log.info("Query submitted")
    reportJob = reportService.runReportJob(reportJob)

    // Request report
    log.info("Downloading query")
    ReportDownloader reportDownloader = new ReportDownloader(reportService, reportJob.getId())

    // Wait for the report to be ready.
    reportDownloader.waitForReportReady()

    // Download the report.
    ReportDownloadOptions options = new ReportDownloadOptions()
    options.setExportFormat(ExportFormat.CSV_DUMP)
    options.setUseGzipCompression(false)
    URL url = reportDownloader.getDownloadUrl(options)
    def report = Resources.toString(url, StandardCharsets.UTF_8)

    return report
}


String downloadInventory(AdManagerSession session) {
    // Construct a Google Ad Manager service factory
    log.info("AdManagerServices Start")
    AdManagerServices adManagerServices = new AdManagerServices()

    // Get Inventory Service
    log.info("InventoryServiceInterface Start")
    InventoryServiceInterface inventoryService = adManagerServices.get(session, InventoryServiceInterface.class)
    def limit = StatementBuilder.SUGGESTED_PAGE_LIMIT
    // Build statement
    //StatementBuilder statementBuilder = new StatementBuilder().orderBy("id ASC").limit(StatementBuilder.SUGGESTED_PAGE_LIMIT)
	StatementBuilder statementBuilder = new StatementBuilder()
    .where('status = :status')
    .withBindVariableValue('status', 'active')
    .limit(limit)

    log.info("StatementBuilder END")
    // Default for total result set size.
    def totalResultSetSize = 0

    // Initialize Empty Report
    def report = '';
	def startloop = true
	//stringformat for to genrate the string in csv format
    def stringformat='''%s|%s|%s|%s|%s|%s \n'''
	report = report + String.format(stringformat,'adserver_id','adserver_adslot_id','adserver_adslot_name','sitepage','status','adserver_parent_id')
    def loopCounter = 0 
    def progress = 0 
    def GamAccountId = Account_ID.evaluateAttributeExpressions().getValue()
 
    log.info("Starting the DO")
    while (startloop==true) {
      // Get ad units by statement.
	  //getAdUnitSizesByStatement
      AdUnitPage page = inventoryService.getAdUnitsByStatement(statementBuilder.toStatement())

      if (page.getResults() != null) {
        totalResultSetSize = page.getTotalResultSetSize()
		log.info("The totalResultSetSize is ==>>>>> $totalResultSetSize")

        for (AdUnit adUnit : page.getResults()) {
			report = report+ String.format(stringformat,
											GamAccountId,
											adUnit.getId(),
											adUnit.getName(),
											adUnit.getAdUnitCode(),
											adUnit.getStatus(),
											adUnit.getParentId())
		}
      }
      statementBuilder.increaseOffsetBy(limit);
      loopCounter = loopCounter + 1
      progress = ((loopCounter * limit ) / totalResultSetSize) * 100
      log.info("Progress is ==>>>>> $progress %")

	  if (statementBuilder.getOffset() >= totalResultSetSize){
		  break;
	  }
    } 
    return report
}

String downloadAudienceSegments(AdManagerSession session) {
    // Construct a Google Ad Manager service factory
    AdManagerServices adManagerServices = new AdManagerServices()

    // Get Inventory Service
    AudienceSegmentServiceInterface audienceService = adManagerServices.get(session, AudienceSegmentServiceInterface.class)
    def limit =  StatementBuilder.SUGGESTED_PAGE_LIMIT
    // Build statement
    //StatementBuilder statementBuilder = new StatementBuilder().orderBy("id ASC").limit(StatementBuilder.SUGGESTED_PAGE_LIMIT)
	StatementBuilder statementBuilder = new StatementBuilder()
	.where("status = :status")
	.limit(limit)
	.withBindVariableValue("status", "ACTIVE")
           
    // Default for total result set size.
    def totalResultSetSize = 0

    // Initialize Empty Report
    def report = ''
	def startloop=true
	def stringformat='''%s^%s^%s^%s^%s^%s^%s \n'''
	report = report + String.format(stringformat,
										'adserver_id',
										'adserver_target_remote_id',
										'adserver_target_name',
										'adserver_target_type',
										'status',
										'dataprovider',
										'segment_type')
     while (startloop==true){
      // Get ad units by statement.
      AudienceSegmentPage page = audienceService.getAudienceSegmentsByStatement(statementBuilder.toStatement())

      if (page.getResults() != null) {
        totalResultSetSize = page.getTotalResultSetSize()
		log.info("The totalResultSetSize is ==>>>>> $totalResultSetSize")

        for (AudienceSegment audienceSegment : page.getResults()) {
			report = report + String.format(stringformat,
								Account_ID.evaluateAttributeExpressions().getValue(),
								audienceSegment.getId(),
								audienceSegment.getName(),
								"AUDIENCE",
								audienceSegment.getStatus(),
								audienceSegment.getDataProvider(),
								audienceSegment.getType())
								
        }
      }
      //statementBuilder.increaseOffsetBy(StatementBuilder.SUGGESTED_PAGE_LIMIT)
	  statementBuilder.increaseOffsetBy(limit)
	  if (statementBuilder.getOffset() >= totalResultSetSize){
		  break;
	  }
    } 
    return report
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////