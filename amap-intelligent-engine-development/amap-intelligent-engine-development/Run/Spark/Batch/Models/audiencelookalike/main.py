
##### GENERAL IMPORTS
from pyspark.context import SparkContext
import pandas as pd
import traceback
import pymysql
import gc 
import re
import os
import sys

import datetime as DT
from sys import argv
import numpy as np
from datetime import date
from datetime import datetime

import pyspark
from pyspark.sql import SparkSession
from pyspark.sql.functions import col,lit

from scipy.stats import f_oneway
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
from sklearn.metrics import confusion_matrix
from sklearn.model_selection import train_test_split, GridSearchCV
from xgboost import XGBClassifier
from sklearn import metrics
from sklearn.metrics import precision_score, recall_score, roc_curve, roc_auc_score,f1_score,auc
import json

import pyspark.sql.functions as F
from pyspark.sql import DataFrame
from pyspark.sql.types import *
import boto3
from py4j.protocol import Py4JJavaError
from io import StringIO
import pickle
# Custom Import
sys.path.append('/tmp/Libraries')
from ie_hive_connection import IEHiveConnection
from ie_hdfs_utils import pkl_from_hdfs

#Establish Connection:Entering Hive credentials
# class hive_db:
#     host = "localhost"
#     port = 10000
#     username = "hadoop"
#     configuration = { 'hive.txn.manager': 'org.apache.hadoop.hive.ql.lockmgr.DbTxnManager'}
#
#     @classmethod
#     def set(cls, host, port, username, configuration):
#         cls.host = host
#         cls.port = port
#         cls.username = username
#         cls.configuration = configuration

#Function to create hive connection
def create_hive_connection():
    try:
        # connection = hive.Connection(
        #     host=hive_db.host,
        #     port=hive_db.port,
        #     username=hive_db.username,
        #     configuration=hive_db.configuration)
        connection = IEHiveConnection()
        print("Establishing Hive connection")
    except ConnectionError as e:
        print(f"The error '{e}' occurred")
        raise ConnectionError("Hive Connection Failed.")
    return connection

#Establish Connection:Entering mysql credentials     
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

#Function to create mysql connection
def create_mysql_connection():
    try:
        connection = pymysql.connect(
            host=mysql_db.host,
            database=mysql_db.database,
            port=mysql_db.port,
            user=mysql_db.user,
            password= mysql_db.password)
        print("Establishing Mysql connection")
    except Error as e:
        print(f"The error '{e}' occurred")
        raise ConnectionError("mySQL Connection Failed.")
    return connection

#Function to write table to hive
def load_to_hive_execute(df) -> None:
    if df.head(1):
        conn = IEHiveConnection()
    
    ### Adding partition column
        df = df.withColumn("partition_date", lit(partition_date))
        
        cursor = conn.cursor()
        spark_session.sql("DROP TABLE IF EXISTS trf_dp_car_sociodemo_enriched_temp")
        cursor.execute("DELETE FROM dp_car_sociodemo_enriched WHERE partition_date = {}".format(partition_date))
        df.write.mode('overwrite').saveAsTable("trf_dp_car_sociodemo_enriched_temp")
        cursor.execute("INSERT INTO TABLE dp_car_sociodemo_enriched SELECT * FROM trf_dp_car_sociodemo_enriched_temp")
        print("The data is inserted in dp_car_sociodemo_enriched")
        spark_session.sql("DROP TABLE IF EXISTS trf_dp_car_sociodemo_enriched_temp")
        print('output saved') 
        conn.close()
    else:
        print("[DM3][ERROR] The DF has not elements, please check the validation rules")
        


#Function to write to s3 bucket using pandas dataframe      
def write_data_to_csv_on_s3_execute(dataframe, bucket, path): 
    """ Write pandas dataframe to a CSV on S3 """ 
    try: 
        print("Writing {} records to {}".format(len(dataframe), path)) 
        filepath = f"s3://{bucket}/{path}"
        csv_buffer = StringIO() 
        dataframe.to_csv(csv_buffer, sep=",", index=False) 
        s3_resource = boto3.resource("s3") 
        s3_resource.Object(bucket, path).put(Body=csv_buffer.getvalue())
        print("File writtern to s3 bucket")
    except: 
        logger.error("ERROR: Unexpected error: Could not load the file to S3 Bucket.") 
        sys.exit()
        


      
################################################################## MODEL EXECUTION #####################################################################################
# getting hist_data
def hist_flag_data(model):
    if model == execute_model[0]:
        query = "SELECT * FROM TRF_Am_Lookalike_Historical_Logic WHERE partition_date = {} AND hist_enrich != 0 AND age_enrich != 0".format(partition_date)
        df_hist_flagData = pd.read_sql(query,hive_connection)
        df_hist_flagData = pd.DataFrame(df_hist_flagData)
        
    elif model == execute_model[1]:
        query = "SELECT * from TRF_Am_Lookalike_Historical_Logic where partition_date = {} and hist_enrich != 0 and gender_enrich != 0".format(partition_date)
        df_hist_flagData = pd.read_sql(query,hive_connection)
        df_hist_flagData = pd.DataFrame(df_hist_flagData)
        
    
    cols_remap = {key: key.split(".")[1] for key in df_hist_flagData.columns}
    df_hist_flagData.rename(columns=cols_remap, inplace=True)
    return df_hist_flagData
        
        

# getting data from sql , table name --> DP_Car_Sociodemo
def get_sociodemo_data_execute(model):
    if model == execute_model[0]:
        query = "SELECT dp_userid,{} FROM data_activation.DP_Car_Sociodemo where (partition_date = {})".format(execute_model[0],partition_date)
    if model == execute_model[1]:
        query = "SELECT dp_userid,{} FROM data_activation.DP_Car_Sociodemo where (partition_date = {})".format(execute_model[1],partition_date)
    df_car = pd.read_sql(query,mysql_connection)
    df_car_sociodemo = pd.DataFrame(df_car)
    return df_car_sociodemo


