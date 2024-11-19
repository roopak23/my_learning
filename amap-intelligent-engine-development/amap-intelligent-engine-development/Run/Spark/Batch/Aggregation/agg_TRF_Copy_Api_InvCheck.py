from datetime import datetime
import sys

# Script to prepare api_inventorycheckupdate

from pyspark.sql import SparkSession,functions as F
import pymysql
sys.path.append('/tmp/Libraries')
from ie_hive_connection import IEHiveConnection



def now() -> str:
    return datetime.now().strftime("%Y/%m/%d, %H:%M:%S")

def drop_staging(table_name):
    try:
        spark_session.sql("DROP TABLE {}_staging PURGE ".format(table_name))
    except Exception as e:
        print(f"[IE][INFO][{now()}] There is no staging table to drop")
            # print(f"[IE][INFO][{now()}] {e}")
            
def load_to_hive(df, table_name: str, partitioned: str, today: str, mode: str, preffix: str = '', database: str = 'default') -> None:
    '''
    Use this function if Bucketing is ENABLED
    This is a workaround becouse spark 3.0.1 does not yet support writing into bucketed tables
    See: https://issues.apache.org/jira/browse/SPARK-19256
    mode: "append"/"overwrite"
    '''
    print(f"[IE][INFO][{now()}] Entering load_to_hive fn for table {preffix}{table_name}")
    modes = {"append": "INTO", "overwrite": "OVERWRITE"}

    mode = mode.lower()

    # Raises an Error if function get wrong mode value
    if mode not in modes.keys():
        raise KeyError(f"[IE][ERROR][{now()}] Mode should be append or overwrite")

    print(f"[IE][INFO][{now()}] DF is populated: Writing to data to Hive")

    # Add partition column
    if partitioned:
        print(f"[IE][INFO][{now()}] Today {today} ")
        #df = df.withColumn(partitioned, F.lit(int(today)))
        print(f"[IE][INFO][{now()}] Added partition column")
        
        

        
    drop_staging(table_name)

    # Save temp table
    try:
        print(f"[IE][INFO][{now()}] Trying to saveAsTable {preffix}{table_name}_staging")
        df.write.mode("overwrite").saveAsTable(f"{preffix}{table_name}_staging")
    except Exception as ex:
        print(f"[IE][ERROR][{now()}] Saving temp {preffix}{table_name}_staging table error: {ex}")
        raise ex
    
    print(f"[IE][INFO][{now()}] Saving temp {preffix}{table_name}_staging done")

    # PyHive is faster then using the HIVE CLI command
    try:
        print(f"[IE][INFO][{now()}] Creating IEHiveConnection")
        conn = IEHiveConnection()
        print(f"[IE][INFO][{now()}] Connection id: {conn}")
    except Exception as ex:
        print(f"[IE][ERROR][{now()}] Can't connect!")
        print(f"[IE][ERROR][{now()}] {ex}")
        raise ex

    try:
        # Since dynamic partitioning is enabled I do not need to specity the partition column in the insert
        print(f"[IE][INFO][{now()}] Creating cursor")
        cursor = conn.cursor()
        print(f"[IE][INFO][{now()}] Executing INSERT {modes[mode]} TABLE {table_name} PARTITION({partitioned} = {int(today)})  SELECT * FROM {preffix}{table_name}_staging")
        cursor.execute(f"INSERT {modes[mode]} TABLE {table_name} PARTITION({partitioned} = {int(today)}) SELECT * FROM {preffix}{table_name}_staging")
        print(f"[IE][INFO][{now()}] Insertion ended")
    except Exception as ex:
        print(f"[IE][ERROR][{now()}] Saving table {table_name} error: {ex}")
        raise ex
    finally:
        print(f"[IE][INFO][{now()}] Closing Hive connection")
        conn.close()
        print(f"[IE][INFO][{now()}] Connection closed")

    print(f"[IE][INFO][{now()}] Data written into table: {table_name}")
    drop_staging(table_name)
 
 
def mark_process_started():
        connection = pymysql.connect(
        host=aws_rds_connection,
        user=rds_sql_user,
        password=rds_sql_pass,
        database=rdssql_schema
    )
        
        cursor = connection.cursor()
        try:
            cursor.execute("UPDATE batch_status SET date=NOW(), status = 'RUNNING'")
            connection.commit()
            print("[IE][INFO][{now()}] Mark Process Start Completed")
        except Exception as e:
            print(f"[IE][INFO][{now()}] Error truncating table: {e}")
            raise e
        finally:
            cursor.close()
            connection.close()
##########################################################################            

def main():
    
    
    mark_process_started()
    def ReadTable(rds_sql_user, rds_sql_pass, aws_rds_connection, rdssql_schema, table_name, partition_column, num_partitions):
        print(f"[IE][INFO][{now()}] Table {table_name} read started ")
        
        
        
        query = f"SELECT coalesce(MIN({partition_column}),1), coalesce(MAX({partition_column}),1) FROM {table_name} "
        
        min_max_df = spark_session.read \
        	.format("jdbc") \
        	.option('url', f'jdbc:mysql://{aws_rds_connection}:3306/{rdssql_schema}?&useSSL=true&trustServerCertificate=true')\
            .option("driver", "org.mariadb.jdbc.Driver")\
        	.option("user", rds_sql_user )\
        	.option("password", rds_sql_pass ) \
        	.option("query", query) \
        	.load()
        	
        lower_bound, upper_bound = min_max_df.collect()[0]

        query = f"SELECT * FROM {table_name}"
        
        dbtable = f"({query}) AS subq"
        
        df = spark_session.read.format("jdbc")\
            .option('url', f'jdbc:mysql://{aws_rds_connection}:3306/{rdssql_schema}?&useSSL=true&trustServerCertificate=true')\
            .option("driver", "org.mariadb.jdbc.Driver")\
            .option("dbtable", dbtable)\
            .option("user", rds_sql_user)\
            .option("password", rds_sql_pass)\
            .option("partitionColumn", partition_column)\
            .option("lowerBound", lower_bound)\
            .option("upperBound", upper_bound)\
            .option("numPartitions", num_partitions)\
            .option("isolationLevel", 'NONE') \
            .load()
            
        print(f"[IE][INFO][{now()}]. Table {table_name} read completed ")
       
        return df
        

    spark_api_inventorycheck = ReadTable(rds_sql_user, rds_sql_pass, aws_rds_connection, rdssql_schema, 'api_inventorycheck', partition_column='id', num_partitions=20)

    load_to_hive(spark_api_inventorycheck, 'api_inventorycheck', 'partition_date', datetime.now().strftime('%Y%m%d%H%M'),'OVERWRITE')
  


    
if __name__ == "__main__":
    partition_date = int(sys.argv[1])  # in YYYYMMDD format
    aws_rds_connection = sys.argv[2]
    rds_sql_user = sys.argv[3]
    rds_sql_pass = sys.argv[4]
    rdssql_schema = "data_activation"
    
    
    
    spark_session = SparkSession.builder \
        .config("hive.exec.dynamic.partition.mode", "nonstrict") \
        .enableHiveSupport() \
        .getOrCreate()
    spark_session.sql(f"use default")
    

    main()

