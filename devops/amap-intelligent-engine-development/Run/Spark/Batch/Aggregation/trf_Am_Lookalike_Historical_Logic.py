# GENERAL Imports
from pyspark.context import SparkContext
import pandas as pd
import pymysql
import datetime as DT
import numpy as np
from datetime import date
import pyspark.sql.functions as F
from pyspark.sql import DataFrame
from pyspark.sql.types import *

from py4j.protocol import Py4JJavaError
from io import StringIO 
import pyspark
from pyspark.sql import SparkSession
from pyspark.sql.functions import col,lit

import traceback
import gc 
from scipy.stats import f_oneway

import os
import sys
import re
import json
from sys import argv
from datetime import datetime

from py4j.protocol import Py4JJavaError
from io import StringIO 
import boto3
import pickle

# Custom Import
sys.path.append('/tmp/Libraries')
from ie_hive_connection import IEHiveConnection

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
def create_hive_connection(database: str = 'default'):
    try:
        connection = IEHiveConnection(database=database)
        print("Establishing Hive connection")
    except ConnectionError as e:
        print(f"The error '{e}' occurred")
        raise ConnectionError("Hive Connection Failed.")
    return connection
    
# getting site user data contains start date on latest purchase date. 
def get_siteUserdata():
    top_nav_date = "SELECT max(to_date(start_date)) as nav_date from {} where partition_date = {}".format(siteuser_table,partition_date)
    top_nav_date = pd.read_sql(top_nav_date,hive_connection)
    top_nav_date = top_nav_date['nav_date'][0]
    top_nav_date = "'"+top_nav_date+"'"
    
    query = "SELECT distinct dp_userid,start_date,partition_date from {} where partition_date = {} and to_date(start_date) = {}".format(siteuser_table,partition_date,top_nav_date)
 
    df_siteUserData = pd.read_sql(query,hive_connection)
    df_siteUserData = pd.DataFrame(df_siteUserData)
    return df_siteUserData


# getting purchase data 
def get_purchaseData():
    top_purchase_date = "SELECT max(to_date(purchase_date)) as purchase_date from {} where partition_date = {}".format(purchase_table,partition_date)
    top_purchase_date = pd.read_sql(top_purchase_date,hive_connection)
    top_purchase_date = top_purchase_date['purchase_date'][0]
    top_purchase_date = "'"+top_purchase_date+"'"

    query = "SELECT distinct dp_userid,purchase_date,partition_date from {} where partition_date = {} and cast(to_date(purchase_date) as date) = {}".format(purchase_table,partition_date,top_purchase_date)

    df_UserPurchaseData = pd.read_sql(query,hive_connection)
    df_UserPurchaseData = pd.DataFrame(df_UserPurchaseData)
    return df_UserPurchaseData


## making distinct user list of siteuser and purchase table users, and putting purchase_flag and site_user_flag 
def siteUser_purchase_flag(df_siteUserData,df_UserPurchaseData):
    totaluser = []
    for i in df_siteUserData['dp_userid']:
        totaluser.append(i)
        
    for j in df_UserPurchaseData['dp_userid']:
        totaluser.append(j)

    totaluser = set(totaluser)
    
    # getting all unique users from purchase table and siteuser table and also applying the purchase_flag and siteuser_flag
    df_totaluser = pd.DataFrame(list(totaluser))
    df_totaluser.columns = ['dp_userid']
    df_totaluser['purchase_flag'] = 0
    df_totaluser['siteuser_flag'] = 0

    for i in df_totaluser['dp_userid']:
        for j in range(len(df_UserPurchaseData['dp_userid'])):
            if i == df_UserPurchaseData['dp_userid'][j]:
                if df_UserPurchaseData['partition_date'][j] != '':
                    df_totaluser['purchase_flag'] = 1
                    break

    for i in df_totaluser['dp_userid']:
        for j in range(len(df_siteUserData['dp_userid'])):
            if i == df_siteUserData['dp_userid'][j]:
                if df_siteUserData['start_date'][j] != '':
                    df_totaluser['siteuser_flag'] = 1
                    break
                
    return df_totaluser,totaluser
    

