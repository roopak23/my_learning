# -*- coding: utf-8 -*-
"""
Created on Wed Mar 20 18:14:46 2024

@author: dipan.arya
"""




# import logging

# logging.basicConfig(filename='/tmp/forecasting.log', level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

import pandas as pd
import numpy as np
import datetime
import time
import signal
from sys import argv
from scipy import stats
from pmdarima import metrics
from pmdarima import auto_arima
from math import isnan
import datetime
# Spark Imports
import pymysql
from pyspark.sql import  SparkSession
from pyspark.context import SparkContext
import traceback
from pyspark.sql.functions import when
import pyspark.sql.functions as F
from pyspark.sql.types import FloatType
from pyspark.sql.types import *
import pyspark.sql.functions as sf
from statsmodels.tsa.stattools import adfuller
from statsmodels.tsa.seasonal import STL
from ast import literal_eval
from sklearn.metrics import mean_absolute_error
import sys
sys.path.append('/tmp/Libraries')
from ie_hive_connection import IEHiveConnection

pd.set_option('max_columns', None)

class mysql_db:
    host = ""
    database = ""
    port = 1
    user = ""
    password = ""
    @classmethod
    def set(cls, host, database, port, user, password):
        cls.host = host
        cls.database = database
        cls.port = port
        cls.user = user
        cls.password = password

class dateset():
    yesterday = (datetime.date.today() -
                 datetime.timedelta(days=1)).strftime('%Y%m%d')
    def __init__(self, value_for_model, partition_date):
        self.start = dateset.generate_start_day(
            value_for_model["days"], value_for_model["historical_ratio"], partition_date)
        self.end = partition_date
    @staticmethod
    def generate_start_day(days, ratio, partition_date):
        # TODO: Need to tune default_ratio for client data
        default_ratio = 2
        if ratio is None:
            days = default_ratio
            print("No input was detected. Using default ratio of 2.")
        elif ratio < 1:
            days = default_ratio
            print("Ratio was out of range. Using default ratio of 2.")
        try:
            date = datetime.datetime.strptime(str(partition_date), '%Y%m%d')
            return (date - datetime.timedelta(days=(days * ratio))).strftime('%Y%m%d')
        except:
            raise TypeError(
                "Partition_date is out of range or incorrect format. YYYYMMDD")


class ModelResults():
    def __init__(self, table, sku, smape, value_for_model, model, error, iter_metrics):
        self.date = datetime.date.today().strftime("%Y-%m-%d")
        self.sku = sku + "|" + dateset.yesterday
        self.model_name = 'ARIMA'
        self.error_message = ModelResults.generate_error_message(error)
        self.hyperparameters = ModelResults.generate_hyperparameters(
            value_for_model, model, iter_metrics)
        self.kpi = 'SMAPE'
        self.kpi_value = float("{:.2f}".format(smape))
        self.partition_date = dateset.yesterday
        self.table = table  # Datatable to output
    def generate_hyperparameters(value_for_model, model, iter_metrics):
        if type(model) is str:
            hyperparameters = model
        else:
            hyperparameters = {}
            hyperparameters['runtime'] = float("{:.2f}".format(value_for_model['runtime']))
            hyperparameters['days'] = value_for_model['days']
            hyperparameters['metrics'] = iter_metrics
            hyperparameters['historical_ratio'] = value_for_model['historical_ratio']
            hyperparameters['information_criterion'] = value_for_model['information_criterion']
            order = model.get_params().get("order")
            hyperparameters['p'] = order[0]
            hyperparameters['d'] = order[1]
            hyperparameters['q'] = order[2]
        return hyperparameters
    def generate_error_message(error):
        message = ''
        if error:
            message = error
        else:
            message = 'All clear'
        return message
    def generate_query(self):
        hyperparameters = f"{self.hyperparameters}"
        hyperparameters = hyperparameters.replace("'", "''")
        if isnan(self.kpi_value):
            self.kpi_value = 0
        query = f"""INSERT INTO {self.table}(
                        `date`,
                        sku,
                        model_name,
                        error_message,
                        hyperparameters,
                        kpi,
                        kpi_value)
                    VALUES (
                        '{self.date}',
                        '{self.sku}',
                        '{self.model_name}',
                        '{self.error_message}',
                        '{hyperparameters}',
                        '{self.kpi}',
                        {self.kpi_value})"""
        return query

# Create mysql connection
def create_mysql_connection():
    try:
        connection = pymysql.connect(
            host=mysql_db.host,
            database=mysql_db.database,
            port=mysql_db.port,
            user=mysql_db.user,
            password=mysql_db.password)
    except Error as e:
        print(f"The error '{e}' occurred")
        raise ConnectionError("mySQL Connection Failed.")
    return connection


# Create Hive connection


def create_hive_connection():
    try:
        connection = IEHiveConnection()
    except Exception as e:
        print(f"The error '{e}' occurred")
        raise ConnectionError("Hive Connection Failed.")
    return connection


def execute_write_query(connection, query):
    try:
        cur = connection.cursor()
        cur.execute(query)
        connection.commit()
        # connection.close()
    except Exception as e:
        print("Query failed", query, e)
        traceback.print_tb(e.__traceback__)
        raise Exception(e)
    finally:
        connection.close()


def intergration_check(data_table):
    conn = create_hive_connection()
    cur = conn.cursor()
    query = f'SELECT * from {data_table["inv_input_table"]} LIMIT 1'
    cur.execute(query)
    data = cur.fetchone()
    cur.close()
    if data is None:
        return False
        # raise ConnectionError("Database connection not established.")
    return True


def clear_table(table):
    query = f"DELETE FROM {table}"
    mysql_connection = create_mysql_connection()
    execute_write_query(mysql_connection, query)
    print(f'Table {table} cleared')


# Fetch data from Hive
# Arguments:
# spark_session: Spark Context
# query: SQL query