########### 1 as Male and 0 as Female
def execute_gender_model(BUCKET_NAME):
   
    # KEY_NAME = 'data/ml_models/audiencelookalike/lookalike_gender/gender_model.pkl'
    KEY_NAME = '/tmp/audiencelookalike/saved_model/lookalike_gender/gender_model.pkl'
    # = boto3.client('s3')
    
    # Download the serialized model from S3
    #serialized_model = s3.get_object(Bucket=BUCKET_NAME, Key=KEY_NAME)['Body'].read()
    
    # Deserialize the model using pickle
    xgb_model_loaded_gender = pickle.load(pkl_from_hdfs(KEY_NAME))
    
    # getting caruserbehaviour data
    query = "select * from dp_car_user_behaviour where (partition_date = {})".format(partition_date)
    df_modelbase=pd.read_sql(query,hive_connection)
    df_modelbase = pd.DataFrame(df_modelbase)
    #df_modelbase.columns = df_modelbase.columns.str.replace('dp_car_user_behaviour.', '')
    cols_remap = {key: key.split(".")[1] for key in df_modelbase.columns}
    df_modelbase.rename(columns=cols_remap, inplace=True)
    
    query1="select attributes from trf_am_lookalike_model_features where model_name = 'gender'"
    df_var_list= pd.read_sql(query1,hive_connection)
    df_var_list = pd.DataFrame(df_var_list)
    df_var_list=df_var_list['attributes'].tolist()
 
    ##datframe with only attributes
    df_final_model=df_modelbase[df_var_list+['dp_userid']]

    # importing the car sociodemo data
    df_car_sociodemo = get_sociodemo_data_execute(execute_model[1])
    # users having gender info in df_car_sociodemo -- table (1)
    sociodemousers_gender_avail = df_car_sociodemo.loc[(df_car_sociodemo[execute_model[1]] !='') & (df_car_sociodemo[execute_model[1]].notnull())]
    sociodemousers_gender_avail.rename(columns = {execute_model[1]:'prediction_gender'}, inplace = True)
    sociodemousers_gender_avail = pd.merge(sociodemousers_gender_avail[['dp_userid','prediction_gender']],df_final_model['dp_userid'],how='inner',on='dp_userid')
    sociodemousers_gender_avail['pred_prob_max_gender'] = 1
    sociodemousers_gender_avail['predicted_probability_gender'] = 1
    sociodemousers_gender_avail['known_user_g'] = 1

    
    #getting those users who does not have info in sociodemo data
    # carrying out anti join using merge method
    df3 = df_final_model.merge(sociodemousers_gender_avail, on='dp_userid')
    df_final_model = df_final_model[~df_final_model['dp_userid'].isin(df3['dp_userid'])]
    
    # Here we import the hist_flag file to check which user has the previous records for gender or not in caruserbehaviour
    
    # importing hist_data
    df_hist_flagData = hist_flag_data(execute_model[1])
    
    # users those have the hist enrich details ---- table(2) , column name ===>  
    df_hist_users = pd.merge(df_final_model['dp_userid'],df_hist_flagData[['dp_userid','enrich_gender_val']],how='inner',on='dp_userid')
    df_hist_users.rename(columns = {'enrich_gender_val':'prediction_gender'}, inplace = True)
    df_hist_users['pred_prob_max_gender'] = 1
    df_hist_users['predicted_probability_gender'] = 1
    df_hist_users['known_user_g'] = 1
    
    # getting those users who does not have the details in hist
    # carrying out anti join using merge method
    df3 = df_final_model.merge(df_hist_flagData['dp_userid'], on='dp_userid')
    df_final_model = df_final_model[~df_final_model['dp_userid'].isin(df3['dp_userid'])]

    dp_userids=df_final_model['dp_userid']
    df_final_model = df_final_model.drop(['dp_userid'], axis=1)
    dp_userids = pd.DataFrame(dp_userids)
    # Create an empty list to store the results
    
    
    if len(df_final_model)<1:
        print('No records available for model prediction')
        results_df_lal_gender = pd.DataFrame(columns = ['dp_userid','prediction_gender','pred_prob_max_gender','predicted_probability_gender'])
    else:
    
        
        results_lal = []
        
        # Loop over the samples in the test set
        for i in range(len(df_final_model)):
            # Get the true and predicted label for the i-th sample
            y_pred_prob_lal =  xgb_model_loaded_gender.predict_proba(df_final_model.iloc[[i]])
            y_pred_lal = y_pred_prob_lal.argmax()
            y_prob = y_pred_prob_lal[0, y_pred_lal]
            
            #print(y_prob)
            # Add the results to the list
            results_lal.append({'prediction_gender': y_pred_lal, 'pred_prob_max_gender': y_prob})
        y_predd=xgb_model_loaded_gender.predict_proba(df_final_model)
    
        # Create a DataFrame with a single "list" column
        df_arr = pd.DataFrame(columns=["list"])
    
        # Set the values of each row to the corresponding list from the array
        for i in range(len(y_predd)):
            df_arr.loc[i] = [y_predd[i]]
        
        # Display the DataFrame
       
        
        # Convert the list of dictionaries to a DataFrame
        results_lal = pd.DataFrame(results_lal)
        results_lal['predicted_probability_gender'] = df_arr["list"]
        results_lal['pred_prob_max_gender'] = results_lal['pred_prob_max_gender'].round(2)
        results_lal['dp_userid'] = dp_userids['dp_userid'].tolist()
        results_df_lal_gender = results_lal
        results_df_lal_gender['prediction_gender'] = results_df_lal_gender['prediction_gender'].map({1: 'M', 0: 'F'})
        results_df_lal_gender['predicted_probability_gender']= results_df_lal_gender['predicted_probability_gender'].astype(str)

     
    # here we concatenate results_df_lal_gender with df_hist_users
    return pd.concat([results_df_lal_gender,df_hist_users,sociodemousers_gender_avail]).fillna(0)
    
