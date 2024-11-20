# Python imports
from sys import argv
import pandas as pd
import traceback

# Spark Imports
from pyspark.sql import SparkSession
from pyspark.context import SparkContext

# Import ML
from pyspark.ml import Estimator, Model, Pipeline
from pyspark.ml.evaluation import MulticlassClassificationEvaluator
from pyspark.ml.feature import VectorAssembler, StringIndexer, ChiSqSelector
from pyspark.ml.classification import *
from pyspark.ml.evaluation import *
from pyspark.ml.tuning import ParamGridBuilder, CrossValidator
from pyspark.sql.functions import when, first
import pyspark.sql.functions as F
from pyspark.sql.types import FloatType

# Custom Import
import sys
sys.path.append('/tmp/Libraries')
from ie_hive_connection import IEHiveConnection


# Function to fetch data from Hive
def fetch_from_hive(spark_session, query, database='default'):
    # Create connection
    conn = IEHiveConnection(database=database)

    # read in pandas and convert to hive
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
        df = spark_session.createDataFrame(result)
        print("converted to spark")
        conn.close()

    return df

# Function to load data to Hive


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
        df.write.saveAsTable(
            "{table_name}_staging".format(table_name=table_name))

        # PyHive is faster then using the HIVE CLI command
        conn = IEHiveConnection(database=database)

        # Since dynamic partitioning is enabled I do not need to specity the partition column in the insert
        cursor = conn.cursor()
        cursor.execute(
            "INSERT OVERWRITE TABLE {table_name} SELECT * FROM {table_name}_staging".format(table_name=table_name))
        conn.close()
        print("Data written into table: {}".format(table_name))
    else:
        print("[DM3][ERROR] The DF has not elements, please check the validation rules")

# Function to train random Forest Model
# Arguments:
# train: training data,
# rseed: random seed for result reproducibility
# max_bins: No. of categories for Feature with max no. of categories


def train_random_forest(train, rseed, max_bins):
    # Identify the festures
    input_list = [i for i in train.columns if i != 'target' and i != 'userid']

    # Set the pipeline
    otherIndexer = StringIndexer(inputCols=input_list, outputCols=[
                                 i+"_idx" for i in input_list], handleInvalid="skip")
    # Merges multiple columns into a vector column
    vecAssembler = VectorAssembler(
        inputCols=[i+"_idx" for i in input_list], outputCol="input")
    targetIndexer = StringIndexer(
        inputCol="target", outputCol="target_idx", handleInvalid="skip")
    selector = ChiSqSelector(numTopFeatures=100, featuresCol='input',
                             outputCol='selectedFeatures', labelCol='target_idx')
    rf = RandomForestClassifier(featuresCol="selectedFeatures", labelCol="target_idx",
                                predictionCol="prediction", seed=rseed, maxBins=max_bins)  # Random Forest

    # Create the pipeline
    rf_pipeline = Pipeline(
        stages=[otherIndexer, vecAssembler, targetIndexer, selector, rf])

    # Optimize the RF
    paramGrid = (ParamGridBuilder().addGrid(
        rf.maxDepth, [8, 10]).addGrid(rf.numTrees, [100, 125]).build())
    evaluator = MulticlassClassificationEvaluator(
        labelCol="target_idx", metricName="accuracy")
    cv_RF = CrossValidator(estimator=rf_pipeline, estimatorParamMaps=paramGrid,
                           evaluator=evaluator, numFolds=2, seed=rseed)

    # Output the best model
    rf_model = cv_RF.fit(train)
    print("[SUCCESS] Model Computed!")

    return rf_model

# To extract max probability


def max_binarizer(vector):
    max_val = float(max(vector))

    return max_val


