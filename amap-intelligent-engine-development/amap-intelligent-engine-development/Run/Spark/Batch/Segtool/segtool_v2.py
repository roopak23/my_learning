# Python imports
from sys import argv
import pymysql
from pymysql import Error
from pyhive import hive
import pandas as pd
import traceback

# Spark Imports
from pyspark.sql import HiveContext
from pyspark.context import SparkContext
import pyspark.sql.functions as F
from pyspark.sql.types import *

def fetch_from_hive(sql_Context,spark_Context, query):
    # Create connection
    conn = hive.Connection(
        host="localhost",
        port=10000,
        username="hadoop",
        configuration={'hive.txn.manager': 'org.apache.hadoop.hive.ql.lockmgr.DbTxnManager'}
    )

    # read in pandas and conver to hive
    result = pd.read_sql(query, conn)
    print("Data found: {}".format(result.count()))
    
    try:
        cols_remap = {key:key.split(".")[1] for key in result.columns }
        result.rename(columns=cols_remap, inplace = True)
    except:
        print("No column to remap")
    finally:
        try:
            df = sql_Context.createDataFrame(result)
            print("converted to spark")

        except Exception as e:
            print("DF Is EMPTY: {}".format(e))
            schema = StructType([
                StructField("userid",StringType(),False),
                StructField("segmentid",IntegerType(),False)
            ])
            df = sql_Context.createDataFrame(spark_Context.emptyRDD(), schema)
        finally:
            conn.close()

    return df

def load_to_hive(df, table_name, partitioned: str, today: str) -> None:
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
        from pyhive import hive
        conn = hive.Connection(
            host="localhost",
            port=10000,
            username="hadoop",
            configuration={'hive.txn.manager': 'org.apache.hadoop.hive.ql.lockmgr.DbTxnManager'}
        )

        # Since dynamic partitioning is enabled I do not need to specity the partition column in the insert
        cursor = conn.cursor()
        cursor.execute("INSERT OVERWRITE TABLE {table_name} SELECT * FROM {table_name}_staging".format(table_name = table_name))
        conn.close()
        print("Data written into table: {}".format(table_name))
    else:
        print("[DM3][ERROR] The DF has not elements, please check the validation rules")


def create_mysql_connection(host, database, port, user, password):
    try:
        connection = pymysql.connect(
            host=host,
            database=database,
            port=port,
            user=user,
            password=password)
    except Error as e:
        print(f"The error '{e}' occurred")
        raise ConnectionError("mySQL Connection Failed.")
    return connection

def main(output_table, host, database, port, user, password, partition_date):
    # Get active segments
    seg_query = "SELECT id, sql_query FROM segments WHERE active = 'Y'"
    conn = create_mysql_connection(host, database, port, user, password)
    cur = conn.cursor()
    cur.execute(seg_query)
    data = cur.fetchall()

    # Get Context
    sc = SparkContext.getOrCreate()

    # Configure Spark
    sqlContext = HiveContext(sc)

    # Create empty df
    schema = StructType([
        StructField("userid",StringType(),False),
        StructField("segmentid",IntegerType(),False)
    ])
    df_segments = sqlContext.createDataFrame(sc.emptyRDD(), schema)

    # For each segment execute hive query and append
    for segment in data:
        id = segment[0]
        query = eval(segment[1])["A"].replace("\\", "")
        print(query)
        
        print("Executing segment: {}".format(id))
        df_tmp = fetch_from_hive(sqlContext,sc, query).withColumn("segmentid", F.lit(id))
        df_segments = df_segments.unionAll(df_tmp)

    # Write result to hive
    # drop old stagin
    try:
        sqlContext.sql("DROP TABLE {}_staging".format(output_table))
    except Exception as e:
        print("[DEBUG] staging table doesn't exist: {}".format(e))
    finally:
        load_to_hive(df_segments, output_table, 'partition_date', partition_date)
        try:
            sqlContext.sql("DROP TABLE {}_staging".format(output_table))
        except Exception as e:
            print("[DEBUG] staging table doesn't exist: {}".format(e))

        

    # BYEEEE

# Templated variables
__name__ = "__main__"
if __name__ == "__main__":
    # TODO: Validation on the argument

    # =============== CONFIGS ===============
    # output_table = trg_user_segment_mapping
    # partition_date = 20210914
    # =======================================

    # Tables
    output_table = argv[1]

    # DB conn
    host=argv[2]
    database=argv[3]
    port=int(argv[4])
    user=argv[5]
    password=argv[6]

    # Partition must be the last
    partition_date = argv[7]

    main(output_table, host, database, port, user, password, partition_date)

# EOF