def execute_age_model(BUCKET_NAME):
    #KEY_NAME = 'data/ml_models/audiencelookalike/lookalike_age/age_model.pkl'
    KEY_NAME = '/tmp/audiencelookalike/saved_model/lookalike_age/age_model.pkl'
    s3 = boto3.client('s3')
    
    # Download the serialized model from S3
    #serialized_model = s3.get_object(Bucket=BUCKET_NAME, Key=KEY_NAME)['Body'].read()
    
    # Deserialize the model using pickle
    xgb_model_loaded_age = pickle.load(pkl_from_hdfs(KEY_NAME))
    
    # getting caruserbehaviour data
    query = "select * from dp_car_user_behaviour where (partition_date = {})".format(partition_date)
    df_modelbase=pd.read_sql(query,hive_connection)
    df_modelbase = pd.DataFrame(df_modelbase)
    cols_remap = {key: key.split(".")[1] for key in df_modelbase.columns}
    df_modelbase.rename(columns=cols_remap, inplace=True)
    
    query1="select attributes from trf_am_lookalike_model_features where model_name = 'age'"
    df_var_list_age= pd.read_sql(query1,hive_connection)
    df_var_list_age = pd.DataFrame(df_var_list_age)
    var_list_age_final=df_var_list_age['attributes'].tolist()
    
    ##Final datframe
    df_final_model_age = df_modelbase[var_list_age_final+['dp_userid']]

    # importing the car sociodemo data
    df_car_sociodemo = get_sociodemo_data_execute(execute_model[0])

    # users having age info in df_car_sociodemo -- table (1) 
    sociodemousers_age_avail = df_car_sociodemo.loc[(df_car_sociodemo[execute_model[0]] !='') & (df_car_sociodemo[execute_model[0]].notnull())]
    sociodemousers_age_avail.rename(columns = {execute_model[0]:'prediction_age'}, inplace = True)
    
    sociodemousers_age_avail = pd.merge(sociodemousers_age_avail[['dp_userid','prediction_age']],df_final_model_age['dp_userid'],how='inner',on='dp_userid')
    sociodemousers_age_avail['pred_prob_max_age'] = 1
    sociodemousers_age_avail['predicted_probability_age'] = 1
    sociodemousers_age_avail['known_user_a'] = 1

    #getting those users who does not have info in sociodemo data
    # carrying out anti join using merge method
    df3 = df_final_model_age.merge(sociodemousers_age_avail, on='dp_userid')
    df_final_model = df_final_model_age[~df_final_model_age['dp_userid'].isin(df3['dp_userid'])]

    # Here we import the hist_flag file to check which user has the previous records for age or not.
    
    # importing hist_data
    df_hist_flagData = hist_flag_data(execute_model[0])
    
    # users those have the hist enrich details ---- table(2) 
    df_hist_users = pd.merge(df_final_model['dp_userid'],df_hist_flagData[['dp_userid','enrich_age_val']],how='inner',on='dp_userid')
    df_hist_users.rename(columns = {'enrich_age_val':'prediction_age'}, inplace = True)
    df_hist_users['pred_prob_max_age'] = 1
    df_hist_users['predicted_probability_age'] = 1
    df_hist_users['known_user_a'] = 1
    
    # getting those users who does not have the details in hist
    # carrying out anti join using merge method
    df3 = df_final_model.merge(df_hist_flagData['dp_userid'], on='dp_userid')
    df_final_model = df_final_model[~df_final_model['dp_userid'].isin(df3['dp_userid'])]

    dp_userids=df_final_model['dp_userid']
    df_final_model = df_final_model.drop(['dp_userid'], axis=1)
    
    dp_userids = pd.DataFrame(dp_userids)
    
    if len(df_final_model)<1:
        print('No records available in table for prediction')
        results_df_lal_age = pd.DataFrame(columns = ['dp_userid','prediction_age','pred_prob_max_age','predicted_probability_age',])
    else:
        # Create an empty list to store the results
        results_lal_age = []
        
        # Loop over the samples in the test set
        for i in range(len(df_final_model)):
            # Get the true and predicted label for the i-th sample
            y_pred_prob_lal_age =  xgb_model_loaded_age.predict_proba(df_final_model.iloc[[i]])
            y_pred_lal_age = y_pred_prob_lal_age.argmax()
            y_prob_age = y_pred_prob_lal_age[0, y_pred_lal_age]
            # Add the results to the list
            results_lal_age.append({'prediction_age': y_pred_lal_age, 'pred_prob_max_age': y_prob_age})
        
        y_predd_age=xgb_model_loaded_age.predict_proba(df_final_model)
    
        # Create a DataFrame with a single "list" column
        df_arr_age = pd.DataFrame(columns=["list_age"])
    
        # Set the values of each row to the corresponding list from the array
        for i in range(len(y_predd_age)):
            df_arr_age.loc[i] = [y_predd_age[i]]
        
        # Convert the list of dictionaries to a DataFrame
        results_lal_age = pd.DataFrame(results_lal_age)
        results_lal_age['predicted_probability_age'] = df_arr_age["list_age"]
        results_lal_age['pred_prob_max_age'] = results_lal_age['pred_prob_max_age'].round(2)
    
        results_lal_age['dp_userid'] = dp_userids['dp_userid'].tolist()
        results_df_lal_age = results_lal_age
        map_sub = {}
        a = 0
        for i in age_bucket:
            map_sub[a] = i
            a+=1
        results_df_lal_age['prediction_age'] = results_df_lal_age['prediction_age'].map(map_sub)
        results_df_lal_age['predicted_probability_age']= results_df_lal_age['predicted_probability_age'].astype(str)

    return  pd.concat([results_df_lal_age,df_hist_users,sociodemousers_age_avail]).fillna(0)
    

#Function to convert the columns datatype from object to string
def convert_df_dtypes(df):
    for i in (df.columns.tolist()):
        if (df[i].dtypes == 'object'):
            df[i] = df[i].astype('str')
    return df
    
# condition for making known user flag    
def conditions(df):
    if (df['known_user_g'] == 1) or (df['known_user_a'] == 1): 
        return 1
    else:
        return 0

    
def merged(df_gender,df_age):

    df_gender = df_gender[['dp_userid','prediction_gender', 'pred_prob_max_gender',
       'predicted_probability_gender', 'known_user_g']]
    df_age = df_age[['dp_userid', 'prediction_age', 'pred_prob_max_age',
       'predicted_probability_age', 'known_user_a']]
       
    # have to do full outer join to get the all users from both tables.
    merged_df = df_age.merge(df_gender, how="outer", on=["dp_userid"])
    merged_df = merged_df.fillna(0)
    merged_df = merged_df.replace(np.nan,0)
 
    merged_df['known_user'] = merged_df.apply(conditions, axis=1)
    merged_df = merged_df.drop(['known_user_g','known_user_a'],axis = 1)
    # adding city and country columns
    query = "SELECT dp_userid,city,country FROM data_activation.DP_Car_Sociodemo where (partition_date = {})".format(partition_date)
    df_car = pd.read_sql(query,mysql_connection)
    df_car_sociodemo = pd.DataFrame(df_car)
    
    final_merged_df = pd.merge(merged_df,df_car_sociodemo,how='inner',on='dp_userid')
    final_merged_df = final_merged_df[['dp_userid','prediction_gender','pred_prob_max_gender', 'predicted_probability_gender','prediction_age','pred_prob_max_age','predicted_probability_age', 'known_user', 'city','country']]
    
    final_merged_df = final_merged_df.drop_duplicates(keep='first')
    final_merged_df = final_merged_df.fillna(0)
    final_merged_df = final_merged_df.replace(np.nan,0)
    final_merged_df = convert_df_dtypes(final_merged_df)
    return final_merged_df


def function_model_execute(execute_model,BUCKET_NAME):
    if (execute_model[0] == '' and execute_model[1] == '') :
        print("Please select at least one model.")
        return 0
    try:
        for i in execute_model:
            if i == 'gender' or i == 'sex':        
                gender_output=execute_gender_model(BUCKET_NAME)
                gender_output = convert_df_dtypes(gender_output)
                
            elif i == 'age':
                #age_output,df_hist_users_age=execute_age_model(BUCKET_NAME)
                age_output=execute_age_model(BUCKET_NAME)
                age_output = convert_df_dtypes(age_output)
            else:
                print("Enter model value")
            

               
        if (execute_model[0] == ''):
            age_output = pd.DataFrame(columns = ['dp_userid', 'prediction_age', 'pred_prob_max_age','predicted_probability_age', 'known_user_a'])
        elif (execute_model[1] == ''):
            gender_output =  pd.DataFrame(columns =['dp_userid','prediction_gender', 'pred_prob_max_gender','predicted_probability_gender', 'known_user_g'])
 
        
        merged_output= merged(gender_output, age_output)
        if (len(merged_output)<1):
            print("Can't load to hive since final output don't have any rows.")
        else:
            merged_output_sparkDF = spark_session.createDataFrame(merged_output)
            load_to_hive_execute(merged_output_sparkDF)

            ################ code to write to S3
            query="select * from dp_car_sociodemo_enriched WHERE (partition_date={})".format(partition_date)
            dp_car_sociodemo_enriched = pd.read_sql(query,hive_connection)
            dp_car_sociodemo_enriched = pd.DataFrame(dp_car_sociodemo_enriched)
            cols_remap = {key: key.split(".")[1] for key in dp_car_sociodemo_enriched.columns}
            dp_car_sociodemo_enriched.rename(columns=cols_remap, inplace=True)
            path = "data/outbound/crm_analytics/DP_Car_Sociodemo_Enriched/DP_Car_Sociodemo_Enriched.csv"
            write_data_to_csv_on_s3_execute(dp_car_sociodemo_enriched, BUCKET_NAME, path)

        hive_connection.close()

    except Exception as e:
        print(e)
        traceback.print_tb(e.__traceback__)


