# Imports
import pandas as pd
import traceback
import datetime as DT
from sys import argv
import numpy as np

# Import ML
from pyspark.sql.functions import when
import pyspark.sql.functions as F
from pyspark.sql.types import FloatType
from pyspark import SparkContext
from pyspark.sql import SparkSession
from pyspark.sql.types import *
from pyspark.sql.functions import col,lit

# Custom Import
import sys
sys.path.append('/tmp/Libraries')
from ie_hive_connection import IEHiveConnection

def fetch_from_hive(spark_session, query, schema, database: str = 'default'):
    # Create connection
    conn = IEHiveConnection(database=database)

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



def load_to_hive(df, table_name, partitioned: str, today: str, database: str = 'default') -> None:
    # Use this function if Bucketing is ENABLED
    # This is a workaround becouse spark 3.0.1 does not yet support writing into bucketed tables
    # See: https://issues.apache.org/jira/browse/SPARK-19256

    if df.head(1):
        print("[DM3][INFO] DF is populated: Writing to data to Hive")

        # Add partition column
        if partitioned:
            df = df.withColumn(partitioned, F.lit(int(today)))
            print("[DM3][INFO] Added partition column")

        # Save temp table
        df.write.saveAsTable("{table_name}_staging".format(table_name = table_name))

        # PyHive is faster then using the HIVE CLI command
        conn = IEHiveConnection(database=database)

        # Since dynamic partitioning is enabled I do not need to specity the partition column in the insert
        cursor = conn.cursor()
        cursor.execute("INSERT OVERWRITE TABLE {table_name} SELECT * FROM {table_name}_staging".format(table_name = table_name))
        conn.close()
        print("Data written into table: {}".format(table_name))
    else:
        print("[DM3][ERROR] The DF has not elements, please check the validation rules")



