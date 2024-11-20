import datetime
from googleads import ad_manager, oauth2

import pandas as pd
import traceback
from sys import argv
import numpy as np

import pyspark.sql.functions as F
from pyspark.sql.types import *
from pyspark import SparkContext
from pyspark.sql import SparkSession
from pyspark.sql.types import *

# Custom Import
import sys
sys.path.append('/tmp/Libraries')
from ie_hive_connection import IEHiveConnection

def fetch_input_from_hive(spark_session, partition_date, database: str = 'database'):
    # Create connection
    conn = IEHiveConnection(database=database)

    query = "SELECT DISTINCT * from trf_adserver_forecast_input where partition_date = {}".format(partition_date)

    schema = StructType([
        StructField('tech_line_id', StringType(), True),
        StructField('remote_id', StringType(), True),
        StructField('tech_order_id', StringType(), True),
        StructField('order_remote_id', StringType(), True),
        StructField('start_date', DateType(), True),
        StructField('end_date', DateType(), True),
        StructField('product_suggestion', StringType(), True),
        StructField('adserver_target_type', DoubleType(), True),
        StructField('audience_suggestion', StringType(), True),
        StructField('priority_suggestion', IntegerType(), True),
        StructField('frequency_capping', StringType(), True),
        StructField('frequency_suggestion', IntegerType(), True),
        StructField('cost_per_unit', DoubleType(), True),
        StructField('metric', StringType(), True),
        StructField('campaign_objective', StringType(), True),
        StructField('creative_size', StringType(), True)
        ])
    

    # read in pandas and conver to hive
    result = pd.read_sql(query, conn)
    print("query done")
    print(result.columns)
    row_count = result.shape[0]

    # Check row_count returned from Hive query
    if(row_count == 0):
        print("query returned 0-rows")
        return 0
        
    result = result.replace({np.nan: None})
    print(result.dtypes)
    print(schema)

    # Create DataFrame only when Hive Query return rows
    df = spark_session.createDataFrame(result, schema)
    print("converted to spark")
    conn.close()

    return df

def create_proposal_line_item(root_ad_unit_id, segment, width, height, start_datetime, end_datetime, cost_per_unit, metric, goal, num_time_units, line_item_priority):

    line_item = {
        'targeting': {
            'inventoryTargeting': {
                'targetedAdUnits': [
                    {
                        'includeDescendants': True,
                        'adUnitId': root_ad_unit_id,
                    }
                ],
            },
            'customTargeting': {
                'logicalOperator': 'OR',
                'children': [
                    {
                        'xsi_type': 'AudienceSegmentCriteria',
                        'operator': 'IS',
                        'audienceSegmentIds': [segment],
                    }
                ],
            },
        },
        'creativePlaceholders': [
            {
                'size': {
                    'width': width,
                    'height': height,
                },
            },
        ],
        'lineItemType': 'STANDARD',
        'startDateTimeType': "USE_START_DATE_TIME",
        'startDateTime': start_datetime,
        'endDateTime': end_datetime,
        'costType': metric,
        'costPerUnit': {
            'currencyCode': 'AUD',
            'microAmount': cost_per_unit,
        },
        'primaryGoal': {
            'units': goal,
            'unitType': 'IMPRESSIONS',
            'goalType': 'LIFETIME',
        },
        'contractedUnitsBought': '0',
        'creativeRotationType': 'EVEN',
        'discountType': 'PERCENTAGE',
        'frequencyCaps': {
            'timeUnit': 'DAY',
            'numTimeUnits': num_time_units,
            'impressions': '1',
            'timeBetweenCaps': '0',
        },
        'lineItemPriority': line_item_priority,
    }
    return line_item

def call_forecast_gam(df, forecast_service):
    # must be tested when real data available
    adserver_forecast_output_schema = StructType([
        StructField('remote_id', StringType(), True),
        StructField('order_remote_id', StringType(), True),
        StructField('unit_type', StringType(), True),
        StructField('predicted_units', IntegerType(), True),
        StructField('quantity_delivered', IntegerType(), True),
        StructField('matched_units', IntegerType(), True),
        StructField('model_id', StringType(), True)
        ])
    adserver_forecast_output_df = spark.createDataFrame([], schema)

    start_datetime = datetime.datetime.strptime(str(partition_date), '%Y%m%d') + datetime.timedelta(days=1)
    for values in df.collect():
        end_datetime = values.end_date
        width = values.creative_size.split('x')[0]
        height = values.creative_size.split('x')[1]
        cost_per_unit = values.unit_net_price * 1000000

        #line_item = create_proposal_line_item(values.ad_format_id, values.commercial_audience, width, height, start_datetime, end_datetime, cost_per_unit, values.metric, values.remaining_quantity, 1, 10)
        line_item = create_proposal_line_item(values.product_suggestion, values.product_suggestion, width, height, start_datetime, end_datetime, cost_per_unit, values.metric, values.product_suggestion, values.product_suggestion, values.product_suggestion)

        prospective_line_item = {
            'lineItem': line_item,
            'advertiserId': values.advertiser_id,
        }

        forecast_options = {
            'ignoredLineItemIds': [],
        }

        forecast  = forecast_service.getDeliveryForecast(prospective_line_item, forecast_options)

        new_row = {"remote_id": values.remote_id, "order_remote_id": values.order_remote_id, "unit_type": forecast['unitType'], "predicted_units": forecast['predicted_units'], "quantity_delivered": forecast['deliveredUnits'], "matched_units": forecast['matched_units'], "model_id": values.model_id}

        new_df = spark.createDataFrame([tuple(new_row.values())], schema)

        adserver_forecast_output_df = adserver_forecast_output_df.union(new_df)

    return adserver_forecast_output_df

def main(partition_date: str, database: str = 'database') -> None:

    spark_session = SparkSession.builder \
        .config("hive.exec.dynamic.partition.mode", "nonstrict") \
        .enableHiveSupport() \
        .getOrCreate()
    spark_session.sql(f"USE {database}")
    spark_context = SparkContext.getOrCreate()
    spark_context.setLogLevel("INFO")

    # Set the path to your JSON key file
    json_key_file = '/path/to/json/key/file.json'

    # Create an OAuth2 client using the JSON key file
    credentials = oauth2.ServiceAccountCredentials.from_json_keyfile_name(
        json_key_file,
        scopes=['https://www.googleapis.com/auth/dfp']
    )
    oauth2_client = oauth2.GoogleServiceAccountClient(credentials)

    # Create an Ad Manager client using the OAuth2 client
    client = ad_manager.AdManagerClient('version', oauth2_client)

    forecast_service = client.service.ForecastService

    # code to initialize and authenticate forecast_service
    # sample Dataframe
    # df = {'ad_format_id': '123', 'commercial_audience': '456', 'creative_size': ['300x250'], 'unit_net_price': 0.5, 'metric': 'CPM', 'remaining_quantity': 1000, 'advertiser_id': '789', 'end_date': '2022-12-31'}
    input_df = fetch_input_from_hive(spark_session)
    if input_df == 0:
        print("<<<<<<<< There are no rows in trf_adserver_forecast_input table for partition_date = {} >>>>>>>".format(partition_date))
        return

    output_df = call_forecast_gam(input_df, forecast_service)

__name__ = "__main__"
if __name__ == "__main__":

    # TODO: Validation on the argument

    #partition_date = (DT.date.today() - DT.timedelta(days=1)).strftime("%Y%m%d")
    partition_date = argv[1] # in YYYYMMDD format

    try:
        main(partition_date)
    except Exception as e:
        print(e)
        traceback.print_tb(e.__traceback__)