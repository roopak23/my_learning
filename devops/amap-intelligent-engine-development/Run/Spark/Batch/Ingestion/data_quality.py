from pyspark.sql.functions import col, count
from pyspark.sql.functions import monotonically_increasing_id
from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.types import *
import pandas as pd
from ingestion import now
import sys
sys.path.append('/tmp/Libraries')
from ie_hive_connection import IEHiveConnection


def duplicate_clear(df: DataFrame, val: dict, schema: StructType, spark_context):
    """
    Clear df from duplicates. Only first duplicate remains.\n
    input:
        df - dataframe (spark) on which actions are performed;\n
        val - dictionaty with parameters;\n
        schema - schema with data on the column structure.\n
        sc - Main entry point for Spark functionality. Need to crate empty df.\n
    output:
        df - cleaned dataframe without duplicates or unchanged dataframe if 'remove_duplicates = False'\n
        duplicate_df - contain the values that were rejected.\n
    """

    print(f"[IE][INFO][{now()}] Getting SparkSession")
    spark_session = SparkSession.builder.getOrCreate()
    print(f"[IE][INFO][{now()}] SparkSession id: {spark_session}")
    duplicate_df = spark_session.createDataFrame(spark_context.emptyRDD(), schema=schema)

    if val["config"].get('remove_duplicates'):
        unique_cols = []

        # Get unique columns
        for vlue in schema:
            if vlue.metadata['pk']:
                unique_cols.append(vlue.name)

        # collect full duplicate
        duplicate_df = df.groupBy(df.columns).count().filter(
            col("count") > 1).drop("count")
        # drop full duplicate
        df = df.dropDuplicates()

        if len(unique_cols) != 0:
            #  Collect duplicates by column
            tmp = df.join(df.groupBy(unique_cols).agg((count("*") > 1).cast("int").alias("duplicate_indicator")),
                          on=unique_cols, how="inner").filter('duplicate_indicator >= 1').drop('duplicate_indicator')
            duplicate_df = duplicate_df.union(tmp)
            # del duplicate by column
            df = df.dropDuplicates(subset=unique_cols)

    return df, duplicate_df


def mandatory_clear(df: DataFrame, val: dict, schema: StructType, spark_context):
    """
    Clear df from nan values.\n
    input:
        df - dataframe (spark) on which actions are performed;\n
        val - dictionaty with parameters;\n
        schema - schema with data on the column structure.\n
        sc - Main entry point for Spark functionality. Need to crate empty df.\n
    output:
        df - cleaned dataframe without nan(none) or unchanged dataframe if 'check_mandatory = False'\n
        mandatory_df - contain the values that were rejected.\n
    """
    print(f"[IE][INFO][{now()}] Getting SparkSession")
    spark_session = SparkSession.builder.getOrCreate()
    print(f"[IE][INFO][{now()}] SparkSession id: {spark_session}")
    mandatory_df = spark_session.createDataFrame(spark_context.emptyRDD(), schema=schema)
    mandatory_cols = []

    if val["config"].get('check_mandatory'):
        # Get mandatory columns
        for vlue in schema:
            if not vlue.nullable:
                mandatory_cols.append(vlue.name)

        if len(mandatory_cols) == 0:
            return df, mandatory_df

        for c in mandatory_cols:
            mandatory_df = mandatory_df.union(df.filter(col(c).isNull()))
            df = df.na.drop(subset=c)

    return df, mandatory_df


def get_from_hive(table_name: str):
    """
    :param table_name: name of table in HIVE
    :return: DF with data from table
    """

    # Simple query to select all values from table
    select_query = f'SELECT * FROM {table_name}'

    try:
        # Create local connection to HIVE
        conn = IEHiveConnection()

        # Using SQL select data from table & write to pandas df
        df = pd.read_sql_query(select_query, conn)

    finally:
        # Close connection
        conn.close()

    return df


