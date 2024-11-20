# GENERAL Imports
import os
import sys
import re
import json
from sys import argv
from datetime import datetime

# Spark Imports
import pyspark.sql.functions as F
from pyspark.context import SparkContext
from pyspark.sql import DataFrame
from pyspark.sql.types import *
from pyspark.sql import SparkSession
import boto3
from py4j.protocol import Py4JJavaError
# Custom Import
sys.path.append('/tmp/Libraries')
from ie_hive_connection import IEHiveConnection


def now() -> str:
    return datetime.now().strftime("%Y/%m/%d, %H:%M:%S")


def listDirectoryFromSource(storage: str, remoteDirectoryName: str, environment: str) -> list:
    '''
    Downloads from data source to local machine
    It will accept an environment flag to manage different
    clud providers.
    Accettable values: AWS, GP, AZR
    '''

    return_list = []

    if "AWS" in environment:
        s3_resource = boto3.resource("s3")
        bucket = s3_resource.Bucket(storage)
        for s3_object in bucket.objects.filter(Prefix=remoteDirectoryName):
            # Need to split s3_object.key into path and file name, else it will give error file not found.
            path, filename = os.path.split(s3_object.key)
            if filename.endswith(".csv"):
                return_list.append(s3_object.key)

    elif "GCP" in environment:
        # TODO: Implement GCP storage
        print("NOT IMPLEMENTED YET")

    elif "AZR" in environment:
        # TODO: Imprement Azure storage
        print("NOT IMPLEMENTED YET")

    else:
        print(f"[IE][ERROR][{now()}] Environment not recognized, exiting!")
        sys.exit(1)

    return return_list


def load_to_hive(df: DataFrame, table_name: str, partitioned: str, today: str, mode: str, preffix: str = '', database: str = 'default') -> None:
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

    if df.head(1):
        print(f"[IE][INFO][{now()}] DF is populated: Writing to data to Hive")

        # Add partition column
        if partitioned:
            df = df.withColumn(partitioned, F.lit(int(today)))
            print(f"[IE][INFO][{now()}] Added partition column")

        # Save temp table
        try:
            print(f"[IE][INFO][{now()}] Trying to saveAsTable {preffix}{table_name}_staging")
            df.write.saveAsTable(f"{preffix}{table_name}_staging")
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
            print(f"[IE][INFO][{now()}] Executing INSERT {modes[mode]} TABLE {table_name} SELECT * FROM {preffix}{table_name}_staging")
            cursor.execute(f"INSERT {modes[mode]} TABLE {table_name} SELECT * FROM {preffix}{table_name}_staging")
            print(f"[IE][INFO][{now()}] Insertion ended")
        except Exception as ex:
            print(f"[IE][ERROR][{now()}] Saving table {table_name} error: {ex}")
            raise ex
        finally:
            print(f"[IE][INFO][{now()}] Closing Hive connection")
            conn.close()
            print(f"[IE][INFO][{now()}] Connection closed")

        print(f"[IE][INFO][{now()}] Data written into table: {table_name}")
    else:
        print(f"[IE][ERROR][{now()}] The DF has not elements, please check the validation rules!")


def load_to_hive_spark(df: DataFrame, table_name: str, partitioned: str, today: str) -> None:
    '''
    Use this function if Bucketing is DISABLED
    This is MUCH faster then the above
    '''

    print(f"[IE][INFO][{now()}] Inside the load_to_hive_function")
    # Add partition column
    if partitioned:
        df = df.withColumn(partitioned, F.lit(int(today)))
        print(f"[IE][INFO][{now()}] Added partition column")

    # Write to hive Table
    df.write.mode("overwrite").insertInto(table_name)
    print(f"[IE][INFO][{now()}] Data written into table: {table_name}")


def save_df_to_s3(df: DataFrame, sep: str, storage: str, path: str) -> None:
    '''
    :param df: DataFrame which will be writen as CSV on S3
    :param sep: separator, needed to separate values in CSV
    :param storage: bucket s3 when file was saved
    :param path: path when file was saved
    :return: None, just save file on S3
    '''

    filepath = f"s3a://{storage}/{path}"

    # Save df as csv file
    df.coalesce(1).write.format('csv').option("delimiter", sep).option('header', 'true').mode("append").save(filepath)

    # Create resourse session and bucket
    s3 = boto3.resource('s3')
    my_bucket = s3.Bucket(storage)

    # Select only file with data
    internal_files = [object_summary.key for object_summary in my_bucket.objects.filter(Prefix=path)]

    # Move file with data to corect dir
    s3.Object(storage, path).copy_from(CopySource=f"{storage}/{internal_files[1]}")

    # Delete not needed files
    for file in internal_files:
        s3.Object(storage, file).delete()


