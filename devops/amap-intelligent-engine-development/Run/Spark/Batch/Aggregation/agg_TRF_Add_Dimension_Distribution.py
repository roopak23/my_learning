# -*- coding: utf-8 -*-
"""
Created on Thu Apr 11 18:14:39 2024

@author: dipan.arya
"""

from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.window import Window
from pyspark.sql import DataFrame
from pyspark.sql import *
from datetime import datetime, timedelta
import traceback
import pymysql

# Custom Import
import sys
sys.path.append('/tmp/Libraries')
from ie_hive_connection import IEHiveConnection

lookback_period = 30

# rds sql configurations
rdssql_schema = 'data_activation'
forecasting_result_table = 'ML_InvForecastingOutputSegment'
forecasting_result_table_filter = ' '
rds_list_columns = 'adserver_id,adserver_adslot_id, date,metric,future_capacity'


# hive related configurations
dtf_addnal_dimensn = 'trf_dtf_additional_dimensions'
distribution_combination = ['adserver_adslot_id', 'adserver_id', 'state', 'city', 'event','pod_position','video_position']
analysis_variable = 'impressions'
join_with_forecast = ["adserver_id","adserver_adslot_id"]

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
        print("[DM3][INFO] Save temp table")
        df.write.saveAsTable("{table_name}_staging".format(table_name = table_name))
        print("[DM3][INFO] Save temp table completed")

        # PyHive is faster then using the HIVE CLI command
        conn = IEHiveConnection(database=database)

        # Since dynamic partitioning is enabled I do not need to specity the partition column in the insert
        cursor = conn.cursor()
        print("[DM3][INFO] Copy to Target Table")
        cursor.execute("INSERT OVERWRITE TABLE {table_name} SELECT * FROM {table_name}_staging".format(table_name = table_name))
        print("[DM3][INFO] Copy to Target Table Copleted ")
        conn.close()
        print("Data written into table: {}".format(table_name))
    else:
        print("[DM3][ERROR] The DF has not elements, please check the validation rules")