# getting the dp_useranagraphic data where attribute_name in ('age','gender') and partition date is the most recent. 
def age_gender_useranagraphic(totaluser):
    totaluser = tuple(totaluser)
    query = "SELECT DISTINCT dp_userid,lower(attribute_name) as attribute_name ,attribute_value,partition_date from {} where lower(attribute_name) in {} and dp_userid in {} and (dp_userid is not null or dp_userid != '""') and partition_date = {}".format(useranagraphic_table,columnNames,totaluser,partition_date)
    df_useranagraphic = pd.read_sql(query,hive_connection)
    df_useranagraphic = pd.DataFrame(df_useranagraphic)
    return df_useranagraphic


# age_flag and gender_flag
#going to make 2 new columns in df_totaluser for age_flag  and gender_flag
#age_flag	    ---> flag to check if age value is available for this user	
#gender_flag	---> flag to check if gender value is available for this user

def handeling_none(df,col):
    #df['attribute_value'].replace('None','',regex = True,inplace = True)
    df[col].fillna(value=np.nan, inplace=True)
    df[col].replace(np.nan,'',regex = True,inplace = True)
    return df

def age_gender_flag(df_useranagraphic,df_totaluser):
    df_totaluser['age_flag'] = 0
    df_totaluser['gender_flag'] = 0
    df_useranagraphic = handeling_none(df_useranagraphic,'attribute_value')
    for i in range(len(df_useranagraphic['dp_userid'])):
        for j in range(len(df_totaluser['dp_userid'])):
            if df_useranagraphic['dp_userid'][i] ==   df_totaluser['dp_userid'][j]:
              
                if df_useranagraphic['attribute_name'][i] == columnNames[0] and df_useranagraphic['attribute_value'][i] != '':
                    df_totaluser['age_flag'][j] = 1
                    break
                if df_useranagraphic['attribute_name'][i] == columnNames[1] and df_useranagraphic['attribute_value'][i] != '':
                    df_totaluser['gender_flag'][j] = 1
                    break


# now we will get the all data 'olduseranagraphic' containing only df_totaluser users except latest partition date. 
# df_olduseranagraphic  have the details of age or gender or both in history --> will use for hist_enrich flag
def get_olduseranagqraphic(totaluser):
    totaluser = tuple(totaluser)
    if top_partition_dates == 0:
        return 0
    top_latest_dates = "SELECT DISTINCT partition_date as p_date from {} order by p_date DESC limit {}".format(useranagraphic_table,top_partition_dates+1)
    tld = pd.read_sql(top_latest_dates,hive_connection)
    partition_dates = list(tld['p_date'][1:])
    partition_dates = tuple(partition_dates)

    query = "select dp_userid,lower(attribute_name) as attribute_name,attribute_value, max(partition_date) as max_partition_date  from {} where dp_userid in {} and (dp_userid is not null or dp_userid != '""') and lower(attribute_name) in {} and attribute_value != '' and partition_date in {} group by dp_userid,attribute_name,attribute_value".format(useranagraphic_table,totaluser,columnNames,partition_dates)
    df_olduseranagraphic = pd.read_sql(query,hive_connection)
    df_olduseranagraphic = pd.DataFrame(df_olduseranagraphic)
    return df_olduseranagraphic
    
    
#hist_enrich	    --> flag to check if user(from df_totaluser) has info in historical partition_date			
#age_enrich	        --> flag to check if age value is populated using hisory		    
#enrich_age_val     -->	Value for age value		                                        
#gender_enrich	    --> flag to check if gender value is populated using hisory		    
#enrich_gender_val	--> Value for gender value		                                    

def utility_flags(df_totaluser,df_olduseranagraphic):
    
    df_totaluser['hist_enrich'] = 0
    df_totaluser['age_enrich'] = 0
    df_totaluser['enrich_age_val'] = 0
    df_totaluser['gender_enrich'] = 0
    df_totaluser['enrich_gender_val'] = 0
    
    if top_partition_dates != 0:
        df_olduseranagraphic = handeling_none(df_olduseranagraphic,'attribute_value')
        for i in range(len(df_olduseranagraphic['dp_userid'])):
            for j in range(len(df_totaluser['dp_userid'])):
                # checking if user from df_totaluser has value 0 for age_flag or gender_flag, then that user will be checked on previuos partition dates.  
                if (df_totaluser['age_flag'][j] == 0 or df_totaluser['gender_flag'][j] == 0) and df_olduseranagraphic['dp_userid'][i] == df_totaluser['dp_userid'][j]:
                    if df_olduseranagraphic['attribute_name'][i] == columnNames[0] and df_olduseranagraphic['attribute_value'][i] != '':
                        df_totaluser['hist_enrich'][j] = 1
                        df_totaluser['age_enrich'][j] = 1
                        df_totaluser['enrich_age_val'][j] = df_olduseranagraphic['attribute_value'][i]
                    elif df_olduseranagraphic['attribute_name'][i] == columnNames[1]  and df_olduseranagraphic['attribute_value'][i] != '':
                        df_totaluser['hist_enrich'][j] = 1
                        df_totaluser['gender_enrich'][j] = 1
                        df_totaluser['enrich_gender_val'][j] = df_olduseranagraphic['attribute_value'][i]
                    break