def gender_model(car_gender, user_data):
    print("[INFO] Running Gender model")
    # Get user data
    gender_data = user_data.join(car_gender, 'userid', how="inner").drop(
        *["age", "partition_date"])
    no_gender_data = user_data.join(
        car_gender, 'userid', how="leftanti").drop(*["age", "partition_date"])

    # 0 = MALE, 1 = FEMALE
    gender_data = gender_data.withColumn("target", when(
        gender_data.gender == Gender_Ranges[0], 0).otherwise(1)).drop("gender")

    # Split in Train & Test
    training, test = gender_data.randomSplit([0.7, 0.3], seed=random_seed)
    training.cache()

    # Find feature having highest unique values and pass it as maxBins hyperparameter
    expression = [F.countDistinct(c).alias(c) for c in training.columns[1:]]
    x = training.select(*expression).collect()
    max_bins = max([x[0][i] for i in range(len(training.columns[1:]))]) + 1

    # Train the model
    gender_rf = train_random_forest(training, random_seed, max_bins)

    # Compute error score
    evaluator = MulticlassClassificationEvaluator(
        labelCol="target_idx", predictionCol="prediction")
    accuracy = evaluator.evaluate(gender_rf.transform(test))

    print("Accuracy = %s" % (accuracy))
    print("Test Error = %s" % (1.0 - accuracy))

    # Run it on all the users
    gender_global = gender_rf.transform(
        no_gender_data.withColumn("target", F.lit(0)))
    gender_global = gender_global["userid", "prediction", "probability"] \
        .withColumn("gender", when(gender_global.prediction == 0, Gender_Ranges[0]).otherwise(Gender_Ranges[1])) \
        .withColumn("accuracy_gender", max_bin_udf(gender_global["probability"]))["userid", "gender", "accuracy_gender"]

    # Build final DF with Threshold
    lal_gender = gender_global.where(
        gender_global["accuracy_gender"] >= threshold_gender)

    return lal_gender


def age_model(car_age, user_data):
    print("[INFO] Running Age model")
    # Get user data
    age_data = user_data.join(car_age, 'userid', how="inner").drop(
        *["gender", "partition_date"])
    no_age_data = user_data.join(car_age, 'userid', how="leftanti").drop(
        *["gender", "partition_date"])

    # 1 = MALE, 0 = FEMALE
    age_data = age_data.withColumn("target", when(age_data.age == Age_Ranges[0], 0)
                                   .otherwise(when(age_data.age == Age_Ranges[1], 1)
                                              .otherwise(when(age_data.age == Age_Ranges[2], 2)
                                                         .otherwise(when(age_data.age == Age_Ranges[3], 3)
                                                                    .otherwise(when(age_data.age == Age_Ranges[4], 4)
                                                                               .otherwise(when(age_data.age == Age_Ranges[5], 5)
                                                                                          .otherwise(when(age_data.age == Age_Ranges[6], 6)))))))

                                   ).drop("age")

    # Split in Train & Test
    training, test = age_data.randomSplit([0.7, 0.3], seed=random_seed)
    training.cache()

    expression = [F.countDistinct(c).alias(c) for c in training.columns[1:]]
    x = training.select(*expression).collect()
    max_bins = max([x[0][i] for i in range(len(training.columns[1:]))]) + 1

    # Train the model
    age_rf = train_random_forest(training, random_seed, max_bins)

    # Compute error score
    evaluator = MulticlassClassificationEvaluator(
        labelCol="target_idx", predictionCol="prediction")
    accuracy = evaluator.evaluate(age_rf.transform(test))

    print("Accuracy = %s" % (accuracy))
    print("Test Error = %s" % (1.0 - accuracy))

    # Run it on all the users
    age_global = age_rf.transform(no_age_data.withColumn("target", F.lit(0)))
    age_global = age_global["userid", "prediction", "probability"] \
        .withColumn("age", when(age_global.prediction == 0, Age_Ranges[0])
                    .otherwise(when(age_global.prediction == 1, Age_Ranges[1])
                               .otherwise(when(age_global.prediction == 2, Age_Ranges[2])
                                          .otherwise(when(age_global.prediction == 3, Age_Ranges[3])
                                                     .otherwise(when(age_global.prediction == 4, Age_Ranges[4])
                                                                .otherwise(when(age_global.prediction == 5, Age_Ranges[5])
                                                                           .otherwise(when(age_global.prediction == 6, Age_Ranges[6])))))))) \
        .withColumn("accuracy_age", max_bin_udf(age_global["probability"]))["userid", "age", "accuracy_age"]

    # Build final DF with Threshold
    lal_age = age_global.where(age_global["accuracy_age"] >= threshold_age)

    return lal_age