def fetch_from_hive(spark_session, query):
    # Create connection
    conn = create_hive_connection()
    # read in pandas and conver to hive
    result = pd.read_sql(query, conn)
    print("query done")
    print(result.columns)
    try:
        cols_remap = {key: key.split(".")[1] for key in result.columns}
        print("columns renamed")
        result.rename(columns=cols_remap, inplace=True)
        print("apply column name")
    except:
        print("No column to remap")
    finally:
        df = result
        conn.close()
    return df

# Load data to Hive
# Arguments:
# df: Python DataFrame to load
# query: Schema of the df dataframe

def load_to_hive(df, table_name, schema=False, database='default') -> None:
    print('check if data is present')
    print(df.head(1))
    if len(df) > 1:
        print("[DM3][INFO] DF is populated: Writing to data to Hive")
        print("Save temp table")
        spark_session = SparkSession.builder \
            .config("hive.exec.dynamic.partition.mode", "nonstrict") \
            .enableHiveSupport() \
            .getOrCreate()
        spark_session.sql(f"USE {database}")
        spark_context = SparkContext.getOrCreate()
        spark_context.setLogLevel("WARN")
        if schema:
            df = spark_session.createDataFrame(df, schema)
        else:
            df = spark_session.createDataFrame(df)
        try:
            spark_session.sql("drop table {table_name}_staging".format(
                table_name=table_name))
        except:
            pass
        df = df.withColumn('adserver_target_type', sf.lit('NULL'))
        df = df.withColumn('adserver_target_category', sf.lit('NULL'))
        df = df.withColumn('adserver_target_code', sf.lit('NULL'))
        df = df.withColumn('adserver_target_remote_id', sf.lit('NULL'))
        df = df.withColumn('adserver_target_name', sf.lit('NULL'))
        df = df.select("date", "adserver_adslot_id", "adserver_id", "adserver_target_remote_id", "adserver_target_name",
                       "adserver_target_type", "adserver_target_category", "adserver_target_code",	"metric", "future_capacity", "partition_date")
        df.write.saveAsTable(
            "{table_name}_staging".format(table_name=table_name))
        conn = create_hive_connection()
        query = "INSERT OVERWRITE TABLE {table_name} SELECT * FROM {table_name}_staging".format(
            table_name=table_name)
        execute_write_query(conn, query)
        print("Data written into table: {}".format(table_name))
    else:
        print("[DM3][ERROR] The DF has not elements, please check the validation rules")


def load_data_from_hive(data_table: dict, partition_date: int, value_for_model: dict, database: str = 'default'):
    spark_session = SparkSession.builder \
        .config("hive.exec.dynamic.partition.mode", "nonstrict") \
        .enableHiveSupport() \
        .getOrCreate()
    spark_session.sql(f"USE {database}")
    # Get Context
    spark_context = SparkContext.getOrCreate()
    spark_context.setLogLevel("WARN")
    # Fetch data from Hive
    search_date = dateset(value_for_model, partition_date)
    df_input = fetch_from_hive(spark_session, "SELECT * FROM {} where metric = 'IMPRESSION' and partition_date  BETWEEN {} AND {} ".format(data_table["inv_input_table"], search_date.start, search_date.end))
    #df_input = fetch_from_hive(spark_session, "SELECT * FROM {} where metric = 'IMPRESSION' and partition_date  BETWEEN {} AND {} AND adserver_adslot_id in (select distinct adserver_adslot_id from {} where partition_date = {})".format(data_table["inv_input_table"], search_date.start, search_date.end,data_table["inv_input_table"],partition_date))
    return df_input

def load_booked_data_from_hive():
    spark_session = SparkSession.builder \
        .config("hive.exec.dynamic.partition.mode", "nonstrict") \
        .enableHiveSupport() \
        .getOrCreate()
    spark_session.sql(f"USE {database}")
    # Get Context
    spark_context = SparkContext.getOrCreate()
    spark_context.setLogLevel("WARN")
    # Fetch data from Hive
    booked = fetch_from_hive(spark_session, "SELECT `date`, booked, adserver_adslot_id, adserver_id FROM ( SELECT `date`, booked, adserver_adslot_id, adserver_id, partition_date, ROW_NUMBER() OVER ( PARTITION BY adserver_adslot_id, `date` ORDER BY partition_date DESC ) AS row_num FROM {} where `date` >= DATE_FORMAT(CURRENT_DATE, 'yyyy-MM-dd') ) as Ranked WHERE row_num = 1 ".format('TRF_AdServer_InvFuture'))
    return booked

def ReadTable(rds_sql_user, rds_sql_pass, aws_rds_connection, rdssql_schema,rdssql_port, select_statement, partition_column, lower_bound, upper_bound, num_partitions, fetch_size):
    # Use the passed `select_statement` to dynamically define the query
    dbtable = f"({select_statement}) AS subq"
    spark_session = SparkSession.builder \
        .config("hive.exec.dynamic.partition.mode", "nonstrict") \
        .enableHiveSupport() \
        .getOrCreate()
    df = spark_session.read.format("jdbc") \
        .option('url', f'jdbc:mysql://{aws_rds_connection}:{rdssql_port}/{rdssql_schema}?&useSSL=true&trustServerCertificate=true') \
        .option("driver", "org.mariadb.jdbc.Driver") \
        .option("dbtable", dbtable) \
        .option("user", rds_sql_user) \
        .option("password", rds_sql_pass) \
        .option("partitionColumn", partition_column) \
        .option("lowerBound", int(lower_bound)) \
        .option("upperBound", int(upper_bound)) \
        .option("numPartitions", int(num_partitions)) \
        .option("batchsize", fetch_size) \
        .load()
    return df