def main(partition_date: str, database: str = 'default') -> None:
    spark_session = SparkSession.builder \
        .config("hive.exec.dynamic.partition.mode", "nonstrict") \
        .enableHiveSupport() \
        .getOrCreate()
    spark_session.sql(f"USE {database}")

    # Get Context
    spark_context = SparkContext.getOrCreate()
    spark_context.setLogLevel("INFO")

	# Queries
    query_trf_adv_joinedwith_mrkt_ordr = "SELECT DISTINCT trf_advertiser.advertiser_id as advertiser_id, trf_advertiser.advertiser_name as advertiser_name, trf_advertiser.brand_name as brand_name, trf_advertiser.industry as industry, market_order.market_order_line_details_id as market_order_line_details_id, market_order.media_type as media_type, market_order.length as length, market_order.total_price as budget, nvl(market_order.format_id, '*****') as format_id,market_order.market_product_type_id as market_product_type_id FROM (select * from trf_advertiser where partition_date = {} limit 50) trf_advertiser join (SELECT m.advertiser_id	,m.brand_name ,n.market_order_line AS market_order_line_details_id ,n.mediatype AS media_type ,n.length ,n.total_price ,n.format as format_id ,n.market_product_type AS market_product_type_id FROM STG_SA_Market_Order M INNER JOIN TRF_market_order_line_details N ON m.market_order_id = n.market_order_id where M.partition_date = {} and n.partition_date = {}) market_order  on trf_advertiser.advertiser_id = market_order.advertiser_id".format(partition_date, partition_date, partition_date)
    query_catalogitem = "SELECT DISTINCT catalog_item_id, parent_id,  cast(catalog_level as string) as catalog_level, record_type, display_name FROM stg_sa_catalogitem where partition_date = {}".format(partition_date)

	
	# Columns Schema
    schema_trf_adv_joinedwith_mrkt_ordr = StructType([
        StructField('advertiser_id', StringType(), True),
        StructField('advertiser_name', StringType(), True),
        StructField('brand_name', StringType(), True),
        StructField('industry', StringType(), True),
        StructField('market_order_line_details_id', StringType(), True),
        StructField('media_type', StringType(), True),
        StructField('length', StringType(), True),
        StructField('budget', DoubleType(), True),
        StructField('format_id', StringType(), True),
        StructField('market_product_type_id', StringType(), True)
        ])


    schema_catalogitem = StructType([
        StructField('catalog_item_id', StringType(), True),
        StructField('parent_id', StringType(), True),
        StructField('catalog_level', StringType(), True),
        StructField('record_type', StringType(), True),
        StructField('display_name', StringType(), True)
        ])

    DF_trf_adv_joined_with_mrkt_ordr = fetch_from_hive(spark_session, query_trf_adv_joinedwith_mrkt_ordr, schema_trf_adv_joinedwith_mrkt_ordr)
    if(DF_trf_adv_joined_with_mrkt_ordr == 0):
        print("<<<<<<<< There are no rows in trf_advertiser table for partition_date = {} >>>>>>>".format(partition_date))
        return

    DF_catalogitem = fetch_from_hive(spark_session, query_catalogitem, schema_catalogitem)


    # Create Empty RDD
    empty_RDD = spark_context.emptyRDD()

	# Structure of the output DataFrame
    columns = StructType([
        StructField('advertiser_id', StringType(), True),
        StructField('advertiser_name', StringType(), True),
        StructField('brand_name', StringType(), True),
        StructField('industry', StringType(), True),
        StructField('market_order_line_details_id', StringType(), True),
        StructField('catalog_level', StringType(), True),
        StructField('record_type', StringType(), True),
        StructField('media_type', StringType(), True),
        StructField('length', StringType(), True),
        StructField('display_name', StringType(), True),
        StructField('budget', DoubleType(), True),
        StructField('market_product_type_id', StringType(), True)
        ])

    # Create Empty DataFrame
    DF_trf_advertiser_spec = spark_session.createDataFrame(data = empty_RDD, schema = columns)



    # Import trf_advertiser and market_order JOINED data to Spark DataFrame

    if(DF_trf_adv_joined_with_mrkt_ordr != 0 and DF_catalogitem == 0):
        print("<<<<<  DF_trf_adv_joined_with_mrkt_ordr has data and but DF_catalogitem has no data  >>>>>")
        stgDF = DF_trf_adv_joined_with_mrkt_ordr.select(col("advertiser_id"), col("advertiser_name"), col("brand_name"), col("industry"),col("market_order_line_details_id"), lit("").alias("catalog_level"), lit("").alias("record_type"),col("media_type"),col("length"), lit("").alias("display_name"),col("budget"),col("market_product_type_id"))
        DF_trf_advertiser_spec = DF_trf_advertiser_spec.union(stgDF)
        return



    # Logic to load the DF_trf_advertiser_spec DataFrame
    for row in DF_trf_adv_joined_with_mrkt_ordr.rdd.collect():
        key = row.format_id
        while True:
            if(key == row.format_id):
                stgDF = DF_catalogitem.select( lit(row.advertiser_id).alias("advertiser_id"),lit(row.advertiser_name).alias("advertiser_name"),lit(row.brand_name).alias("brand_name"),lit(row.industry).alias("industry"),lit(row.market_order_line_details_id).alias("market_order_line_details_id"),col("catalog_level"),col("record_type"),lit(row.media_type).alias("media_type"),lit(row.length).alias("length"),col("display_name"),lit(row.budget).alias("budget"),lit(row.market_product_type_id).alias("market_product_type_id")).filter(col("catalog_item_id") == lit(key))
                if(stgDF.count() == 0):
                    stgDF = DF_trf_adv_joined_with_mrkt_ordr.select(col("advertiser_id"), col("advertiser_name"), col("brand_name"), col("industry"),col("market_order_line_details_id"), lit("").alias("catalog_level"), lit("").alias("record_type"),col("media_type"),col("length"), lit("").alias("display_name"),col("budget"),col("market_product_type_id")).filter(col("format_id") == lit(key))
                    DF_trf_advertiser_spec = DF_trf_advertiser_spec.union(stgDF)
                    break
					
                else:
                    stgDF = DF_catalogitem.select( lit(row.advertiser_id).alias("advertiser_id"),lit(row.advertiser_name).alias("advertiser_name"),lit(row.brand_name).alias("brand_name"),lit(row.industry).alias("industry"),lit(row.market_order_line_details_id).alias("market_order_line_details_id"),col("catalog_level"),col("record_type"),lit(row.media_type).alias("media_type"),lit(row.length).alias("length"),col("display_name"),lit(row.budget).alias("budget"),lit(row.market_product_type_id).alias("market_product_type_id")).filter(col("catalog_item_id") == lit(key))
                    DF_trf_advertiser_spec = DF_trf_advertiser_spec.union(stgDF)
                    key = DF_catalogitem.select("parent_id").filter(DF_catalogitem.catalog_item_id == lit(key)).collect()
                    if key:
                        key = key[0][0]
    					
            else:
                stgDF = DF_catalogitem.select( lit(row.advertiser_id).alias("advertiser_id"),lit(row.advertiser_name).alias("advertiser_name"),lit(row.brand_name).alias("brand_name"),lit(row.industry).alias("industry"),lit(row.market_order_line_details_id).alias("market_order_line_details_id"),col("catalog_level"),col("record_type"),lit(row.media_type).alias("media_type"),lit(row.length).alias("length"),col("display_name"),lit(row.budget).alias("budget"),lit(row.market_product_type_id).alias("market_product_type_id")).filter(col("catalog_item_id") == lit(key))
                DF_trf_advertiser_spec = DF_trf_advertiser_spec.union(stgDF)
                key = DF_catalogitem.select("parent_id").filter(DF_catalogitem.catalog_item_id == lit(key)).collect()
                if key:
                    key = key[0][0]
    		
            if key:
                continue
    				
            else:
                break
    				
    distinctDF_trf_advertiser_spec = DF_trf_advertiser_spec.distinct()
	
    # Write result to hive
    # drop old staging
    try:
        spark_session.sql("DROP TABLE {}_staging".format('trf_advertiser_spec'))
    except:
        print("[DEBUG] staging table doesn't exist")
    finally:
        load_to_hive(distinctDF_trf_advertiser_spec, 'trf_advertiser_spec', 'partition_date', partition_date)
        spark_session.sql("DROP TABLE {}_staging".format('trf_advertiser_spec'))

    print('[SUCCESS] All done!')
	
	

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