########################################## MODEL TRAINING #########################################################

#Function to write to s3 bucket using pandas dataframe

def save_model(xgb_model,model,BUCKET_NAME):
    # Define the S3 bucket and key where you want to save the trained model
    
    if model == train_model[0]:
        KEY_NAME = '/tmp/audiencelookalike/saved_model/lookalike_age/age_model.pkl'
    elif model == train_model[1]:
        KEY_NAME = '/tmp/audiencelookalike/saved_model/lookalike_gender/gender_model.pkl'
    else:
        print("incorrect model name")
    
    # Serialize the trained model using pickle
    model = xgb_model
    pickle.dump(model,open(KEY_NAME, 'wb'))


def save_model_s3(xgb_model, model, BUCKET_NAME):
    # Define the S3 bucket and key where you want to save the trained model
    
    if model == train_model[0]:
        KEY_NAME = 'data/ml_models/audiencelookalike/lookalike_age/age_model.pkl'
    elif model == train_model[1]:
        KEY_NAME = 'data/ml_models/audiencelookalike/lookalike_gender/gender_model.pkl'
    else:
        print("incorrect model name")
    
    # Serialize the trained model using pickle
    model = xgb_model
    serialized_model = pickle.dumps(model)
    
    # Create a connection to S3
    s3 = boto3.client('s3')
    
    # Upload the serialized model to S3
    s3.put_object(Bucket=BUCKET_NAME, Key=KEY_NAME, Body=serialized_model)
    
    
# writing the results like confusion matrix , precision, recall etc to s3 bucket.

def write_data_to_csv(dataframe, file_name, BUCKET_NAME, model): 
    """ Write pandas dataframe to a CSV on S3 """ 
 
    if model == train_model[0]:
        
        outdir = '/tmp/audiencelookalike/saved_model/lookalike_age'
        if not os.path.exists(outdir):
             os.makedirs(outdir,)

        filename = '{}/{}.csv'.format(outdir,file_name)

        print("Writing {} records to {}".format(len(dataframe), filename))
    elif model == train_model[1]:
        

        outdir = '/tmp/audiencelookalike/saved_model/lookalike_gender'
        if not os.path.exists(outdir):
             os.makedirs(outdir)

        filename = '{}/{}.csv'.format(outdir,file_name)
        print("Writing {} records to {}".format(len(dataframe), filename)) 
    
    dataframe.to_csv(filename, sep=",", index=False) 



def write_data_to_csv_on_s3(dataframe, file_name,BUCKET_NAME,model): 
    """ Write pandas dataframe to a CSV on S3 """ 
    try: 
        if model == train_model[0]:
            filename = 'data/ml_models/audiencelookalike/lookalike_age/{}.csv'.format(file_name)
            print("Writing {} records to {}".format(len(dataframe), filename))
        elif model == train_model[1]:
            filename = 'data/ml_models/audiencelookalike/lookalike_gender/{}.csv'.format(file_name)
            print("Writing {} records to {}".format(len(dataframe), filename)) 
        
        csv_buffer = StringIO() 
        dataframe.to_csv(csv_buffer, sep=",", index=False) 
        s3_resource = boto3.resource("s3") 
        print(BUCKET_NAME+filename)
        s3_resource.Object(BUCKET_NAME, filename).put(Body=csv_buffer.getvalue())
    except: 
        logger.error("ERROR: Unexpected error: Could not load the file to S3 Bucket.") 
        sys.exit()
        
    
# loading the data to hive 
def load_to_hive(index_list, model) -> None:

    # making a dataframe for storing into hive table.
    model_list = []
    for i in index_list:
        model_list.append(model)
    
    
    # first converting the features to spark data frame for loading to hive
    var_list=pd.DataFrame(list(zip(model_list, index_list)),columns=['model_name','attributes'])
    var_list_sparkDF = spark_session.createDataFrame(var_list)

    # storing data into temp table
    cursor = hive_connection.cursor()
    spark_session.sql("DROP TABLE IF EXISTS trf_am_lookalike_model_features_temp")

            
    # storing to hive
    if var_list_sparkDF.head(1):
        var_list_sparkDF.write.mode('overwrite').saveAsTable("trf_am_lookalike_model_features_temp")
        
        conn = IEHiveConnection()
        
        cursor = conn.cursor()
        # Deleting the exsisting record if any from hive before loading to the new featutres list in hive
        if model == train_model[0]:
            var_name = "'" +train_model[0]+"'"
            cursor.execute("DELETE FROM trf_am_lookalike_model_features WHERE model_name = {}".format(var_name))
        if model == train_model[1]:
            var_name = "'" +train_model[1]+"'"
            cursor.execute("DELETE FROM trf_am_lookalike_model_features WHERE model_name = {}".format(var_name))
        
        cursor.execute("INSERT INTO TABLE trf_am_lookalike_model_features SELECT * FROM trf_am_lookalike_model_features_temp")
        print("The data is inserted in trf_am_lookalike_model_features")
        spark_session.sql("DROP TABLE IF EXISTS trf_am_lookalike_model_features_temp")
        conn.close()
    else:
        print("[DM3][ERROR] The DF has not elements, please check the validation rules")


# Function to pass buckets for confusion matrix
def categ_function(age_bucket):
    var_actual = []
    var_predicted = []
    for i in age_bucket:
        x = 'Actual '+ i
        y = 'Predicted '+ i
        var_actual.append(x)
        var_predicted.append(y)
    return var_actual, var_predicted

# Funtions for collecting the data from tables          

# getting data from "ds_car_lookalike_modelbase" table
def get_car_data():
    query = "select * from dp_car_user_behaviour where (partition_date = {})".format(partition_date)
    # query = "select * from ds_car_lookalike_modelbase"
    df_modelbase=pd.read_sql(query,hive_connection)
    df_modelbase = pd.DataFrame(df_modelbase)
    if len(df_modelbase) == 0:
    # if there is no data, raise an error and exit the program
        print(f"No data found in dp_car_user_behaviour on partition date {partition_date}")
        sys.exit(1)
    else:
        df_modelbase
        # ...
    cols_remap = {key: key.split(".")[1] for key in df_modelbase.columns}
    df_modelbase.rename(columns=cols_remap, inplace=True)
    df_modelbase = df_modelbase.drop(columns=['last_navigation_date', 'last_transaction_date','purchase_date',  'navigation_date','partition_date'])
    # check if there is any data on the partition date
    return df_modelbase
    