def TruncateRDS_table(rds_sql_user, rds_sql_pass, aws_rds_connection, rdssql_schema, rdssql_port, table_name):
    conn = create_mysql_connection()
    cursor = conn.cursor()
    truncate_table_query = f"truncate table {table_name} ;"
    cursor.execute(truncate_table_query)
    print(f"Table '{table_name}' truncated.")
    cursor.close()
    conn.close()

def Insert_Data_RDS(df, table_name,count_of_partitions,rows_per_partition):
    df.write.format("jdbc")\
        .option("url", f'jdbc:mysql://{aws_rds_connection}:{rdssql_port}/{rdssql_schema}?&useSSL=true&trustServerCertificate=true')\
        .option("driver", "org.mariadb.jdbc.Driver")\
        .option("dbtable", table_name)\
        .option("user", rds_sql_user)\
        .option("password", rds_sql_pass)\
        .option("numPartitions", count_of_partitions)\
        .option("batchsize", rows_per_partition)\
        .mode('append')\
        .save()

def filter_combinations(df, metric, max_date):
    # Filter out the combinations without enough historical_capacity or without activity in the last 2 days
    min_capacity = 0
    if metric == 'IMPRESSION':
        min_capacity = 1
    elif metric == 'CLICK':
        min_capacity = 100
    # df = df.groupby(['adserver_id','adserver_adslot_id' ,'adserver_target_remote_id' ]
    df = df.groupby(['adserver_id','adserver_adslot_id']
    ).filter(lambda x: 
        x['historical_capacity'].mean() >= min_capacity 
        and (max_date - x['date'].max()).days <= 2
        ).reset_index(drop=True)
    return df

# Funtion to impute outliers, it removes negative values and values with Z-SCORE >= 3
# Arguments:
# ts: Timeseries DataFrame
# field: name of the timeseries column


def OutLiersImputation(ts: pd.DataFrame, field: str) -> pd.DataFrame:
    # Compute Z score
    # Remove negative values, if any
    ts = ts[ts[field] >= 0]
    z_scores = stats.zscore(ts[field], nan_policy='omit')
    abs_z_scores = np.abs(z_scores)
    # Filter Outliers
    filtered_entries = abs_z_scores >= 3
    # Apply filter to TS
    ts.loc[filtered_entries,field] = ts[field].median()
    return ts


def printDF(df: pd.DataFrame, step: str) -> None:
    print("---- In Step: {} ----".format(step))
    # DF imputation print
    with pd.option_context(
        "display.max_rows", None, "display.max_columns", None, "display.width", 1000
    ):
        print(df)


# Impute the missing values, fill the missing values by backfill and reindex by forward fill
# Arguments:
# ts: timeseris dataframe
# Index: index of the time seriesdata - date column
# idx: index of the timeseries data from minimum to maximum date

def evaluate_imputation(ts: pd.DataFrame, Index: str, idx: pd.DatetimeIndex, method: str, order: int = None) -> float:
    # Impute missing values using the specified method
    ts_imputed, _ = MissingImputationWithMethod(ts, Index, idx, method, order)
    # Dummy evaluation - this should be replaced with actual model evaluation
    # Here we use mean absolute error (MAE) as an example metric
    # For real use, you need a reference for comparison
    reference = ts.copy()  # Replace with actual reference data if available
    imputed_values = ts_imputed[Index].values
    reference_values = reference[Index].values
    # Calculate mean absolute error (MAE)
    mae = mean_absolute_error(reference_values, imputed_values)
    return mae

def choose_imputation_method(ts: pd.DataFrame, Index: str, idx: pd.DatetimeIndex) -> str:
    methods = ['linear', 'polynomial', 'nearest', 'spline', 'mean', 'median', 'ffill', 'bfill']
    best_method = None
    best_score = float('inf')
    best_order = None
    for method in methods:
        try:
            # For polynomial and spline, you may need to test different orders
            orders = [1, 2, 3] if method in ['polynomial', 'spline'] else [None]
            for order in orders:
                score = evaluate_imputation(ts, Index, idx, method, order)
                if score < best_score:
                    best_score = score
                    best_method = method
                    best_order = order
        except Exception as e:
            print(f"Failed for method {method} with exception {e}")
    return best_method, best_order

def MissingImputationWithMethod(ts: pd.DataFrame, Index: str, idx: pd.DatetimeIndex, method: str, order: int = None) -> pd.DataFrame:
    # Set Index and add missing dates
    ts.set_index(ts[Index], inplace=True)
    ts = ts.sort_index()
    ts = ts.reindex(idx)
    # Fill missing values with the specified method
    if method == 'linear':
        ts = ts.interpolate(method='linear')
    elif method == 'polynomial':
        ts = ts.interpolate(method='polynomial', order=order)
    elif method == 'nearest':
        ts = ts.interpolate(method='nearest')
    elif method == 'spline':
        ts = ts.interpolate(method='spline', order=order)
    elif method == 'mean':
        ts.fillna(ts.mean(), inplace=True)
    elif method == 'median':
        ts.fillna(ts.median(), inplace=True)
    elif method == 'ffill':
        ts.fillna(method='ffill', inplace=True)
    elif method == 'bfill':
        ts.fillna(method='bfill', inplace=True)
    else:
        ts.fillna(ts.mean(), inplace=True)
    ts[Index] = ts.index
    return ts


def MissingImputation(ts: pd.DataFrame, Index: str, idx: pd.DatetimeIndex) -> pd.DataFrame:
    # Set Index and add missing dates
    best_method, best_order = choose_imputation_method(ts, Index, idx)
    ts_imputed = MissingImputationWithMethod(ts, Index, idx, best_method, best_order)
    missing = len(ts)
    ts_imputed[Index] = ts_imputed.index
    #ts.set_index(ts[Index], inplace=True)
    #ts = ts.sort_index()
    #ts = ts.reindex(idx, method="ffill")
    # Fill NaN values
    # ts.fillna(method="bfill", limit=30, inplace=True)
    #ts.fillna(method="bfill", inplace=True)
    #ts[Index] = ts.index
    return ts_imputed, len(ts_imputed) - missing