# <--- load to hive---->
def load_to_hive(df, database: str = 'default') -> None:
    if df.head(1):
        conn = IEHiveConnection(database=database)
    
    
    ### Adding partition column
        df = df.withColumn("partition_date", lit(partition_date))
        
        query = "SELECT count(*) FROM TRF_Am_Lookalike_Historical_Logic WHERE partition_date ={}".format(partition_date)
        record_check = pd.read_sql(query,hive_connection)
        record_df = pd.DataFrame(record_check)
        print(record_df)
        
        cursor = conn.cursor()
        if record_df.empty:
            spark_session.sql("DROP TABLE IF EXISTS TRF_Am_Lookalike_Historical_Logic_temp")
        else:
            if record_check['_c0'][0] > 1:
                cursor.execute("DELETE FROM TRF_Am_Lookalike_Historical_Logic WHERE partition_date ={}".format(partition_date))
                spark_session.sql("DROP TABLE IF EXISTS TRF_Am_Lookalike_Historical_Logic_temp")
        
        
        df.write.mode('overwrite').saveAsTable("TRF_Am_Lookalike_Historical_Logic_temp")    
        cursor.execute("INSERT INTO TABLE TRF_Am_Lookalike_Historical_Logic SELECT * FROM TRF_Am_Lookalike_Historical_Logic_temp")
        print("The data is inserted in TRF_Am_Lookalike_Historical_Logic")
        spark_session.sql("DROP TABLE IF EXISTS TRF_Am_Lookalike_Historical_Logic_temp")
        conn.close()
    else:
        print("DM3Info Table TRF_Am_Lookalike_Historical_Logic_temp could not be created, dataframe is empty")


def main():
    try:
        df_siteUserData = get_siteUserdata()
        df_UserPurchaseData = get_purchaseData()
        df_totaluser,totaluser = siteUser_purchase_flag(df_siteUserData,df_UserPurchaseData)
        df_useranagraphic = age_gender_useranagraphic(totaluser)
        age_gender_flag(df_useranagraphic,df_totaluser)
        df_olduseranagraphic = get_olduseranagqraphic(totaluser)
        utility_flags(df_totaluser,df_olduseranagraphic)
        df_totaluser["enrich_gender_val"]=df_totaluser["enrich_gender_val"].values.astype('str')
        df_totaluser["enrich_age_val"]=df_totaluser["enrich_age_val"].values.astype('str')
        hist_enrich_output_sparkDF = spark_session.createDataFrame(df_totaluser)
        load_to_hive(hist_enrich_output_sparkDF)
        return df_totaluser
        
    except Exception as e:
        print(e)
        traceback.print_tb(e.__traceback__)
    else:
        print("Either no data available")

    
if __name__ == "__main__":
    useranagraphic_table = 'stg_dp_useranagraphic'
    purchase_table = 'stg_dp_purchase_userdata'
    siteuser_table = 'TRF_DP_Siteuserdata'
    columnNames = ('date of birth','gender') 
    top_partition_dates = 0
    #partition_date = 20230509
    
    partition_date = int(sys.argv[1])

    spark_session = SparkSession.builder \
        .config("hive.exec.dynamic.partition.mode", "nonstrict") \
        .enableHiveSupport() \
        .getOrCreate()
    spark_session.sql(f"use default")
    
    hive_connection = create_hive_connection()
    spark_context = SparkContext.getOrCreate()
    spark_context.setLogLevel("INFO")
    user_anagraphic_history = main()
  