# getting data from sql , table name --> DP_Car_Sociodemo

def get_sociodemo_data():
    if train_model[1] == "":
        query = "SELECT dp_userid,{} FROM data_activation.DP_Car_Sociodemo where (partition_date = {})".format(train_model[0],partition_date)
    elif train_model[0] == "":
        query = "SELECT dp_userid,{} FROM data_activation.DP_Car_Sociodemo where (partition_date = {})".format(train_model[1],partition_date)
    else:
        query = "SELECT dp_userid,{},{} FROM data_activation.DP_Car_Sociodemo where (partition_date = {})".format(train_model[0],train_model[1],partition_date)
    df_car = pd.read_sql(query,mysql_connection)
    df_car_sociodemo = pd.DataFrame(df_car)
    if len(df_car_sociodemo) == 0:
    # if there is no data, raise an error and exit the program
        print(f"No data found in df_car_sociodemo on partition date {partition_date}")
        sys.exit(1)
    else:
        df_car_sociodemo
        # ...
    return df_car_sociodemo


######################## age functions ############################

# required vairable in age in dp_car_user_behaviour -- >  
#dp_userid

def merge_sql_and_hive_data(df_car_sociodemo_age,df_modelbase_age):
    # merging sql and hive data on use_id.
    df_final_age = df_modelbase_age.merge(df_car_sociodemo_age, how='inner', on="dp_userid")
    
    #### Code to automate the bucket creation
    age_ranges=[]
    for i in age_bucket:
        age_ranges.append(int(i.split('-')[0]))
    age_ranges.append(int(age_bucket[-1].split('-')[1]))
   
   
    # df_final_age[train_model[0]] = df_final_age[train_model[0]].fillna(0)
    df_final_age[train_model[0]] = df_final_age[train_model[0]].replace('','0',regex = True)
    df_final_age[train_model[0]] = df_final_age[train_model[0]].astype(int)
    df_final_age['age_range']=pd.cut(df_final_age[train_model[0]],bins=age_ranges,labels=age_bucket)


    df_final_age = df_final_age.drop(columns=[train_model[0]])
    return df_final_age
    
# finding the fill rate and removing columns which have fill rate less than 5%. 
def fill_rate(df_final_age):
    # replace all 0 values with NaN
    df_fillrate_age=df_final_age.replace(0, np.nan)
 
    # calculate the fill rate of each column
    fill_rates_age = (1 - df_fillrate_age.isna().mean()) * 100
    
    # display the fill rates
    #print(fill_rates_age.tolist())
    
    for col, fill_rate in fill_rates_age.items():
        if fill_rate < 5:
            df_final_age.drop(columns=col, inplace=True)
    #print(df_final_age.columns.tolist())
    
    # dropping the unnessary columns again and also age column, since we now have age_range column and we are also dropping gender and city since we are going to make car for those variables also.
    # df_final_age_fillrate=df_final_age.drop(columns=['partition_date','last_trans_dt', 'last_nvig_dt','purchase_date','month_no','age','gender','city'])
    df_final_age_fillrate = df_final_age.copy()
    return df_final_age_fillrate
    
#df_final_age = fill_rate(df_final_age)


### Age Model Start
# splitting the data set into two , 1st where age_range columns have value & other does not have the value.
def split_avail_unavail_data_for_age(df_final_age_fillrate):
    # converting data type of "age_range" from 'categorical' to object type.
    df_final_age_fillrate['age_range'] = df_final_age_fillrate.age_range.astype(str)
    
    # filling NaN value with 0 in the age_range column
    df_final_age_fillrate['age_range']=df_final_age_fillrate['age_range'].replace(np.nan,'0')
    
    # Spliting the data frame into age avaialbe and not available 

    # DataFrame having city names
    df_final_age_available = df_final_age_fillrate[(df_final_age_fillrate['age_range'] != '0') & (df_final_age_fillrate['age_range'] != 'nan')]
    
    # DataFrame not having city names
    df_final_age_UNavailable = df_final_age_fillrate[df_final_age_fillrate['age_range'] == '0']
    
    return df_final_age_available
    
## Anova test - used for checking relationship bw categorical and continuous variable

# using one way anova test for the analysis of univariate  (means how each independent variable is related to our y variable(dependent variable))
def anova_test_age(df_final_age_available):
    # using one way anova test 

    # Set the dependent variable column name
    dependent_variable = 'age_range'
    
    df_final_age_anova = df_final_age_available.copy()
    
    if len(train_model[1]) !=0:
        if 'gender' in df_final_age_anova.columns:
            df_final_age_anova = df_final_age_anova.drop(columns=['gender','dp_userid'])
        elif 'sex' in df_final_age_anova.columns:
            df_final_age_anova = df_final_age_anova.drop(columns=['sex','dp_userid'])
    else:
        df_final_age_anova = df_final_age_anova.drop(columns=['dp_userid'])
        
    # Get a list of the independent variable column names
    independent_variables = df_final_age_anova.columns[df_final_age_anova.columns != dependent_variable]
    
    # making list of all the columns that have p<0.2.
    good_col=[]
    df_final_age_anova=df_final_age_anova.replace(np.nan,0)
    
    # Perform ANOVA on each independent variable and the dependent variable
    cate = ""
    for i in range(len(age_bucket)-1):
        x = "df_final_age_anova[col][df_final_age_anova[dependent_variable] == "+"'"+age_bucket[i]+"'"+"],"
        cate+=x
    x = "df_final_age_anova[col][df_final_age_anova[dependent_variable] == "+ "'"+ age_bucket[-1]+"'" +"]"
    cate+=x    
  
    for col in independent_variables:
        # f,p = f_oneway(df_final_age_anova[col][df_final_age_anova[dependent_variable] == '16-25'],df_final_age_anova[col][df_final_age_anova[dependent_variable] == '26-35'],df_final_age_anova[col][df_final_age_anova[dependent_variable] == '36-45'],df_final_age_anova[col][df_final_age_anova[dependent_variable] == '46-55'],df_final_age_anova[col][df_final_age_anova[dependent_variable] == '56-65'],df_final_age_anova[col][df_final_age_anova[dependent_variable] == '66-100'])
        class_var = eval(cate)
        f,p = f_oneway(*class_var)

        if p<1:
            #print(f'Independent variable: {col},F-statistic: {f:.2f},p-value: {p:.2f}')
            good_col.append(col)
   
    return good_col,df_final_age_anova

#### Random forest for the analysis of checking multicorelation and checking information value to filter out further top varaibles.

