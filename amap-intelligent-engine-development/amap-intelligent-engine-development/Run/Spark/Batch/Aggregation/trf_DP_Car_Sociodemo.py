from pyspark.sql import SparkSession
from pyspark.context import SparkContext
from pyhive import hive
import pandas as pd
import traceback
import datetime as DT
from sys import argv
import numpy as np
from datetime import date

# Custom Import
import sys
sys.path.append('/tmp/Libraries')
from ie_hive_connection import IEHiveConnection


def fetch_from_hive(spark_session, query, database: str = 'default'):
    # Create connection
    conn = IEHiveConnection(database=database)

    # read in pandas and conver to hive
    result = pd.read_sql(query, conn)
    print("query done")
    print(result.columns)
    row_count = result.shape[0]

    # Check row_count returned from Hive query
    if (row_count == 0):
        print("query returned 0-rows")

    result = result.replace({np.nan: None})
    conn.close()

    return result


def main(partition_date: str, host: str, user: str, password: str, hive_db: str) -> None:
    # Configure Spark
    spark_session = SparkSession.builder \
        .config("hive.exec.dynamic.partition.mode", "nonstrict") \
        .enableHiveSupport() \
        .getOrCreate()
    spark_session.sql(f"USE {hive_db}")

    # Get Context
    spark_context = SparkContext.getOrCreate()
    spark_context.setLogLevel("INFO")  # ALL, DEBUG, ERROR, FATAL, INFO, OFF, TRACE, WARN

    query = "SELECT dp_userid, TRIM(LOWER(attribute_name)) as attribute_name, attribute_value, partition_date FROM STG_DP_Useranagraphic WHERE partition_date = {}".format(
        partition_date)

    result = fetch_from_hive(spark_session, query)
    result.drop_duplicates()

    if result.empty:
        print("No new data to ingest")
        return 0
    else:
        car_sociodemo = result.pivot(index='dp_userid', columns=['attribute_name'], values='attribute_value')
        car_sociodemo = car_sociodemo.fillna('').reset_index()
        car_sociodemo.columns = car_sociodemo.columns.str.replace(' ', '_')
        # Write code to convert the column ('Date of birth') to 'Age' column and added the column 'Age' to the code
        print(car_sociodemo.columns)
        if 'age' in car_sociodemo.columns:
            car_sociodemo['partition_date'] = partition_date
        else:
            car_sociodemo['date_of_birth'] = car_sociodemo['date_of_birth'].apply(pd.to_datetime).dt.date
            today = date.today()
            car_sociodemo['age'] = car_sociodemo['date_of_birth'].apply(
                lambda x: today.year - x.year - ((today.month, today.day) < (x.month, x.day))).fillna(0).astype(
                np.int64)
            car_sociodemo['age'] = car_sociodemo['age'].apply(lambda x: '' if x == 0 else str(x)).astype(str)
            car_sociodemo['date_of_birth'] = car_sociodemo['date_of_birth'].fillna('').astype(str)
            car_sociodemo['partition_date'] = partition_date

    # Write result to Mysql
    df = spark_session.createDataFrame(car_sociodemo)
    df.write.mode("overwrite").format("jdbc") \
        .option("driver", "org.mariadb.jdbc.Driver") \
        .option("url", "jdbc:mysql://" + host + ":3306/data_activation") \
        .option("dbtable", "DP_Car_Sociodemo") \
        .option("user", user) \
        .option("password", password).save()

    print('New data to ingest found')
    print('[SUCCESS] All done!')


__name__ = "__main__"
if __name__ == "__main__":

    partition_date = argv[1]  # in YYYYMMDD format
    host = argv[2]
    user = argv[3]
    password = argv[4]
    hive_db = 'default'

    try:
        main(partition_date, host, user, password, hive_db)
    except Exception as e:
        print(e)
        traceback.print_tb(e.__traceback__)