# Print the mean absolute percentage error_action
# Arguments:
# forecast: forecast series data
# valid: actual series data


def CheckMapeScore(forecast: np.ndarray, valid: pd.DataFrame) -> float:
    # Check MAPE Score
    mape = metrics.smape(valid, forecast)
    print("SMAPE value: {}".format(mape))
    return mape


# Function for the time series with too many missing values
# Arguments:
# data: timeseries data
# args of the time serie

def create_mean_forecast_output(ts: pd.DataFrame, idx: pd.DatetimeIndex):
    # use the mean historical capacity of the weekday for the forecast
    forecast = pd.DataFrame(index = idx)
    values = []
    for dates in forecast.index:
        if str(ts[ts['date'].dt.weekday == dates.weekday()].historical_capacity.mean()) == 'nan':
            values.append(0)
        else:
            values.append(ts[ts['date'].dt.weekday == dates.weekday()].historical_capacity.mean())
    forecast['Prediction'] = values
    return forecast


def mean_as_forecast(ts: pd.DataFrame, Index: str, idx: pd.DatetimeIndex, adslot_id: str, adserver_id: str, metrics: str, partition_date: int,value_for_model):
    ts.set_index(ts[Index], inplace=True)
    ts = ts.sort_index()
    median_value = ts['historical_capacity'].median()
    # Reindex the time series with 'idx' and replace the fill_value of 0 with the median value
    ts = ts.reindex(idx, fill_value=0)
    # Check if the column has below 10 null values than replace it with median else take 0 and calculate
    # if (ts['historical_capacity'] == 0).sum() < 10:
    #     print("less than 10")
    #     ts['historical_capacity']=ts['historical_capacity'].replace(0,median_value)
    # else:
    #     print("more than 10 zero values in the column")
    ts['historical_capacity']=ts['historical_capacity'].replace(0,median_value)
    ts[Index] = ts.index
    Max_Date = datetime.date.today() - datetime.timedelta(days=1)
    idx1 = pd.date_range(Max_Date + pd.DateOffset(days=1),Max_Date + pd.DateOffset(days=value_for_model["days"]))
    print("printing idx1 details ::: ",idx1)
    forecast = create_mean_forecast_output(ts, idx1)
    forecast_step = CreateForecastOutputDF(forecast, idx1, adslot_id, adserver_id, metrics, partition_date)
    return forecast_step

# Function to run the model
# Arguments:
# data: timeseries data
# days: number of days for forecast to be done
# Returns:
# forecast: forecast array
# smape: KPI SMAPE value

def handler(signum, frame):
    print('Training took too much time')
    raise Exception("End of time")

from statsmodels.tsa.seasonal import seasonal_decompose
from statsmodels.tsa.stattools import acf
from scipy.signal import find_peaks

def determine_dynamic_seasonal_period(time_series: pd.Series, max_lag: int = 365) -> int:
    """
    Dynamically determines the seasonal period (m) based on autocorrelation analysis.
    
    :param time_series: The input time series data.
    :param max_lag: The maximum lag to consider for seasonality detection (default: 365 days for daily data).
    :return: The identified seasonal period (m).
    """
    # Calculate autocorrelation for the time series up to the max_lag
    autocorr_values = acf(time_series, nlags=max_lag)
    # Find peaks in the autocorrelation function
    peaks, _ = find_peaks(autocorr_values, height=0.1)  # Detect peaks with height > 0.1
    # Filter out peaks that are too small (less significant)
    significant_peaks = peaks[autocorr_values[peaks] > 0.3]  # Adjust the threshold as needed
    # Define possible seasonal periods to check: weekly (7), monthly (30), quarterly (90), etc.
    common_seasonal_periods = [7, 14, 18, 20, 22, 25, 28, 30, 32, 35, 38, 40, 42, 45,58, 50, 52, 55, 58, 60, 90, 365]
    # Check if any significant peak matches the common seasonal periods
    seasonal_period = 1  # Default value (no seasonality)
    for period in common_seasonal_periods:
        if period in significant_peaks:
            seasonal_period = period
            break
    if seasonal_period == 1 and len(significant_peaks) > 0:
        # If none of the common periods match, select the most significant peak
        seasonal_period = significant_peaks[0]
    if seasonal_period == 1:
        print("No significant seasonal pattern detected.")
    else:
        print(f"Seasonal pattern detected with period: {seasonal_period}")
    return seasonal_period

