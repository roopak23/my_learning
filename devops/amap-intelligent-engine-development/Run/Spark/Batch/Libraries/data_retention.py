# Imports
import pandas as pd
import traceback
import sys
from sys import argv

from pyspark.sql import SparkSession
from pyspark.sql.types import *
from pyspark.sql.functions import col,lit
from datetime import datetime
from dateutil.relativedelta import relativedelta

sys.path.append('/tmp/Libraries')
from ie_hive_connection import IEHiveConnection



def query_on_hive(spark, table_name, number_of_days, latest_dates, database: str = 'default'):
    # Create connection
    conn = IEHiveConnection(database=database)
    schema_partition_date = StructType([StructField('partition_date', IntegerType(), True)])
    query_check = f"select * from {table_name} limit 1"
    result_check = pd.read_sql(query_check, conn)
    row_count_check = result_check.shape[0]
    print(row_count_check)
    if(row_count_check > 0):
        
        query_partitions_na = """select distinct partition_date from {} where partition_date not in ({})""".format(table_name,",".join(str(value) for value in latest_dates))
        result = pd.read_sql(query_partitions_na, conn)
        df = spark.createDataFrame(result, schema_partition_date)
        pdates_na = df.select(col("partition_date")).rdd.flatMap(lambda x: x).collect()
        if(len(pdates_na) > 0):
            for pdate in pdates_na:
                query = f"ALTER TABLE {table_name} DROP PARTITION (partition_Date={pdate})"
                print(query)
                cursor = conn.cursor()
                cursor.execute(query)
            conn.close()
            return 1
        else:
            print(f"There are no older partitions to be dropped in the table {table_name}")
        return 0
    else:
        print(f"There is no data in the table {table_name}")
        return 0


def main(number_of_days: int, table_name: str, partition_date:str, database: str = 'default') -> None:
    print(f"TABLE_NAME --> {table_name}")
    print(f"Number of Days data needs to retained --> {number_of_days}")
    print(f"partition_date is --> {partition_date}")
    spark_session = SparkSession.builder \
        .config("hive.exec.dynamic.partition.mode", "nonstrict") \
        .enableHiveSupport() \
        .getOrCreate()
    spark_session.sql(f"USE {database}")
    today_date = datetime.strptime(partition_date, '%Y%m%d')
    latest_dates = [today_date - relativedelta(days=i) for i in range(number_of_days)]
    latest_dates_str = [date.strftime('%Y%m%d') for date in latest_dates]
    print(f"latest dates --> {latest_dates_str}")

    if(number_of_days > 0):

        result = query_on_hive(spark_session, table_name, number_of_days, latest_dates_str)
        if result == 0:
            print(f"Data retention of the {table_name} is unsuccessful due to empty data/no data with older partitions")
        else:
            print(f"Data retention of the {table_name} is successful")
    else:
        print(f"Value of the parameter number_of_days is invalid: {number_of_days}")


__name__ = "__main__"
if __name__ == "__main__":

    table_name = argv[1].lower()
    number_of_days = int(argv[2])
    partition_date = argv[3]

    try:
        main(number_of_days, table_name, partition_date)
    except Exception as e:
        print(e)
        traceback.print_tb(e.__traceback__)