def main(storage: str, sourcedir: str, environment: str, TASK_ID: str, conf: dict, val: dict, today: str,
         rejected_files_dir: str, database: str = 'default') -> None:
    # Val = validator
    # Conf = configurations

    # Configure Spark
    print(f"[IE][INFO][{now()}] Creating SparkSession")
    spark_session = SparkSession.builder \
        .config("hive.exec.dynamic.partition.mode", "nonstrict") \
        .enableHiveSupport() \
        .getOrCreate()
    spark_session.sql(f"USE {database}")
    print(f"[IE][INFO][{now()}] SparkSession id: {spark_session}")

    # Get Context
    spark_context = SparkContext.getOrCreate()
    spark_context.setLogLevel("INFO")  # ALL, DEBUG, ERROR, FATAL, INFO, OFF, TRACE, WARN

    # Get the file list
    fileList = listDirectoryFromSource(storage, sourcedir, environment)

    # Load Validator
    schema = StructType()

    for item in val["fields"]:
        try:
            schema.add(item["name"], eval(item["type"]), not item["mandatory"],
                       metadata={'pk': item.get('pk') or False})  # !!! mandatory
        except KeyError as key:
            print(f"KeyError: column parameter cannot be found column: '{key}'")
            sys.exit()
        except Exception as e:
            print(f"Unexpected Error: {e}")
            sys.exit()

    # Identify files
    print(f"[IE][INFO][{now()}] File List: {fileList}")
    print(f"[IE][INFO][{now()}] Pattern: {conf['pattern']}")
    files = [f for f in fileList if re.match(conf["pattern"], f.split("/")[-1])]
    print(f"[IE][INFO][{now()}] Matched files: {files}")

    if "AWS" in environment:
        filepath = "s3://{}/".format(storage)

    elif "GCP" in environment:
        # TODO: Implement GCP storage
        print(f"[IE][ERROR][{now()}] NOT IMPLEMENTED YET!")

    elif "AZR" in environment:
        # TODO: Imprement Azure storage
        print(f"[IE][ERROR][{now()}] NOT IMPLEMENTED YET!")

    # Build the container
    df_schema = schema
    df_schema.add('sys_datasource', StringType(), True, metadata={'pk': False})
    df_schema.add('sys_load_id', LongType(), True, metadata={'pk': False})
    df_schema.add('sys_created_on', TimestampType(), True, metadata={'pk': False})
    df_schema.add('_corrupted_data_', StringType(), True, metadata={'pk': False})

    if val["config"].get('add_surrogate_id'):
        df_schema.add('surrogate_id', IntegerType(), True, metadata={'pk': False})

    df = spark_session.createDataFrame(spark_context.emptyRDD(), schema=df_schema)
    ingestion_stats_array = []
    # Perform the import
    if len(files) > 0:

        # Create schema of df with metadata
        schema_meta = StructType()

        # Adding columns parameters to the schema
        schema_meta.add('load_id', LongType(), False)
        schema_meta.add('datasource', StringType(), False)

        schema_meta.add('table_name', StringType(), False)
        schema_meta.add('total_rows', IntegerType(), False)
        schema_meta.add('non_valid_rejected', IntegerType(), False)
        schema_meta.add('mandatory_rejected', IntegerType(), False)
        schema_meta.add('duplicates_rejected', IntegerType(), False)
        schema_meta.add('dq_rejected', IntegerType(), False)
        schema_meta.add('rows_loaded', IntegerType(), False)
        schema_meta.add('partition_date', IntegerType(), False)

        # Create empty container for meta-data
        meta_data = spark_session.createDataFrame(spark_context.emptyRDD(), schema=schema_meta)

        # import custom methods
        from data_quality import total_clear, dq_clear

        # Process each file in dir
        for item in files:
            # Load csv to df
            tmp = (
                spark_session.read
                .option("mode", "PERMISSIVE")
                .load(
                    filepath + item,
                    format="csv",
                    sep=conf["delimiter"],
                    header=True,
                    schema=schema,
                    columnNameOfCorruptRecord='_corrupted_data_'
                )
            )

            # Collect file names and load time
            datasource = item.split("/")[-1]
            timestamp = datetime.utcnow()
            load_id = int(timestamp.strftime('%Y%m%d%H%M%S%f')[:-3])
            created_on = timestamp

            # Add column with name of file which ingested
            tmp = tmp.withColumn('sys_datasource', F.lit(datasource))
            print(f"[IE][INFO][{now()}] File: {datasource.upper()} -- {item}")
            # Add column with load_id
            tmp = tmp.withColumn('sys_load_id', F.lit(load_id))

            # Add column with created_on date
            tmp = tmp.withColumn('sys_created_on', F.lit(created_on))

            # CLEAR
            ingestion_stats, tmp, nonvalid_df, mandatory_df, duplicate_df = total_clear(tmp, val, df_schema, spark_context)

            # DQ check
            tmp, dq_df, blocker = dq_clear(tmp, conf["table"], df_schema, spark_context)

            # get count of DQ rejected values
            if blocker == 'y':
                ingestion_stats['dq_rejected'] = dq_df.count()
            else:
                ingestion_stats['dq_rejected'] = 0

            # Get how much is left
            ingestion_stats['rows_loaded'] = tmp.count()

            # Get partition day
            ingestion_stats['partition_date'] = int(today)

            tmp = tmp.repartition(1)

            # Union with main df
            df = df.union(tmp)

            # Create dict with meta-data
            ingestion_stats["load_id"] = load_id
            ingestion_stats["datasource"] = datasource
            ingestion_stats["table_name"] = conf["table"]

            ingestion_stats_array = []
            ingestion_stats_array.append(ingestion_stats)

            # Temporary container with data
            meta_tmp = spark_session.createDataFrame(ingestion_stats_array, schema=schema_meta)

            # Union main df with temporary
            meta_data = meta_data.union(meta_tmp)

            # Add new column with name of reject reason
            nonvalid_df = nonvalid_df.withColumn('rejected_reason', F.lit('Input Datatape deos noe match expected one'))
            mandatory_df = mandatory_df.withColumn('rejected_reason', F.lit('Mandatory field missing'))
            duplicate_df = duplicate_df.withColumn('rejected_reason', F.lit('Duplicated Row'))

            # Union 3 df to one big df
            rejected_df = nonvalid_df.union(mandatory_df).union(duplicate_df)

            # if we have n flag additional save to a new file rejected value
            if blocker == 'n' and dq_df.head(1):
                timestamp = datetime.utcnow().strftime('%Y%m%d%H%M%S%f')[:-3]
                file_name = f'{os.path.splitext(datasource)[0]}_{timestamp}.csv'
                dq_path = f'{rejected_files_dir}/{today}/fail_complements_{file_name}'
                dq_df = dq_df.withColumn('rejected_reason', F.lit('dq_check_complements'))
                try:
                    save_df_to_s3(dq_df, conf["delimiter"], storage, dq_path)
                except Py4JJavaError as ep:
                    print(f"[IE][INFO][{now()}] {ep}")
                except Exception as ex:
                    print(f"[IE][INFO][{now()}] Unexpected Error: {ex}")
            # if we have y flag add  dq rejected value to rejected_df
            elif blocker == 'y':
                dq_df = dq_df.withColumn('rejected_reason', F.lit('dq_check_validity'))
                rejected_df = rejected_df.union(dq_df)

            # Path where rejected data will be stored
            timestamp = datetime.utcnow().strftime('%Y%m%d%H%M%S%f')[:-3]
            file_name = f'{os.path.splitext(datasource)[0]}_{timestamp}.csv'
            rejected_path = f'{rejected_files_dir}/{today}/{file_name}'

            # Save rejected data to s3
            if rejected_df.head(1):
                try:
                    save_df_to_s3(rejected_df, conf["delimiter"], storage, rejected_path)
                    print(f"[IE][INFO][{now()}] All rejected rows save on s3({rejected_path})")
                except Py4JJavaError as ep:
                    print(f"[IE][INFO][{now()}] {ep}")
                except Exception as ex:
                    print(f"[IE][ERROR][{now()}] Unexpected Error: {ex}")

        # Delete not needed column _corrupted_data_
        df = df.drop('_corrupted_data_')

        # Add new column if we have  add_surrogate_id:TRUE
        if val["config"].get('add_surrogate_id'):
            # Add  unique id
            df = df.withColumn("surrogate_id", F.monotonically_increasing_id())

        # Show Ingestion statistics
        print(f"[IE][INFO][{now()}] Ingestion statistics:")
        meta_data.show()

        # Get number of all rows from all files
        total_rows_loaded = df.count()

        # Order the DF
        print(f"\n[IE][INFO][{now()}] Order: {val['outputOrder']}")
        print(f"[IE][INFO][{now()}] All ingested rows number: {total_rows_loaded}")

        # Sort dataframe
        if not val["config"].get('add_surrogate_id'):
            df = df.select(['sys_datasource'] + ['sys_load_id'] + ['sys_created_on'] + val["outputOrder"])
        else:
            df = df.select(
                ['sys_datasource'] + ['sys_load_id'] + ['sys_created_on'] + ['surrogate_id'] + val["outputOrder"])

        # Show final df
        print(f"[IE][INFO][{now()}] First 20 lines of the df:")
        df.show()

        # Load to hive(ingestion_metadata) meta-data
        try:
            spark_session.sql(f"DROP TABLE {conf['table']}_ingestion_metadata_staging")
            print(f"[IE][INFO][{now()}] Table {conf['table']}_ingestion_metadata_staging dropped before recreation")
        except Exception as e:
            print(f"[IE][INFO][{now()}] There is no staging table to drop")
            # print(f"[IE][INFO][{now()}] {e}")
        finally:
            load_to_hive(meta_data, 'ingestion_metadata', conf["partitionedBy"], today, mode='append',
                         preffix=conf["table"] + '_', database=database)
            try:
                spark_session.sql(f"DROP TABLE {conf['table']}_ingestion_metadata_staging")
                print(f"[IE][INFO][{now()}] Table {conf['table']}_ingestion_metadata_staging dropped after save")
            except Exception as e:
                print(f"[IE][INFO][{now()}] There is no staging table to drop")
                # print(f"[IE][INFO][{now()}] {e}")

        # Load to hive ingested data
        try:
            spark_session.sql("DROP TABLE {}_staging".format(conf["table"]))
            print(f"[IE][INFO][{now()}] Table {conf['table']}_staging dropped before recreate")
        except Exception as e:
            print(f"[IE][INFO][{now()}] There is no staging table to drop")
            # print(f"[IE][INFO][{now()}] {e}")

        finally:
            load_to_hive(df, conf["table"], conf["partitionedBy"], today, mode='overwrite', database=database)
            try:
                spark_session.sql(f"DROP TABLE {conf['table']}_staging")
                print(f"[IE][INFO][{now()}] Table {conf['table']}_staging dropped after save")
            except Exception as e:
                print(f"[IE][INFO][{now()}] There is no staging table to drop")
                # print(f"[IE][INFO][{now()}] {e}")

    else:
        print(f"[IE][INFO][{now()}] No Files matching the pattern. Moving to next task_Id")


# Templated variables
if __name__ == "__main__":
    # TODO: Validation on the argument

    # Get path to folder with file
    sys.path.append(os.path.dirname(__file__))

    # Reanme input arguments
    STORAGENAME = argv[1]
    SOURCEDIR = argv[2]
    ENVIRONMENT = argv[3]
    TASK_ID = argv[4]
    conf = json.loads(argv[5])
    val = json.loads(argv[6])
    today = argv[7]
    rejected_files_dir = argv[8]
    database = 'default'

    try:
        print(f"[IE][INFO][{now()}] Starting ingestion script for {TASK_ID}")
        main(STORAGENAME, SOURCEDIR, ENVIRONMENT, TASK_ID, conf, val, today, rejected_files_dir, database)
    except Exception as e:
        print(f"[IE][ERROR][{now()}] {e}")
        raise e
    print(f"[IE][INFO][{now()}] Ingestion script for {TASK_ID} ended")

# EOF