def Random_forest_classifier(df_final_age_anova,good_col):
    # getting the data for random forest using good_col
    df_random_forest_age=df_final_age_anova[good_col]
    
    # Split the data into features and target
    X_age = df_random_forest_age
    y_age = df_final_age_anova["age_range"]
    # print(X_age.shape)
    # print(y_age.shape)
    if X_age.shape[1]<1:
        print('Do not have enogh data for prediction')
        sys.exit()
        
    # Initialize a Random Forest classifier with 100 trees
    rf_age = RandomForestClassifier(n_estimators=110, max_depth=10, random_state=42)

    # Fit the model on your training data
    rf_age.fit(X_age, y_age)
    
    # Get feature importances
    feature_importances_age = pd.DataFrame(rf_age.feature_importances_,index = X_age.columns,columns=['importance']).sort_values('importance', ascending=False)

    
    # getting top featuring according to their importance 
    top_feature_age=pd.DataFrame(feature_importances_age)
    top_feature_age['importance'] = top_feature_age['importance'].astype(float)
    top_feature_list = top_feature_age[top_feature_age['importance']>0.01].index.tolist()
    print(top_feature_list)
    
    return top_feature_list


# # create scatter plot for continuous variable 
# sns.scatterplot(x=df_final_age_available['avg_order_price'], y=df_final_age_available['age'])

###Xgboost Model implementation
def XGB_classifier(top_feature_list,df_final_age_available):
    # top_feature_list = top_feature_list
    df_age_var_list=pd.DataFrame(top_feature_list,columns=['age_var'])
    
    if train_model[0] == 'age':
        min_size_df = df_final_age_available['age_range'].value_counts().to_frame().reset_index()
        min_size_df.columns=[train_model[0],'count']
        
    min_size = min(min_size_df['count'])
    if min_size < 29:
        print("Insufficient data to train model")
        sys.exit()

    ### code for creating balanced dataset
    df_final_age_available = (df_final_age_available.groupby('age_range', as_index=False)
        .apply(lambda x: x.sample(n=min_size))
        .reset_index(drop=True))
    # print(df_final_age_available.columns.tolist())
    
    X_age = df_final_age_available[top_feature_list]
    y_age = df_final_age_available["age_range"]

    # mapping the y_age with 0 , 1 ,2 , 3,  4, 5
    Subjects = {}
    # {"16-25":0,"26-35":1,"36-45":2,"46-55":3,"56-65":4,"65-100":5}
    a = 0
    for i in age_bucket:
        Subjects[i] = a
        a+=1
    y_age =df_final_age_available["age_range"].map(Subjects)
    

    # Splitting the dataset into the Training set and Test set
    X_train_age, X_test_age, y_train_age, y_test_age = train_test_split(
        X_age, y_age, test_size=0.3, random_state=42)
        
    
    # Fitting XGBoost to the training data
    age_xgb_model = XGBClassifier()
    
    
    # Define the hyperparameters to tune
    param_grid_city = {
        'learning_rate': [0.05],
        'max_depth': [3],
        'n_estimators': [15],
        'subsample': [1],
        'colsample_bytree': [1],
        'reg_alpha': [0.02],
        'reg_lambda': [0.02],
        'min_child_weight': [1,2,3],
        'gamma':[0]
    
    }
    
    # Use grid search with cross-validation to find the best hyperparameters
    grid_search_age = GridSearchCV(estimator=age_xgb_model, param_grid=param_grid_city, cv=5, n_jobs=-1, scoring='accuracy')
    grid_search_age.fit(X_train_age, y_train_age)
    
    # Select the best hyperparameters
    best_params_age = grid_search_age.best_params_
    #print(best_params_age)
    
    # Retrain the model using the best hyperparameters
    age_xg_model = XGBClassifier(**best_params_age)
    age_xg_model.fit(X_train_age, y_train_age)
    print('The accuracy of the xgboost classifier is {:.2f} out of 1 on the training data'.format(age_xg_model.score(X_train_age, y_train_age)))
    print('The accuracy of the xgboost classifier is {:.2f} out of 1 on the test data'.format(age_xg_model.score(X_test_age, y_test_age)))

    
    # predicting the values for test data
    y_pred_age = age_xg_model.predict(X_test_age)
    
    # function to get age buckets for confusion matrix
    var_actual, var_predicted = categ_function(age_bucket)

    # Compute the confusion matrix
    cm_age_test = confusion_matrix(y_test_age, y_pred_age)
    age_cm_score_test = pd.DataFrame(cm_age_test, index = var_actual, columns= var_predicted)
 
    Accuracy_Score = accuracy_score(y_test_age, y_pred_age)
    f1score=f1_score(y_test_age.values, y_pred_age,average = None)
    Precision_Score=metrics.precision_score(y_test_age.values, y_pred_age,average = None)
    Recall_Score=metrics.recall_score(y_test_age.values, y_pred_age,average = None)
    df_scores_test = pd.DataFrame({
         'Metric': ['Accuracy','Precision', 'Recall', 'F1 Score'],
         'Score': [Accuracy_Score,Precision_Score, Recall_Score, f1score]})
    age_cm_metrices_combined_test = pd.concat([ df_scores_test,age_cm_score_test], axis=1)

    print(age_cm_metrices_combined_test)
    
    
    # predicting the values for train data
    y_pred_age_train = age_xg_model.predict(X_train_age)
    
    # Compute the confusion matrix
    cm_age_train = confusion_matrix(y_train_age, y_pred_age_train)
    age_cm_score_train = pd.DataFrame(cm_age_train, index = var_actual, columns = var_predicted)

    Accuracy_Score = accuracy_score(y_train_age, y_pred_age_train)
    
    f1score=f1_score(y_train_age.values, y_pred_age_train,average = None)
    
    Precision_Score=metrics.precision_score(y_train_age.values, y_pred_age_train,average = None)
    
    Recall_Score=metrics.recall_score(y_train_age.values, y_pred_age_train,average = None)
    df_scores_train = pd.DataFrame({
         'Metric': ['Accuracy','Precision', 'Recall', 'F1 Score'],
         'Score': [Accuracy_Score,Precision_Score, Recall_Score, f1score]})
    age_cm_metrices_combined_train = pd.concat([ df_scores_train,age_cm_score_train], axis=1)
    print(age_cm_metrices_combined_train)

    return age_xg_model,X_train_age,y_train_age,X_test_age,y_test_age,age_cm_metrices_combined_test,age_cm_metrices_combined_train


############################ Gender functions #################################

# Merging two tables
def merge_for_final(df_hive,df_mysql):
    df_final_without = df_hive.merge(df_mysql, how='inner', on="dp_userid")
    return df_final_without