def RunModel(data: pd.DataFrame, days: int, input: list) -> pd.DataFrame:
    print("-------------Training---------------")
    # Divide into train and validation set
    # signal.signal(signal.SIGALRM, handler)
    # signal.alarm(15)
    try:
        train = data[: int(input["train"] * (len(data)))]
        valid = data[int(input["train"] * (len(data))):]
        # Size of the dataframes
        print("training columns ::: ",train.columns) 
        print("training index ::: ",train.index) 
        # Size of the dataframes
        print("Training set: {}".format(len(train)))
        print("Validation set: {}".format(len(valid)))
        # Fit ARIMA
        seasonal_period = determine_dynamic_seasonal_period(train)
        train['weekday'] = train.index.weekday 
        valid['weekday'] = valid.index.weekday
        print(f"Seasonal Period Determined: {seasonal_period}")        
        model = auto_arima(
            train['historical_capacity'],
            exogenous=train[['weekday']],
            information_criterion=input["information_criterion"],
            max_p=input["max_p"],
            max_q=input["max_q"],
            max_d=input["max_d"],
            max_P=input["max_P"],
            max_Q=input["max_Q"],
            max_D=input["max_D"],
            start_p=input["start_p"],
            start_q=input["start_q"],
            start_d = input["start_d"],
            start_P=input["start_P"], 
            start_Q=input["start_Q"],
            start_D=input["start_D"],
            stationary=input["stationary"],
            seasonal=True,
            m= seasonal_period, 
            error_action=input["error_action"],
            suppress_warnings=input["suppress_warnings"],
            random_state=42,
            stepwise=True,
            n_jobs=-1,
            n_fits=500,
            random=True,
            trace=True
        )
        model.fit(train['historical_capacity'], exogenous=train[['weekday']])
        # signal.alarm(0)
        print("-------------Verification---------------")
        # Check Mape score
        forecast = model.predict(n_periods=len(valid), exogenous=valid[['weekday']])
        print("Model check", valid, forecast)
        mape = CheckMapeScore(valid['historical_capacity'], forecast)
        print("SMAPE: {}".format(mape))
        # model.fit(data)
        print("-------------Forecasting---------------")
        # Build actual forecast
        future_weekdays = [(train.index[-1].weekday() + i + 1) % 7 for i in range(days)] 
        future_dates = pd.date_range(start=train.index[-1] + pd.Timedelta(days=1), periods=days, freq='D')
        future_exog = pd.DataFrame({'weekday': future_weekdays}, index=future_dates)
        forecast = model.predict(n_periods=days,exogenous=future_exog)
        forecast = pd.DataFrame(forecast, columns=["Prediction"]).round(decimals=0)
        return forecast, mape, model
    except Exception as e:
        # signal.alarm(0)
        print(e)
        return 0,0,0

# Function to create forecast output with all the supporting features
# Arguments:
# sku: adserver_adslot_id
# segment_id: adserver_target_id
# segment_name: adserver_target_name


# def CreateForecastOutputDF(df: pd.DataFrame, dates: pd.DatetimeIndex, sku: str, adserver_id: str , segment_id: str, segment_name: str , metrics: str, partition_date: int) -> pd.DataFrame:
def CreateForecastOutputDF(df: pd.DataFrame, dates: pd.DatetimeIndex, sku: str, adserver_id: str , metrics: str, partition_date: int) -> pd.DataFrame:
    print("Final Columns")
    #  cols = ["date", "gam_adunitid", "device_name", "future_capacity"]
    # cols = ["date", "adserver_adslot_id", "adserver_id", "adserver_target_remote_id",
    #         "adserver_target_name", "metric", "future_capacity",  "partition_date"]
    cols = ["date", "adserver_adslot_id", "adserver_id", "metric", "future_capacity",  "partition_date"]
    # Populate missing columns
    for i in cols:
        if i == "adserver_adslot_id":
            df[i] = sku
        elif i == "date":
            df[i] = dates
        elif i == "future_capacity":
            df[i] = df["Prediction"]
        elif i == "adserver_id":
            df[i] = adserver_id
        elif i == "metric":
            df[i] = metrics
        elif i == "partition_date":
            df[i] = partition_date
    # Just re aligning the columns order
    df_reconstruct = df[cols]
    # Return DF with columns in the right order
    print(
        "Reconstructing done: output has {} row and {} cols.".format(
            len(df_reconstruct), len(df_reconstruct.columns)
        )
    )
    return df_reconstruct


def export_model_results(sku, data_table, smape, value_for_model, model, error, iter_metrics):
    output = ModelResults(data_table, sku, smape,value_for_model, model, error, iter_metrics)
    query = output.generate_query()
    conn = create_mysql_connection()
    execute_write_query(conn, query)
    print(f"Data written into table: {data_table} ")


# Function "main" to call all the functions and set the pipeline
# Arguments:
# matrix: metric to forecast

def write_forecast_to_mysql(forecast_step, tableoutput):
    for i,row in forecast_step.iterrows():
        mysql_connection = create_mysql_connection()
        ''' query = f"""INSERT INTO {tableoutput}(
                            date,
                            adserver_adslot_id,
                            adserver_id,
                            adserver_target_remote_id,
                            adserver_target_name,
                            adserver_target_type,
                            adserver_target_category,
                            adserver_target_code,
                            metric,
                            future_capacity)
                            VALUES (
                                '{row.date}',
                                '{row.adserver_adslot_id}',
                                '{row.adserver_id}',
                                '{row.adserver_target_remote_id}',
                                '{row.adserver_target_name}',
                                'NULL',
                                'NULL',
                                'NULL',
                                '{row.metric}',
                                {int(row.future_capacity)})""" '''
        query = f"""INSERT INTO {tableoutput}(
                            date,
                            adserver_adslot_id,
                            adserver_id,
                            adserver_target_remote_id,
                            adserver_target_name,
                            adserver_target_type,
                            adserver_target_category,
                            adserver_target_code,
                            metric,
                            future_capacity)
                            VALUES (
                                '{row.date}',
                                '{row.adserver_adslot_id}',
                                '{row.adserver_id}',
                                'NULL',
                                'NULL',
                                'NULL',
                                'NULL',
                                'NULL',
                                '{row.metric}',
                                {int(row.future_capacity)})"""
        execute_write_query(mysql_connection, query)

#stationarity checking, if data is non-stationary then make it to stationary by ADF test


def stationarity(df_temp):
    # Apply ADF test 
    result = adfuller(df_temp['historical_capacity'])
    # Extract ADF statistic and p-value
    adf_statistic = result[0]
    p_value = result[1]
    # Apply differencing until the data becomes stationary
    is_stationary = False
    differenced_data =df_temp['historical_capacity']
    num_diffs = 0
    while not is_stationary:
        # Perform the Dickey-Fuller test for stationarity
        result = adfuller(differenced_data)
        p_value = result[1]
        # Check if the data is stationary (p-value <= 0.05)
        if not p_value or isnan(p_value) :
            is_stationary = True
            print("Failed to run adfuller test")
        elif p_value <= 0.05:
            is_stationary = True
            print("Data stationary")
        else:
            print("Data is Non-stationary")
            # Apply differencing
            differenced_data = differenced_data.diff().fillna(0)
            num_diffs += 1
    # Print the number of differencing operations performed
    print("Number of differencing operations:", num_diffs)
    df_temp['historical_capacity'] = differenced_data
    return df_temp