# Input
def total_clear(df: DataFrame, val: dict, schema: StructType, sc):
    """
    :param df: initial dataframe over which all manipulation in this module will be performed \n
    :param val: validator with the parameters needed to clear dataframe \n
    :param schema: structure of df (type of columns, name, ets) \n
    :param sc: Spark Context \n
    :return: Statistics with counters of rejected rows, Clear DF and rejected values
    """

    print(
        f"[IE][INFO][{now()}] Starting DQ clear")

    # Returns a new DataFrame partitioned by the given partitioning expressions. The resulting DataFrame is hash partitioned.
    df = df.repartition(1)

    # Get total values number (non-valid values included)
    total_rows = df.count()

    # needed for the following calculations
    df = df.cache()

    # Collect non-valid rows
    nonvalid_df = df.where(col("_corrupted_data_").isNotNull())
    # Get non-valid rows number
    nonvalid_rejected = nonvalid_df.count()
    # Non-valid clear
    df = df.where(col("_corrupted_data_").isNull())

    # Nan value clear
    df, mandatory_df = mandatory_clear(df, val, schema, sc)
    # Get mandatory rejected rows number
    mandatory_rejected = mandatory_df.count()

    # Duplicate value clear
    df, duplicate_df = duplicate_clear(df, val, schema, sc)
    # Get duplicates rejected rows number
    duplicates_rejected = total_rows - \
        nonvalid_rejected - mandatory_rejected - df.count()

    print(f"[IE][INFO][{now()}] Rejected {nonvalid_rejected} non-valid values")
    print(f"[IE][INFO][{now()}] Rejected {mandatory_rejected} nan(null) values")
    print(f"[IE][INFO][{now()}] Rejected {duplicates_rejected} duplicates values")

    print(
        f"[IE][INFO][{now()}] DQ Clear ending")

    # add statistics to dictionary
    stats = {
        'total_rows': total_rows,
        'non_valid_rejected': nonvalid_rejected,
        'mandatory_rejected': mandatory_rejected,
        'duplicates_rejected': duplicates_rejected
    }

    return [stats, df, nonvalid_df, mandatory_df, duplicate_df]


# Input
def dq_clear(df: DataFrame, table: str, schema: StructType, spark_context, meta_tbl: str = 'dq_metatbl'):
    """
    :param df: initial dataframe over which all manipulation in this module will be performed \n
    :param table: name of the data \n
    :param spark_context: Spark Context \n
    :param schema: structure of df (type of columns, name, ets) \n
    :param meta_tbl: optional parameter, name of table with DQ instructions.
    :return: clear df, df with rejected rows, flag(blocker)
    """
    print(
        f"[IE][INFO][{now()}] Starting DQ script")

    print(f"[IE][INFO][{now()}] Getting SparkSession")
    spark_session = SparkSession.builder.getOrCreate()
    print(f"[IE][INFO][{now()}] SparkSession id: {spark_session}")

    # get all params from meta_tbl
    dq_df = get_from_hive(meta_tbl)

    # check if is necessary case for us
    if table not in dq_df[f'{meta_tbl}.tablename'].unique():
        print(f"[IE][INFO][{now()}] No matches found in DQ table")
        print(
            f"[IE][INFO][{now()}] End of DQ script")
        return [df, spark_session.createDataFrame(spark_context.emptyRDD(), schema=schema), False]

    # get blocker flag
    blocker = dq_df.loc[dq_df[f'{meta_tbl}.tablename']
                        == table][f'{meta_tbl}.blocker'].values[0].lower()

    # Add  unique id
    df = df.withColumn("__unique_id__", monotonically_increasing_id())

    # Select not valid data
    df.createOrReplaceTempView(table)
    query = dq_df.loc[dq_df[f'{meta_tbl}.tablename']
                      == table][f'{meta_tbl}.dq_query'].values[0]
    dq_rejected = spark_session.sql(query)

    if blocker == 'y':
        # Clear df
        dq_rejected.createOrReplaceTempView('dq_rejected_table')
        left_query = f"SELECT A.* FROM {table} A LEFT JOIN dq_rejected_table B ON A.__unique_id__ = B.__unique_id__ WHERE B.__unique_id__ IS NULL"
        df = spark_session.sql(left_query)
    df = df.drop('__unique_id__')

    # delete not needed columns
    dq_rejected = dq_rejected.drop('__unique_id__')

    print(
        f"[IE][INFO][{now()}] End of DQ script")
    return [df, dq_rejected, blocker]