# Dropping columns which have fill rate less than 5%. 
def fill_rate_and_drop(df):
    df_fillrate=df.replace(0, np.nan)
    
    # calculate the fill rate of each column
    fill_rates = (1 - df_fillrate.isna().mean()) * 100

    for col, fill_rate in fill_rates.items():
        if fill_rate < 5:
            df.drop(columns=col, inplace=True)
            
    
    # if ('M' in df_fillrate[train_model[1]].unique() or 'F' in df_fillrate[train_model[1]].unique()):
    #     df_fillrate[train_model[1]] = df_fillrate[train_model[1]].map({'M': 1, 'F': 0})
    if ('M' in df[train_model[1]].unique() or 'F' in df[train_model[1]].unique()):
        df[train_model[1]] = df[train_model[1]].map({'M': 1, 'F': 0})
    
    #df_fillrate[train_model[1]]=df_fillrate[train_model[1]].fillna(0)
    # print("df_",df.shape)
    # splitting the data set into two subdata sets having gender and blank respectively
    df_final_male_female = df[df[train_model[1]] !='']
    df_final_blank_gender = df[df[train_model[1]] =='']
    # print("df_final_male_female_shape",df_final_male_female.shape)
    # print("df_final_blank_gender",df_final_blank_gender)
    return df_final_male_female,df_final_blank_gender
    
    

### Anova test - relationship bw categorical and continuous variable
# Using one way anova test for the univariate analysis
def anova_test(df_final_male_female):
    ##make a dataframe by removing dp_userid column
    
    df_final_male_female[train_model[1]].fillna(0,inplace=True)
    # print("df_final_male_female_zero",df_final_male_female[train_model[1]].isna().sum())
    # print("df_final_male_female",df_final_male_female.shape)
    # print(df_final_male_female.columns.tolist())
    if len(train_model[0])!=0:
        if 'age' in df_final_male_female.columns:
            df_final_male_female_anova = df_final_male_female.drop(columns=['age','dp_userid'])
    else:
        df_final_male_female_anova = df_final_male_female.drop(columns=['dp_userid'])
    # print("df_final_male_female",df_final_male_female_anova.shape)
    # Set the dependent variable column name
    dependent_variable = train_model[1]
    
    # Get a list of the independent variable column names
    independent_variables = df_final_male_female_anova.columns[df_final_male_female_anova.columns != dependent_variable]
    
    columns_to_take=[]
    # Perform ANOVA on each independent variable and the dependent variable
    df_final_male_female_anova=df_final_male_female_anova.replace(np.nan,0)
    for col in independent_variables:
        
        f, p = f_oneway(df_final_male_female_anova[col][df_final_male_female_anova[dependent_variable] == 0], df_final_male_female_anova[col][df_final_male_female_anova[dependent_variable] == 1])
        if p<0.3:
            #print(f'Independent variable: {col},F-statistic: {f:.2f},p-value: {p:.2f}')
            columns_to_take.append(col)
    # print('columns_to_take',columns_to_take)
    return df_final_male_female_anova,columns_to_take


# Apply random forest for feature importance
def random_forest(columns_to_take,df_final_male_female_anova,df_final_male_female):
    new_df=df_final_male_female_anova[columns_to_take]
    # Split the data into features and target
    X = new_df
    y = df_final_male_female[train_model[1]]
    # Initialize a Random Forest classifier with 100 trees
    rf = RandomForestClassifier(n_estimators=90)
    
    # Fit the model on your training data
    rf.fit(X, y)

    # Get feature importances
    feature_importances = pd.DataFrame(rf.feature_importances_,index = X.columns,columns=['importance']).sort_values('importance', ascending=False)
    df2=pd.DataFrame(feature_importances)
    df2['importance']=df2['importance'].astype(float)
    #df2['importance']=df2['importance'].apply(lambda x:'{:.2f}%'.format(x*100))
    index_list=df2[df2['importance']>0.01].index.tolist()
    return index_list

 
    
### Training xgboost model    
def xgboost_code(index_list_ml,df_final_male_female):
    df_gender_var_list=pd.DataFrame(index_list_ml,columns=['gender_var'])
    
    list=index_list_ml+['dp_userid']
    
    if train_model[1] == 'gender' or train_model[1] == 'sex':
        min_size_df = df_final_male_female[train_model[1]].value_counts().to_frame().reset_index()
        min_size_df.columns=[train_model[1],'count']

    min_size = min(min_size_df['count'])
    if min_size < 30:
        print("Insufficient data to train model")
        sys.exit()
    
    
    ### code for creating balanced dataset
    df_final_male_female = (df_final_male_female.groupby(train_model[1], as_index=False)
        .apply(lambda x: x.sample(n=min_size))
        .reset_index(drop=True))

    xgboost_df=df_final_male_female[list]
    X_gender = xgboost_df
    y_gender = df_final_male_female[['dp_userid',train_model[1]]]
    
    X_train_gender, X_test_gender, y_train_gender, y_test_gender = train_test_split(X_gender, y_gender, test_size=0.3, random_state=42)
    X_train_gender_for=X_train_gender.drop(columns=['dp_userid'],axis=1)
    X_test_gender_for= X_test_gender.drop(columns=['dp_userid'],axis=1)
    y_train_gender_for=y_train_gender.drop(columns=['dp_userid'],axis=1)
    y_test_gender_for=y_test_gender.drop(columns=['dp_userid'],axis=1)
    
    # Taking out the user_id_seperate 
    X_train_gender_user=X_train_gender['dp_userid']
    X_test_gender_user=X_test_gender['dp_userid']
    y_train_gender_user=y_train_gender['dp_userid']
    y_test_gender_user=y_test_gender['dp_userid']
    
    
    # Define the XGBoost model
    xgb_model = XGBClassifier()
    
    # Define the hyperparameters to tune
    param_grid = {
        'learning_rate': [.1],
        'max_depth': [4],
        'n_estimators': [25],
        'subsample': [.5],
        'colsample_bytree': [0.05],
        'reg_alpha': [1],
        'reg_lambda': [1],
        'min_child_weight': [2],
        'gamma':[0]
    }
    
    # Use grid search with cross-validation to find the best hyperparameters
    grid_search = GridSearchCV(estimator=xgb_model, param_grid=param_grid, cv=5, n_jobs=10, scoring='accuracy')

    grid_search.fit(X_train_gender_for, y_train_gender_for)
    
    # Select the best hyperparameters
    best_params = grid_search.best_params_
    
    # Retrain the model using the best hyperparameters
    xgb_model = XGBClassifier(**best_params)
    xgb_model.fit(X_train_gender_for, y_train_gender_for)
    
    # Evaluate the performance of the model on the testing set
    accuracy_train_xgb = xgb_model.score(X_train_gender_for, y_train_gender_for)
    accuracy_test_xgb = xgb_model.score(X_test_gender_for, y_test_gender_for)

    ##Test_dataset confusion matrix and other metrices
    predicted_test = xgb_model.predict(X_test_gender_for)
    cm_gender_test = confusion_matrix(y_test_gender_for[train_model[1]].values, predicted_test)
    df_test = pd.DataFrame(cm_gender_test, index=['Actual F', 'Actual M'], columns=['Predicted F', 'Predicted M'])
 
    Accuracy_Score = accuracy_score(y_test_gender_for.values, predicted_test)
    f1score=f1_score(y_test_gender_for.values, predicted_test)
    Precision_Score=metrics.precision_score(y_test_gender_for.values, predicted_test)
    Recall_Score=metrics.recall_score(y_test_gender_for.values, predicted_test)
    df_scores_test = pd.DataFrame({
         'Metric': ['Accuracy','Precision', 'Recall', 'F1 Score'],
         'Score': [Accuracy_Score,Precision_Score, Recall_Score, f1score]})
    df_cm_score_test = pd.concat([ df_scores_test,df_test], axis=1)

     ##Train dataset confusion matrix and other metrices
    predicted_train = xgb_model.predict(X_train_gender_for)   
    cm_gender_train = confusion_matrix(y_train_gender_for[train_model[1]].values, predicted_train)
    df_train = pd.DataFrame(cm_gender_train, index=['Actual F', 'Actual M'], columns=['Predicted F', 'Predicted M'])
    #print(df_train)
    Accuracy_Score = accuracy_score(y_train_gender_for.values, predicted_train)
    f1score=f1_score(y_train_gender_for.values, predicted_train)
    Precision_Score=metrics.precision_score(y_train_gender_for.values, predicted_train)
    Recall_Score=metrics.recall_score(y_train_gender_for.values, predicted_train)
    df_scores_train = pd.DataFrame({
         'Metric': ['Accuracy','Precision', 'Recall', 'F1 Score'],
         'Score': [Accuracy_Score,Precision_Score, Recall_Score, f1score]})
    df_cm_score_train = pd.concat([ df_scores_train,df_train], axis=1)

    return xgb_model,X_test_gender_for,y_test_gender_for,X_train_gender_for,y_train_gender_for,X_gender,y_gender,df_cm_score_test,df_cm_score_train
    