def create_table_from_df(df, table_name):
    conn = create_mysql_connection()
    cursor = conn.cursor()
    columns = ", ".join([f"{col} VARCHAR(255)" for col in df.columns])
    create_table_query = f"CREATE TABLE IF NOT EXISTS {table_name} ({columns});"
    cursor.execute(create_table_query)
    cursor.close()
    conn.close()

def insert_data(df, table_name,partition_date):
    conn = create_mysql_connection()
    cursor = conn.cursor()
    # Truncate the table to remove all existing rows
    truncate_query = f"delete from {table_name} where partition_date = {partition_date};"
    cursor.execute(truncate_query)
    print(f"Table '{table_name}' truncated.")
    # Generate SQL query for data insertion
    columns = ", ".join(df.columns)
    values = ", ".join(["%s"] * len(df.columns))
    insert_query = f"INSERT INTO {table_name} ({columns}) VALUES ({values})"
    # Convert DataFrame to list of tuples
    data = df.values.tolist()
    # Execute the query
    cursor.executemany(insert_query, data)
    conn.commit()
    print(f"{len(data)} rows inserted into '{table_name}'.")
    cursor.close()
    conn.close()

def main(data_table: dict, partition_date: int, value_for_model: dict):
    final_data_df = []
    df_hive = load_data_from_hive(data_table, partition_date, value_for_model)
    # Check for duplicate rows
    if df_hive.duplicated().any():
        print("Duplicate rows found. Program will exit.")
        sys.exit("Logical error: Duplicate rows present in the DataFrame.")
    # Continue with further processing if no duplicates found
    print("No duplicate rows found. Proceeding with further processing.")
    for iter_metrics in df_hive.metric.unique():
        # Subset data for the metric chosen
        df_input = df_hive[df_hive['metric'] == iter_metrics].copy()
        df_input["adserver_adslot_id"] = df_input['adserver_adslot_id'].astype(str)
        df_input['date'] = pd.to_datetime(df_input['date'])
        df_input['historical_capacity'] = df_input['historical_capacity'].astype(
            float)
        # Filter combinations
        max_date = df_input.date.max()
        df_input = filter_combinations(df_input, iter_metrics, max_date)
        # Distinct adslots, adserver_ids, segment_ids
        adserver_ids = df_input["adserver_id"].unique().tolist()
        adslot_ids = df_input["adserver_adslot_id"].unique().tolist()
        segment_id_name = df_input.groupby('adserver_target_remote_id')[
        'adserver_target_name'].agg(lambda x: x.unique())
        # For each adslot_id reindex on data_range and missing imputation
        forecast_output = pd.DataFrame()
        # For each  adslot_id
        results_list = []
        for adserver_id in adserver_ids:
            for adslot_id in adslot_ids:
                # for segment_id, segment_name in zip(segment_id_name.index, segment_id_name.values):
                # Initialise dataset info
                error = ''
                # sku = adserver_id + "|" + adslot_id '''+ "|" + segment_id '''+ "|" + iter_metrics
                sku = adserver_id + "|" + adslot_id + "|" + iter_metrics
                model = ''
                smape = 0
                # Get Single adslot_id
                # df_temp = df_input.loc[(df_input["adserver_adslot_id"] == adslot_id) & (
                #     df_input["adserver_id"] == adserver_id) & (
                #     df_input["adserver_target_remote_id"] == segment_id)].reset_index(drop=True)
                df_temp = df_input.loc[(df_input["adserver_adslot_id"] == adslot_id) & (
                    df_input["adserver_id"] == adserver_id)].reset_index(drop=True)                
                if df_temp.shape[0] == 0:
                    continue
                # checking stationarity    
                if value_for_model["test_stationarity"]:
                    df_temp=stationarity(df_temp)
                # print("RUNNING adslot {} and segment {} for metric {} ...".format(adslot_id,segment_id, iter_metrics))
                print("RUNNING adslot {} and adserver_id {} for metric {} ...".format(adslot_id,adserver_id, iter_metrics))
                Max_Date = datetime.date.today() - datetime.timedelta(days=1)
                Min_Date = df_temp["date"].min()
                print(f"datetime Max {Max_Date} and Min {Min_Date}")
                idx = pd.date_range(Min_Date, Max_Date)
                # Compute original Size
                original_size = len(df_temp.index)
                # Calculate % of missing values
                perc_missing_values = (len(idx) - original_size)/len(idx)
                historical_capacity_unique = df_temp['historical_capacity'].is_unique
                final_data_df.append({
                    'adserver_adslot_id': adslot_id,
                    'perc_missing_values': perc_missing_values,
                    'historical_capacity_unique': historical_capacity_unique,
                    'original_size': original_size,
                    'len_idx': len(idx),
                    'partition_date': partition_date
                    })
                print("Data apend sucessfully for - {}" .format(adslot_id))
                # print("printing dataframe ::: ",df_temp)
                print("partition date ::: ",partition_date)
                print("value_for_model ::: ",value_for_model)
                print(f"perc_missing_values {perc_missing_values} and length condition {len(df_temp.historical_capacity.unique())} and original size is {original_size}")
                if perc_missing_values > 0.5 or len(df_temp.historical_capacity.unique()) == 1 or original_size < 21:
                    print('Use average for Forecast')
                    # forecast_step = mean_as_forecast(df_temp, 'date', idx, adslot_id, adserver_id, segment_id, segment_name, iter_metrics, partition_date,value_for_model)
                    print("adslot_id ::: ", adslot_id)
                    print("adslot_id ::: ", adslot_id)
                    forecast_step = mean_as_forecast(df_temp, 'date', idx, adslot_id, adserver_id, iter_metrics, partition_date,value_for_model)
                    print("Save data to mysql")
                    write_forecast_to_mysql(forecast_step, data_table["output_table"])
                    print("Append adslot_id to output df")
                    forecast_output = forecast_output.append(
                        forecast_step, ignore_index=True)
                    export_model_results(
                        sku, data_table["ML_tuning_output_table"], smape, value_for_model, 'Not Enough Data - Use Average', error, iter_metrics)
                else:
                    # Remove outliers
                    df_imputation = OutLiersImputation(df_temp, "historical_capacity")
                    results = []
                    results.append(adslot_id)
                    results.append(original_size - len(df_imputation.index))
                    # Missing dates fill
                    df_imputation, missing = MissingImputation(df_imputation, "date", idx)
                    # Monitoring
                    print(
                        "::: Added {} missing dates in {} :::".format(
                            missing, adslot_id
                        )
                    )
                    results.append(missing)
                    # Run the model on the TS
                    data_for_model = df_imputation[["date", "historical_capacity"]]
                    data_for_model.set_index("date", inplace=True)
                    tic = time.perf_counter()
                    forecast, smape, model = RunModel(
                        data_for_model, value_for_model["days"], value_for_model)
                    toc = time.perf_counter()
                    value_for_model["runtime"] = toc-tic
                    if (smape, model) == (0,0):
                        print('Arima Failed - Use average for Forecast')
                        # forecast_step = mean_as_forecast(df_temp, 'date', idx, adslot_id, adserver_id, segment_id, segment_name, iter_metrics, partition_date,value_for_model)
                        forecast_step = mean_as_forecast(df_temp, 'date', idx, adslot_id, adserver_id, iter_metrics, partition_date,value_for_model)
                        print("Save data to mysql")
                        write_forecast_to_mysql(forecast_step, data_table["output_table"])
                        print("Append adslot_id to output df")
                        forecast_output = forecast_output.append(
                            forecast_step, ignore_index=True)
                        export_model_results(
                            sku, data_table["ML_tuning_output_table"], smape, value_for_model, 'Failed Model - Use Average', error, iter_metrics)
                        continue
                    results.append(smape)
                    results.append(len(forecast))
                    #results.append(segment_id)
                    results_list.append(results)
                    # Reconstruct data field DF
                    idx1 = pd.date_range(Max_Date + pd.DateOffset(days=1),
                                        Max_Date + pd.DateOffset(days=value_for_model["days"]))
                    forecast_step = CreateForecastOutputDF(
                        forecast, idx1, adslot_id, adserver_id, iter_metrics, partition_date)
                        # forecast, idx1, adslot_id, adserver_id, segment_id, segment_name, iter_metrics, partition_date)
                    print("Save data to mysql")
                    write_forecast_to_mysql(forecast_step, data_table["output_table"])
                    print("Append adslot_id to output df")
                    forecast_output = forecast_output.append(
                        forecast_step, ignore_index=True)
                # Write output
                    # print("SaveDataToHive(sc, forecast_output, output_table_staging)")
                    # load_to_hive(forecast_output, data_table["output_table"])
                    export_model_results(
                        sku, data_table["ML_tuning_output_table"], smape, value_for_model, model, error, iter_metrics)
        final_data = pd.DataFrame(final_data_df)
    print('Results of data preprocessing')
    print(pd.DataFrame(results_list, columns=[
          'adserver_adslot_id', 'outliers removed', 'missing imputation', 'SMAPE value', 'forecast length' ''', 'segment_id' ''']))
    #conn = create_mysql_connection()
    #cursor = conn.cursor()
    table_name = 'ML_Model_Output_Validation'
    create_table_from_df(final_data, table_name)
    insert_data(final_data, table_name,partition_date)
    #cursor.close()
    #conn.close()    
    return 0
