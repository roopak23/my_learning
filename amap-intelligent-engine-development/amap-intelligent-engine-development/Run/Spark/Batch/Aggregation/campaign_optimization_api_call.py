import sys
from pyspark.sql import SparkSession
from pyspark.context import SparkContext

if __name__ == "__main__":
    try:
        spark_session = SparkSession.builder \
            .config("hive.exec.dynamic.partition.mode", "nonstrict") \
            .enableHiveSupport() \
            .getOrCreate()
        print('spark_session')
        spark_context = SparkContext.getOrCreate()
        spark_context.setLogLevel("INFO")
        print('spark_context')

        print(sys.version)
        print('Start...')
        print('Campaign_Monitoring/Optimization API Call')
        print('Empty Script')
        print('...End')

    except Exception as e:
        print(e)