def main (partition_date: str) -> None:

    def get_start_date(end_date: str,lookback_period ) -> str:
        # Convert the end date string to a datetime object
        end_date_obj = datetime.strptime(end_date, "%Y%m%d")
        # Calculate the start date 30 days before the end date
        start_date_obj = end_date_obj - timedelta(days=30)
        # Format the start date as "YYYYMMDD" string
        start_date_str = start_date_obj.strftime("%Y%m%d")
        return start_date_str
    
    spark_session = SparkSession.builder \
            .config("hive.exec.dynamic.partition.mode", "nonstrict") \
            .enableHiveSupport() \
            .getOrCreate()
    
    
    dtf_addnal_dimensn_end_date = partition_date
    dtf_addnal_dimensn_start_date = get_start_date(str(dtf_addnal_dimensn_end_date),lookback_period)
    dtf_addnal_dimensn_filter = " where partition_date >= " + dtf_addnal_dimensn_start_date +" and partition_date<= "+str(dtf_addnal_dimensn_end_date)
    
    distribution_df = spark_session.sql('select * from '+dtf_addnal_dimensn+' '+dtf_addnal_dimensn_filter)

    distribution_df = distribution_df.withColumn('pod_position',F.col('pod_position')).fillna('')
    distribution_df = distribution_df.withColumn('video_position',F.col('video_position')).fillna('')
    
    
    #min_value = distribution_df.select(min('partition_date')).first()[0]
    #max_value = distribution_df.select(max('partition_date')).first()[0]
    
    #print(f"min partition date ::: {min_value}")
    #print(f"max partition date ::: {max_value}")
    
    forecasting_df = spark_session.read.format("jdbc")\
    .option('url','jdbc:mysql://'+ aws_rds_connection +':3306/'+rdssql_schema+'?&useSSL=true&trustServerCertificate=true')\
    .option("driver","org.mariadb.jdbc.Driver")\
    .option("query","select "+rds_list_columns+" from "+rdssql_schema+"."+forecasting_result_table+" "+forecasting_result_table_filter)\
    .option("user",rds_sql_user)\
    .option("password",rds_sql_pass)\
    .load()
    
    def rename_columns(df: DataFrame, column_mappings: dict = None, columns_to_drop: list = None) -> DataFrame:
        if columns_to_drop:
            df = df.drop(*columns_to_drop)
        if column_mappings:
            existing_columns = df.columns
            renamed_columns = []
            error_message = ""
            for old_name, new_name in column_mappings.items():
                if old_name not in existing_columns:
                    error_message += f"Column '{old_name}' does not exist in the DataFrame.\n"
                if new_name in existing_columns:
                    error_message += f"Warning: Column '{new_name}' already exists in the DataFrame.\n"
                if old_name in existing_columns and new_name not in existing_columns:
                    renamed_columns.append(new_name)
            if error_message:
                raise ValueError(error_message)
            for old_name, new_name in column_mappings.items():
                df = df.withColumnRenamed(old_name, new_name)
        return df
    
    # distribution_df = rename_columns(distribution_df, rename_column_for_distribution_df)
    distribution_totals = distribution_df.groupby(distribution_combination).agg(F.sum(analysis_variable).alias("total_"+analysis_variable))
    
    adslot_id_totals = distribution_df.groupby(join_with_forecast).agg(F.sum(analysis_variable).alias("total_"+analysis_variable+"_at_adslot_id"))
    
    distribution_totals = distribution_totals.join(adslot_id_totals, on=join_with_forecast, how="left")
    
    joined_df = distribution_totals.withColumn("distribution_ratio", F.col("total_"+analysis_variable) / F.col("total_"+analysis_variable+"_at_adslot_id"))
    join_with_forecast_ratio = join_with_forecast.copy()
    join_with_forecast_ratio.append('distribution_ratio')
    
    # joined_df.write.mode("overwrite").saveAsTable('joined_df')
    
    #forecasting_df
    
    # join_with_forecast = ['adserver_adslot_id'] #----Change Comment this when adserverid starts matching
    
    joined_df_with_ratio = forecasting_df.select('adserver_id','adserver_adslot_id','date','metric','future_capacity').join(joined_df.select(list(set(join_with_forecast_ratio+distribution_combination))), on=join_with_forecast, how="left")
    
    #uncommon_columns = [col for col in joined_df_with_ratio.columns if col not in forecasting_df.columns].append(join_with_forecast)
    
    joined_df_with_ratio.show()
    
    # Apply distribution ratio to forecasted capacity
    final_df = joined_df_with_ratio.withColumn("distributed_capacity", F.col("distribution_ratio") * F.col("future_capacity"))
    
    columns_to_drop = ['distribution_ratio']
    rename_column_for_distribution_df  = {'future_capacity':'future_capacity_adslot','distributed_capacity': 'future_capacity_distributed'}
    
    final_df_distributed = rename_columns(final_df, rename_column_for_distribution_df,columns_to_drop)
        
    final_distributed_df = final_df_distributed.select('date','adserver_id', 'adserver_adslot_id','state','city','event','pod_position','video_position','metric','future_capacity_distributed','future_capacity_adslot')\
        .orderBy('adserver_id','adserver_adslot_id', 'date', 'state','city','event','pod_position','video_position')
        
    final_distributed_df.createOrReplaceTempView ("final_distributed_df")
    
    #future_capacity_adslot is the same around dimention sso we can use max to get one record
    
    final_distributed_df = spark_session.sql ("SELECT `date`, adserver_id, adserver_adslot_id , `state`, city , COALESCE (event, 'NA') AS event, pod_position,  video_position, metric, SUM(future_capacity_distributed) AS future_capacity, max(future_capacity_adslot) AS future_capacity_adslot  FROM  final_distributed_df WHERE pod_position is NOT NULL GROUP BY `date`,adserver_id,adserver_adslot_id, metric, `state`, city, event, pod_position, video_position ")
    
    final_distributed_df.show(truncate=False)
    
    # Write result to hive
    # drop old staging
    try:
        spark_session.sql("DROP TABLE {}_staging".format('ML_InvForecastingOutputSegmentDistributed'))
    except:
        print("[DEBUG] staging table doesn't exist")
    finally:
        load_to_hive(final_distributed_df, 'ML_InvForecastingOutputSegmentDistributed', 'partition_date', partition_date)
        spark_session.sql("DROP TABLE  {}_staging".format('ML_InvForecastingOutputSegmentDistributed'))
        
    
    #jdbc_url = 'jdbc:mysql://'+ aws_rds_connection +':3306/'+rdssql_schema+'?&useSSL=true&trustServerCertificate=true'
    #connection_properties = {
    #    "user": rds_sql_user,
    #    "password": rds_sql_pass,
    #    "driver": "org.mariadb.jdbc.Driver"
    #}
    
    # def truncate_table():
    #     connection = pymysql.connect(
    #     host=aws_rds_connection,
    #     user=rds_sql_user,
    #     password=rds_sql_pass,
    #     database=rdssql_schema
    # )
    # cursor = connection.cursor()
    # try:
    #     cursor.execute("TRUNCATE ML_InvForecastingOutputSegmentDistributed")
    #     connection.commit()
    #     print("Table truncated successfully")
    # except Exception as e:
    #     print(f"Error truncating table: {e}")
    # finally:
    #     cursor.close()
    #     connection.close()


    # truncate_table()
    
    # final_distributed_df.write.option("batchsize", "1000").jdbc(
    #     url=jdbc_url,
    #     table="ML_InvForecastingOutputSegmentDistributed",
    #     mode="overwrite",  # Choose the appropriate mode: overwrite, append
    #     properties=connection_properties
    # )
       
    ### checking the capacity distribution with actual forecasted capacity ###
    
    ddd = final_df.select('date','adserver_id','adserver_adslot_id','metric','distributed_capacity')
    ddd_sum = ddd.groupby('date','adserver_id','adserver_adslot_id','metric').agg(F.sum('distributed_capacity'))
    join_ddd = ddd_sum.join(forecasting_df,on=['date','adserver_id','adserver_adslot_id','metric'], how="left")
    join_dd_comb = join_ddd.withColumn("distribution_difference_future_capacity", F.round(F.col('sum(distributed_capacity)')-F.col('future_capacity'),2))
    
    
    sum_result = join_dd_comb.selectExpr("sum(distribution_difference_future_capacity) as total_sum").collect()[0]['total_sum']
    
    print("Sum of distribution_difference_future_capacity:", sum_result)
    print("sum of difference should be zero")


#__name__ = "__main__"
if __name__ == "__main__":
    partition_date = int(sys.argv[1])  # in YYYYMMDD format
    aws_rds_connection = sys.argv[2]
    rds_sql_user = sys.argv[3]
    rds_sql_pass = sys.argv[4]
    
    
    
    spark_session = SparkSession.builder \
        .config("hive.exec.dynamic.partition.mode", "nonstrict") \
        .enableHiveSupport() \
        .getOrCreate()
    spark_session.sql(f"use default")
    
    try:
        main(partition_date)
    except Exception as e:
        print(e)
        traceback.print_tb(e.__traceback__)
        raise e