# Templated variables
if __name__ == "__main__":
    # Table
    data_table = {
        "inv_input_table": argv[1],
        "inv_segment_table": argv[2],
        "output_table": argv[3],
        "ML_tuning_output_table": argv[4],
        "reserved_table": argv[5],
        "final_output_table": argv[6]}
    print('arguments---')
    # Model init parameters
    value_for_model = {
        "days": int(argv[7]),
        "metrics": argv[8],
        "historical_ratio": int(argv[9]),
        "information_criterion": argv[10],
        "max_p": int(argv[11]),
        "max_q": int(argv[12]),
        "max_d": int(argv[13]),
        "max_P": int(argv[14]),
        "max_Q": int(argv[15]),
        "max_D": int(argv[16]),
        "start_p": int(argv[17]),
        "start_q": int(argv[18]),
        "start_d": int(argv[19]),
        "start_P": int(argv[20]),
        "start_Q": int(argv[21]),
        "start_D": int(argv[22]),
        "stationary": literal_eval(argv[23]),
        "error_action": argv[24],
        "suppress_warnings": literal_eval(argv[25]),
        "train": float(argv[26]),
        "test_stationarity" : literal_eval(argv[27])
    }
    print(value_for_model)
    print('arguments---')
    partition_date = argv[28]  # Always last value like 20241021
    rds_sql_user = argv[30] 
    rds_sql_pass = argv[31] 
    aws_rds_connection = argv[29]
    rdssql_schema = 'data_activation'
    rdssql_port = int(argv[32]) # int(argv[30])
    database = 'default'
    mysql_db.set(
        aws_rds_connection,
        'data_activation',
        rdssql_port,
        rds_sql_user,
        rds_sql_pass)
    spark_session = SparkSession.builder \
            .config("hive.exec.dynamic.partition.mode", "nonstrict") \
            .enableHiveSupport() \
            .getOrCreate()
    spark_context = SparkContext.getOrCreate()
    if intergration_check(data_table):
        # Clear output tables
        clear_table(data_table['output_table'])
        clear_table(data_table['ML_tuning_output_table'])
        main(data_table, partition_date, value_for_model)
        print("The reserved table is : "+data_table["reserved_table"])
        reserved_select_statement = """SELECT `date`, adserver_adslot_id, adserver_id,reserved  FROM {} WHERE `date` >= DATE_FORMAT(CURRENT_DATE, 'yyyy-MM-dd') """.format(data_table["reserved_table"])
        entire_reserved = ReadTable(rds_sql_user, rds_sql_pass, aws_rds_connection, rdssql_schema,rdssql_port, select_statement=reserved_select_statement, partition_column='reserved', lower_bound='1', upper_bound='1000', num_partitions='10', fetch_size = 10000)
        print(reserved_select_statement)
        reserved = entire_reserved.groupBy("date", "adserver_adslot_id", "adserver_id").agg(F.sum("reserved").alias("reserved"))
        reserved = reserved.filter(reserved['reserved'] >= 1)
        reserved = reserved.withColumn('date', F.date_format(F.col('date'), 'yyyy-MM-dd'))
        booking = load_booked_data_from_hive()
        booking_spark_df = spark_session.createDataFrame(booking)
        booking_spark_df = booking_spark_df.withColumn('date', F.date_format(F.col('date'), 'yyyy-MM-dd'))
        final_df_booked_reserved = ( booking_spark_df.join(reserved,on=['date', 'adserver_adslot_id', 'adserver_id'],how='full').groupBy('date', 'adserver_adslot_id', 'adserver_id').agg(F.sum('booked').alias('booked_amount'),F.sum('reserved').alias('reserved_amount')))
        #final_df_booked_reserved = final_df_booked_reserved['booked_amount'] + final_df_booked_reserved['reserved_amount']
        final_df_booked_reserved = final_df_booked_reserved.withColumn('booked', F.col('booked_amount') + F.col('reserved_amount'))
        final_df_booked_reserved = final_df_booked_reserved.drop('booked_amount', 'reserved_amount')
        forecastdf_select_statement = """SELECT * FROM {} """.format(data_table["output_table"])
        forecast_df = ReadTable(rds_sql_user, rds_sql_pass, aws_rds_connection, rdssql_schema,rdssql_port, select_statement=forecastdf_select_statement , partition_column='future_capacity', lower_bound='1', upper_bound='1000', num_partitions='10', fetch_size = 10000)
        #print("Printing Forecast_DF ")
        #forecast_df.show()
        df = forecast_df.join(final_df_booked_reserved, on=['date','adserver_adslot_id', 'adserver_id'], how='left')
        df = df.withColumn('Ratio', F.when(F.col('booked') > 0, F.col('booked') / F.greatest(F.col('future_capacity'), F.lit(1))).otherwise(None))
        df = df.withColumn('Week', F.weekofyear('Date'))
        weekly_average = df.groupBy(['Week','adserver_adslot_id','adserver_id']).agg(F.mean('Ratio').alias('Weekly_Average_Ratio'))
        df = df.join(weekly_average, on=['Week','adserver_adslot_id','adserver_id'], how='left')
        df = df.fillna({'Weekly_Average_Ratio': 0})
        # df = df.withColumn('formulated_forecast',F.when((F.col('future_capacity').isNull()) | (F.col('future_capacity') <= 0),F.col('booked')).otherwise(F.col('future_capacity')))
        df = df.withColumn('adjusted_forecast', F.round(F.when((F.col('booked').isNull()) | (F.col('booked') <= 0),F.col('future_capacity')).otherwise(F.when((F.col('future_capacity').isNull()) | (F.col('future_capacity') <= 0) | (F.col('future_capacity') < F.col('booked')),F.col('booked')).otherwise(F.col('future_capacity')) + (F.when((F.col('future_capacity') <= 0) | (F.col('future_capacity').isNull()), F.lit(1)).otherwise(F.when((F.col('future_capacity') < F.col('booked')), F.col('booked')).otherwise(F.col('future_capacity'))) * F.col('Weekly_Average_Ratio')))))
        result_df = df.select('Date', 'adserver_adslot_id', 'adserver_id', 'booked', 'future_capacity','Ratio', 'Weekly_Average_Ratio', 'adjusted_forecast')
        clear_table(data_table["final_output_table"])
        adjusted_final_data = result_df.select(F.col("date"), F.col("adserver_adslot_id"), F.col("adserver_id"), F.lit("NULL").alias("adserver_target_remote_id"), F.lit("NULL").alias("adserver_target_name"), F.lit("NULL").alias("adserver_target_type"), F.lit("NULL").alias("adserver_target_category"), F.lit("NULL").alias("adserver_target_code"),F.lit("IMPRESSION").alias("metric"), F.col("adjusted_forecast").alias("future_capacity")).orderBy("adserver_adslot_id", "date")
        adjusted_final_data_total_rows = adjusted_final_data.count()
        rows_per_partition = 10000
        count_of_partitions = (adjusted_final_data_total_rows + rows_per_partition - 1) // rows_per_partition
        TruncateRDS_table(rds_sql_user, rds_sql_pass, aws_rds_connection, rdssql_schema, rdssql_port, data_table["final_output_table"])
        Insert_Data_RDS(adjusted_final_data, data_table["final_output_table"],count_of_partitions,rows_per_partition)
        create_table_from_df(result_df, data_table["final_output_table"]+'_hive')
        TruncateRDS_table(rds_sql_user, rds_sql_pass, aws_rds_connection, rdssql_schema, rdssql_port, data_table["final_output_table"]+'_hive')
        Insert_Data_RDS(result_df, data_table["final_output_table"]+'_hive',count_of_partitions,rows_per_partition)