def main(database: str = 'default'):
    # Get Context

    spark_session = SparkSession.builder \
        .config("hive.exec.dynamic.partition.mode", "nonstrict") \
        .enableHiveSupport() \
        .getOrCreate()
    spark_session.sql(f"USE {database}")

    spark_context = SparkContext.getOrCreate()
    spark_context.setLogLevel("INFO")

    # Define UDF to extract accuracy
    max_bin_udf = F.udf(max_binarizer, FloatType())

    # Import CAR_SocioDemo
    car_sociodemo = fetch_from_hive(spark_session, "SELECT * FROM {} where partition_date = {}".format(
        car_table, partition_date))

    # Replace empty string with NULLs
    car_sociodemo = car_sociodemo.withColumn('age', when(
        F.col('age') == '', None).otherwise(F.col('age')))
    car_sociodemo = car_sociodemo.withColumn('gender', when(
        F.col('gender') == '', None).otherwise(F.col('gender')))

    # Split in Age & Gender
    car_age = car_sociodemo.where(F.col("age").isNotNull())
    car_gender = car_sociodemo.where(F.col("gender").isNotNull())

    # Import hystorical data
    # TODO: Check partition_date logic
    user_data = fetch_from_hive(spark_session, "SELECT {} FROM {} AS a JOIN {} AS b ON a.dmp_userid = b.dmp_userid AND a.partition_date = b.partition_date WHERE a.partition_date = {}".format(
        ','.join(features), user_table, matching_table, partition_date))

    # Call the models
    lal_gender = gender_model(car_gender, user_data)
    lal_age = age_model(car_age, user_data)

    # Remove Duplicates
    lal_age = lal_age.orderBy(lal_age.accuracy_age.desc()).groupBy("userid").agg({"age": "first", "accuracy_age": "first"}).withColumnRenamed(
        "first(age)", "age").withColumnRenamed("first(accuracy_age)", "accuracy_age")
    lal_gender = lal_gender.orderBy(lal_gender.accuracy_gender.desc()).groupBy("userid").agg({"gender": "first", "accuracy_gender": "first"}).withColumnRenamed(
        "first(gender)", "gender").withColumnRenamed("first(accuracy_gender)", "accuracy_gender")

    # Compile end result and write to Hive
    print('[INFO] Both model computed, saving output')
    lal_lookalike = lal_age.join(lal_gender, how="full", on=["userid"])[
        "userid", "age", "gender", "accuracy_age", "accuracy_gender"]
    lal_lookalike = lal_lookalike.join(car_age, how="full", on=["userid"]).select("userid", F.coalesce(
        lal_lookalike["age"], car_age["age"]), lal_lookalike["gender"], lal_lookalike["accuracy_age"], lal_lookalike["accuracy_gender"]).withColumnRenamed("coalesce(age, age)", "age")
    lal_lookalike = lal_lookalike.join(car_gender, how="full", on=["userid"]).select("userid", lal_lookalike["age"], F.coalesce(
        lal_lookalike["gender"], car_gender["gender"]), lal_lookalike["accuracy_age"], lal_lookalike["accuracy_gender"]).withColumnRenamed("coalesce(gender, gender)", "gender")

    #lal_lookalike = lal_lookalike.union(car_age.withColumn("accuracy_age", F.lit(None)).withColumn("accuracy_gender", F.lit(None)).drop('partition_date'))
    #lal_lookalike = lal_lookalike.union(car_gender.withColumn("accuracy_age", F.lit(None)).withColumn("accuracy_gender", F.lit(None)).drop('partition_date'))

    # Write result to hive
    # drop old stagin
    try:
        spark_session.sql("DROP TABLE {}_staging".format(output_table))
    except Exception as e:
        print("[DEBUG] staging table doesn't exist: {}".format(e))
    finally:
        load_to_hive(lal_lookalike, output_table,
                     'partition_date', partition_date)
        spark_session.sql("DROP TABLE {}_staging".format(output_table))

    print('[SUCCESS] All done!')


# Templated variables
__name__ = "__main__"
if __name__ == "__main__":
    # TODO: Validation on the argument

    # =============== CONFIGS ===============
    # car_table = "TEST_CAR_SocioDemo"
    # user_table = "TEST_TRF_UserData"
    # matching_table = "TEST_STG_UserMatching"
    # output_table = 'TEST_LAL_SocioDemo'
    # partition_date = "20210712"
    #
    # # MODEL PARAMETERS
    # random_seed = 123456
    # features = ["userid", "browser", "device", "operatingsystem", "url", "sitedata"]
    # Age_Ranges = ["18-25","26-35","36-45","46-55","56-65","66-75","76-85"]
    # Gender_Ranges = ["Male", "Female"]
    # Days = 10
    #
    # # Threshold
    # threshold_gender = 0.6
    # threshold_age = 0.6
    # =======================================

    # Tables
    car_table = argv[1]
    user_table = argv[2]
    matching_table = argv[3]
    output_table = argv[4]

    # MODEL PARAMETERS
    random_seed = 123456
    features = eval(argv[5])
    Age_Ranges = eval(argv[6])
    Gender_Ranges = eval(argv[7])

    # Threshold
    threshold_gender = argv[8]
    threshold_age = argv[9]

    # Partition must be the last
    partition_date = argv[10]

    try:
        max_bin_udf = F.udf(max_binarizer, FloatType())
        main()
    except Exception as e:
        print(e)
        traceback.print_tb(e.__traceback__)

# EOF