# all collective functions of gender model 
def gender_model(df_modelbase,df_car_sociodemo):
    df_final_without=merge_for_final(df_modelbase,df_car_sociodemo)
    df_final_male_female,df_final_blank_gender=fill_rate_and_drop(df_final_without)
    df_final_male_female_anova,columns_to_take=anova_test(df_final_male_female)
    index_list=random_forest(columns_to_take,df_final_male_female_anova,df_final_male_female)
    xgb_model,X_test_gender_for,y_test_gender_for,X_train_gender_for,y_train_gender_for,X_gender,y_gender,df_cm_score_test,df_cm_scores_train=xgboost_code(index_list,df_final_male_female)
    # BUCKET_NAME = 'amap-dm-product-dev-s3-data'
    train_filename = 'dfscoretrain'
    test_filename = 'dfcmscoretest'
    model = train_model[1]
    model_image = xgb_model

    # loading data to hive
    load_to_hive(index_list, model)
    
    return train_filename,test_filename,model,df_cm_score_test,df_cm_scores_train,model_image


 # all collective functions of age model        
def age_model(df_modelbase, df_car_sociodemo):
    df_final_age = merge_sql_and_hive_data(df_car_sociodemo,df_modelbase)
    df_final_age_fillrate = fill_rate(df_final_age)
    df_final_age_available = split_avail_unavail_data_for_age(df_final_age_fillrate)
    good_col,df_final_age_anova = anova_test_age(df_final_age_available)
    top_feature_list = Random_forest_classifier(df_final_age_anova,good_col)
    age_xg_model,X_train_age,y_train_age,X_test_age,y_test_age,df_cm_score_test,df_cm_scores_train= XGB_classifier(top_feature_list,df_final_age_available)
    
    train_filename = 'age_cm_metrices_combined_train'
    test_filename = 'age_cm_metrices_combined_test'
    model = train_model[0]
    model_image = age_xg_model
    
    # loading the features to hive 
    load_to_hive(top_feature_list, model)
    
    return train_filename,test_filename,model,df_cm_score_test,df_cm_scores_train,model_image
    


def function_model_train(train_model, BUCKET_NAME):
    if len(train_model)<1:
        print("Please select at least one model.")
        return 0
        
    try:
        # getting the data 
        df_modelbase = get_car_data()
        df_car_sociodemo=get_sociodemo_data()
            
            
        for i in train_model:
            if i == 'gender' or i == 'sex':
                train_filename,test_filename,model,df_cm_score_test,df_cm_scores_train,model_image = gender_model(df_modelbase,df_car_sociodemo)
            elif i == 'age':
                train_filename,test_filename,model,df_cm_score_test,df_cm_scores_train,model_image = age_model(df_modelbase,df_car_sociodemo)  
            else:
                continue
    
            #saving the files in s3     
            write_data_to_csv(df_cm_scores_train, train_filename ,BUCKET_NAME, model)
            write_data_to_csv(df_cm_score_test, test_filename ,BUCKET_NAME, model)
            save_model(model_image, model, BUCKET_NAME)
            print(i+' model saved to s3')
            
        return 0
        
    except Exception as e:
        print(e)
        traceback.print_tb(e.__traceback__)
    else:
        print("Either no data available")




def main(step):
       
    try:
        if step == 'training':
            function_model_train(train_model, BUCKET_NAME)
        else:
            function_model_execute(execute_model,BUCKET_NAME)
                
    except Exception as e:
        print(e)
        traceback.print_tb(e.__traceback__)



    
__name__ = "__main__"
if __name__ == "__main__":
    
    '''
    For age_model, have created 3 age_groups --> '-30' : 0,'31-70' : 1,'71+' : 2
    
    For gender/sex model ,mapping --> 'M': 1, 'F': 0
    If otherwise please check with the business team for mapping of 1 & 0 in the same the column.
    
    train_model can be 'age','gender'
    to train both model use 
    train_model = ['age','gender']
    
    to train age only pass 'age'
    train_model = ['age','']
    
    to train gender only pass 'gender'
    train_model = ['','gender']
    '''
    '''
    mysql_db.set(
        "amap-dm-product-dev-rds.cvm6b2mayn6u.eu-west-1.rds.amazonaws.com",
        "data_activation",
        int("3306"),
        "",
        "")
    
    train_model= eval('["age","gender"]')
    execute_model= eval('["age","gender"]')
    age_bucket = eval('["16-25","26-35","36-45","46-55","56-65","66-100"]')
    BUCKET_NAME= "amap-dm-product-dev-s3-data"
    # for training set step to training or execution anything other than training
    step = "trining"
    partition_date= 20230522  # Always last value"""""
    '''
    
    mysql_db.set(
        sys.argv[8],
        sys.argv[5],
        int(sys.argv[11]),
        sys.argv[9],
        sys.argv[10])
        
    train_model = eval(sys.argv[2])
    execute_model = eval(sys.argv[3])
    age_bucket = eval(sys.argv[4])
    BUCKET_NAME = sys.argv[1]
    step = sys.argv[6]
    partition_date = int(sys.argv[7])  # Always last value"""""

    step = sys.argv[12]
    
    
    spark_session = SparkSession.builder \
        .config("hive.exec.dynamic.partition.mode", "nonstrict") \
        .enableHiveSupport() \
        .getOrCreate()
    spark_session.sql(f"USE default")
    hive_connection = create_hive_connection()
    mysql_connection = create_mysql_connection()
    spark_context = SparkContext.getOrCreate()
    spark_context.setLogLevel("INFO")
    lookalike_output = main(step)