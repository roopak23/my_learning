# GENERAL Imports
import os
import sys
import re
import json
from sys import argv
import datetime
from datetime import datetime, timedelta
import time

import pandas as pd
import numpy as np
import signal
from scipy import stats

# Spark Imports
import pymysql
from pyspark.sql import SparkSession
from pyspark.context import SparkContext
import traceback

# Spark Imports
from pyspark.sql.functions import when
import pyspark.sql.functions as F
from pyspark.sql.types import FloatType
from pyspark.sql.types import *
import pyspark.sql.functions as sf
from pyspark.sql import DataFrame
import boto3
import io
from io import StringIO
from py4j.protocol import Py4JJavaError

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
        # connection = hive.Connection(
        #         #     host=hive_db.host,
        #         #     port=hive_db.port,
        #         #     username=hive_db.username,
        #         #     configuration=hive_db.configuration)
        connection = IEHiveConnection(database=database)
        print("Establishing Hive connection")
    except ConnectionError as e:
        print(f"The error '{e}' occurred")
        raise ConnectionError("Hive Connection Failed.")
    return connection


#Function to write to s3 bucket using spark dataframe
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
        
     
        
#Function to write to s3 bucket using pandas dataframe      
def write_data_to_csv_on_s3(dp_car_user_behaviour, BUCKET_NAME, path): 
    """ Write pandas dataframe to a CSV on S3 """ 
    try: 
        
        # filepath = f"s3://{bucket}/{path}"
        csv_buffer = StringIO() 
        dp_car_user_behaviour.to_csv(csv_buffer, sep=",", index=False) 
        s3_resource = boto3.resource("s3") 
        print("Writing {} records to {}".format(len(dp_car_user_behaviour), path)) 
        s3_resource.Object(BUCKET_NAME, path).put(Body=csv_buffer.getvalue())
        print("File writtern to s3 bucket")
    except: 
        logger.error("ERROR: Unexpected error: Could not load the file to S3 Bucket.") 
        sys.exit()


#Function to write table to hive
def load_to_hive(df, database: str = 'default') -> None:
    if df.head(1):
        conn = IEHiveConnection(database=database)
        
        cursor = conn.cursor()
        cursor.execute("INSERT INTO TABLE DP_Car_User_Behaviour SELECT * FROM ds_car_userbehvaiour_temp")
        print("The data is inserted in DP_Car_User_Behaviour")
        spark_session.sql("DROP TABLE IF EXISTS ds_car_userbehvaiour_temp")
        conn.close()
    else:
        print("[DM3][ERROR] The DF has not elements, please check the validation rules")
		
		
#Function to convert the datatypes from pandas df to sparkR df
def convert_df_dtypes(df):
    """
    This function takes a pandas DataFrame as input and returns a list of column names and their corresponding data types.

    Parameters:
    df (pandas.DataFrame): A pandas DataFrame.

    Returns:
    list: A list of strings containing the column names and their corresponding data types.
    """
    # Create a DataFrame with the column names
    col_names_df = pd.DataFrame({'Column_Names': df.columns.to_list()})

    # Create a DataFrame with the data types
    dtypes_df = pd.DataFrame({'Data_Types': df.dtypes.tolist()})
    # Replace multiple values at once using a dictionary
    dtypes_df['Data_Types'] = dtypes_df['Data_Types'].replace({'object': 'string', 'int64': 'int', 'float64': 'float', 'datetime64[ns]': 'date'})
    # Concatenate the two DataFrames along the columns axis
    final_df = pd.concat([col_names_df, dtypes_df], axis=1)
    # Combine the column names and data types into a new column
    new_col = final_df['Column_Names'] + " " + final_df['Data_Types'].astype('str')
    # Convert the new coluTRF_DPmn to a list
    new_col_list = new_col.tolist()
    # Iterate over the list and convert each element to a string
    new_col_list = [str(elem) for elem in new_col_list]


    # the resulting list without the square brackets and strings
    new_col_str= ', '.join(new_col_list)
    new_col_str = new_col_str.strip('[]\'')
    new_col_str = new_col_str.replace('\'', '')
    return new_col_str
    
##############################extra added #############################################################
def rename_and_remove_underscore(df):
        # Replace multiple words in column names
        
        df.rename(columns=lambda x: x.replace("buying_frequency", "buy"),inplace=True)
        df.rename(columns=lambda x: x.replace("frequency", "freq")
                       .replace("buying", "buy").replace("duration","dur").replace("daily", "d").replace("weekly", "w").replace("monthly","m"), inplace=True)
               

        # Remove column names with four or more underscores
        
        columns_to_keep = [col for col in df.columns if col.count('_') < 4]
        
        df = df[columns_to_keep]
        return df
    


####################################### purchase code ######################################

#### Get product data
def get_product_data(partition_date):
    query = "SELECT * FROM {} WHERE (partition_date={})".format(stg_dp_product_attribute, partition_date)
    df_product = pd.read_sql(query,hive_connection)
    df_product = pd.DataFrame(df_product) 
    df_product = df_product.drop_duplicates()
    cols_remap = {key: key.split(".")[1] for key in df_product.columns}
    df_product.rename(columns=cols_remap, inplace=True)
    return df_product
    
#df_product = get_product_data(partition_date)


#### Get purchase data
def get_purchase_user_data(partition_date):
    query = "SELECT * FROM {} WHERE (partition_date={}) and purchase_date is not null".format(stg_dp_purchase_userdata, partition_date)
    df_purchase_data = pd.read_sql(query,hive_connection)
    df_purchase_data = pd.DataFrame(df_purchase_data) 
    cols_remap = {key: key.split(".")[1] for key in df_purchase_data.columns}
    df_purchase_data.rename(columns=cols_remap, inplace=True)
    return df_purchase_data
    

# get all product ids
def get_product_ids():
    query =  "SELECT * FROM {} where partition_date = {}".format(stg_dp_product_attribute, partition_date)
    df_product = pd.read_sql(query,hive_connection)
    df_product = pd.DataFrame(df_product) 
    df_product = df_product.drop_duplicates()
    df_product = pd.DataFrame(df_product)
    cols_remap = {key: key.split(".")[1] for key in df_product.columns}
    df_product.rename(columns=cols_remap, inplace=True)
    return df_product['product_id'].unique().tolist()



# adding a dummy purchase user with all possible product_id ---> all possible categories and sub_categories in order to get all columns that we want
def add_dummy_purchase_user(df_purchase,partition_date):
    products = get_product_ids()
    # creating an empty df
    df_columns = ['sys_datasource', 'sys_load_id', 'sys_created_on', 'dp_userid', 'purchase_date', 'purchase_channel', 'purchase_amount', 'purchase_discount', 'purchase_channel_name', 'purchase_channel_location', 'purchase_channel_url', 'product_id', 'partition_date']
    df_catsub = pd.DataFrame(columns=df_columns)
    
    # setting the correct start and end date
    if len(df_purchase) >1:
        if df_purchase['purchase_date'].max() == df_purchase['purchase_date'].max():
            date_p = df_purchase['purchase_date'].max()
        else:
            date_p = datetime.strptime(str(partition_date), '%Y%m%d') - timedelta(days=1) + timedelta(seconds=1)
    else:
        date_p = datetime.strptime(str(partition_date), '%Y%m%d') - timedelta(days=1) + timedelta(seconds=1)

    channel = ['Store','Online']
    # adding new user
    k = 0
    for prod in products:
        new_row = pd.Series({
                                'sys_datasource': None,
                                'sys_load_id': None,
                                'sys_created_on': None,
                                'dp_userid' : 'user_dummy', 
                                'purchase_date' : date_p, 
                                'purchase_channel' : channel[k], 
                                'purchase_amount' : 0., 
                                'purchase_discount': 0.1,
                                'purchase_channel_name': None, 
                                'purchase_channel_location': None,
                                'purchase_channel_url': None,
                                'product_id': prod,
                                'partition_date': int(partition_date)
                            })
        
        df_catsub = pd.concat([df_catsub, new_row.to_frame().T], ignore_index=True)
        
        k = k + 1
        if k == 2:
            k = 0
    
    # print(df_catsub)
    df_purchase = pd.concat([df_purchase, df_catsub], ignore_index=True)

    return df_purchase
    


############# filtering users who did transaction on last day ( for now maxdate) in purchase data. maxdate will be replaced with last day (current day - 1)
def get_last_day_users(partition_date, df_purchase_data):

    df_purchase_data['purchase_datemapping'] = df_purchase_data['purchase_date'].astype(str)
    df_purchase_data["purchase_datemapping"] = df_purchase_data["purchase_datemapping"].astype(str).str.split(" ").str[0]
    max_trans_date_user=df_purchase_data.groupby(['dp_userid'])['purchase_datemapping'].max()
    max_trans_date_user=max_trans_date_user.reset_index()

    ### maxdate will be replaced with last day (current day - 1)
    maxdate_date = df_purchase_data["purchase_datemapping"].max()
    max_trans_date_user['CARlastday_users'] = np.where(max_trans_date_user['purchase_datemapping']==maxdate_date,1,0)
    max_trans_date_user = max_trans_date_user.loc[max_trans_date_user['CARlastday_users'] == 1]
    max_trans_date_user = max_trans_date_user[['dp_userid','CARlastday_users']]
    df_purchase_data = pd.merge(df_purchase_data,max_trans_date_user,how='left',on=['dp_userid'])
    df_purchase_data = df_purchase_data.loc[df_purchase_data['CARlastday_users'] == 1]
    df_purchase_data = df_purchase_data.drop(['purchase_datemapping','CARlastday_users'], axis=1)
    return df_purchase_data, max_trans_date_user



# splitting the records for product_id(prod_00010, prod_00011) into 2.
### Preprocessing of purchase data
def prep_purchase_data(df_purchase_data):
    #split prod column
    df_purchase_data["key"]=df_purchase_data["sys_created_on"].astype(str)+"___"+df_purchase_data["dp_userid"].astype(str)+"___"+df_purchase_data["purchase_date"].astype(str)+"___"+df_purchase_data["purchase_channel"].astype(str)+"___"+df_purchase_data["purchase_amount"].astype(str)+"___"+df_purchase_data["purchase_discount"].astype(str)+"___"+df_purchase_data["purchase_channel_name"].astype(str)+"___"+df_purchase_data["purchase_channel_location"].astype(str)+"___"+df_purchase_data["partition_date"].astype(str)
    df_purchase_data1=df_purchase_data[["key","product_id"]]
    prod_split = df_purchase_data1['product_id'].str.split(',',expand=True)
    
    #prod_split
    df2 = pd.concat([df_purchase_data1,prod_split], axis=1)
    df2=df2.drop(['product_id'], axis=1)
   
    df3=df2.set_index('key').stack().droplevel(1).reset_index(name='product_id')
    
    ## key , prod_split in df3
    #splitting the mapping columns from Key in Purchase data
    
    df3["sys_created_on"]=df3["key"].astype(str).str.split("___").str[0]
    df3["dp_userid"]=df3["key"].astype(str).str.split("___").str[1]
    df3["purchase_date"]=df3["key"].astype(str).str.split("___").str[2]
    df3["purchase_channel"]=df3["key"].astype(str).str.split("___").str[3]
    df3["purchase_amount"]=df3["key"].astype(str).str.split("___").str[4]
    df3["purchase_discount"]=df3["key"].astype(str).str.split("___").str[5]
    df3["purchase_channel_name"]=df3["key"].astype(str).str.split("___").str[6]
    df3["purchase_channel_location"]=df3["key"].astype(str).str.split("___").str[7]
    df3["partition_date"]=df3["key"].astype(str).str.split("___").str[8]

    
    #####final purchase dataframe
    df3 = df3.drop('key', axis=1)

    df3['purchase_amount']=df3['purchase_amount'].astype(str).map(lambda x: re.findall(r'\d+', x))
 
    df3['purchase_amount']=df3['purchase_amount'].map(lambda x:float('.'.join(x)))

    df3['purchase_datemapping']=df3['purchase_date'].astype(str)
    df3["purchase_datemapping"]=df3["purchase_datemapping"].astype(str).str.split(" ").str[0]
    
    purchase_data_agg=df3.copy()
    return purchase_data_agg



## Product data processing ### assuming comma and $ issue fixed in data
def transforming_product_data(df_product,purchase_data_agg):
    df_product_02 = df_product.pivot(index="product_id", columns="attribute_name", values="attribute_value")
    df_product_02=df_product_02.reset_index()
    df_product_02['product_price_per_unit']=df_product_02['product_price_per_unit'].astype(str).map(lambda x: re.findall(r'\d+', x))
    df_product_02['product_price_per_unit']=df_product_02['product_price_per_unit'].map(lambda x:float('.'.join(x)))

    ### handling leading spaces in ids
    df_product_02["product_id"]=df_product_02["product_id"].str.strip()
    purchase_data_agg["product_id"]=purchase_data_agg["product_id"].str.strip()
    purchase_data_agg["dp_userid"]=purchase_data_agg["dp_userid"].str.strip()
    return purchase_data_agg,df_product_02
    


### purchase_data_agg merge with product data to get the details of product_price_per_unit value in purchase_data  == > daily purchase of a product details
def merging_purchase_prod_daily(purchase_data_agg, df_product_02):
    df_purchase_prod_daily=pd.merge(purchase_data_agg,df_product_02[['product_id','product_price_per_unit']],how='left',on=['product_id'])
    df_purchase_prod_daily['product_price_per_unit']=df_purchase_prod_daily['product_price_per_unit'].fillna(0)
    return df_purchase_prod_daily


############### Feature Generation start here 

### calculating avg bucket price (avg selling price of a product ) by a user in a day##added
def calculating_avg_purchaseorder_price(df_purchase_prod_daily):
    Avg_purchaseorder_price=df_purchase_prod_daily.groupby(['dp_userid','purchase_datemapping']).product_price_per_unit.mean()
    Avg_purchaseorder_price=Avg_purchaseorder_price.reset_index()
    Avg_purchaseorder_price.rename(columns={'product_price_per_unit':'Avg_Order_price_dt'},inplace=True)
    return Avg_purchaseorder_price


### calculating max and min price of product  by a user in a day
def daily_price_statistics(df_purchase_prod_daily):
    max_purchaseorder_price=df_purchase_prod_daily.groupby(['dp_userid','purchase_datemapping']).product_price_per_unit.max()
    max_purchaseorder_price=max_purchaseorder_price.reset_index()
    max_purchaseorder_price.rename(columns={'product_price_per_unit':'max_price_prod_dt'},inplace=True)
    
    min_purchaseorder_price=df_purchase_prod_daily.groupby(['dp_userid','purchase_datemapping']).product_price_per_unit.min()
    min_purchaseorder_price=min_purchaseorder_price.reset_index()
    
    min_purchaseorder_price.rename(columns={'product_price_per_unit':'min_price_prod_dt'},inplace=True)
    max_min_daily=pd.merge(max_purchaseorder_price,min_purchaseorder_price,how='left',on=['dp_userid','purchase_datemapping'])
    return max_min_daily



############ daily level purchase channel (online/store) countby transactions ####added
def daily_level_purchase_transactions_history(df_purchase_prod_daily):
    df_purchase_online_store=df_purchase_prod_daily[['dp_userid','purchase_date','purchase_datemapping','purchase_channel']]
    df_purchase_online_store=df_purchase_online_store.drop_duplicates()
    df_purchase_online_store["avg_buying_frequency_daily_online"]=np.where(df_purchase_online_store['purchase_channel']=='Online',1,0)
    df_purchase_online_store["avg_buying_frequency_daily_store"]=np.where(df_purchase_online_store['purchase_channel']=='Store',1,0)
    purchase_online_store=df_purchase_online_store.groupby(['dp_userid','purchase_datemapping'])['avg_buying_frequency_daily_online','avg_buying_frequency_daily_store'].sum()
    purchase_online_store=purchase_online_store.reset_index()
    return purchase_online_store



############ daily level purchase category level aggregated sale value###########Purchase product category level budget
def daily_level_purchase_category_aggregated(df_purchase_prod_daily,df_product_02):
    df_purchase_prod_cat=df_purchase_prod_daily[['product_id','dp_userid','purchase_datemapping', 'product_price_per_unit']]
    
    ##########mappinng prod table (adding product_category column in the purchase table)
    df_purchase_prod_cat=pd.merge(df_purchase_prod_cat,df_product_02[['product_id','product_category']],how='left',on=['product_id'])

    df_purchase_prod_cat['product_category'] = 'avg_budget_daily_' + df_purchase_prod_cat['product_category'].astype(str)

    # daily total product sale of a category 
    daily_catgory_amount=df_purchase_prod_cat.groupby(['dp_userid','product_category','purchase_datemapping'])['product_price_per_unit'].sum()
    daily_catgory_amount=daily_catgory_amount.reset_index()
    daily_catgory_amount.rename(columns={'product_price_per_unit':'catgory_dailypricetotal'},inplace=True)
    transposed_daily_catgory_amount = daily_catgory_amount.pivot(index=["dp_userid","purchase_datemapping"], columns="product_category", values="catgory_dailypricetotal")
    # Reset the index
    transposed_daily_catgory_amount = transposed_daily_catgory_amount.reset_index()
    transposed_daily_catgory_amount=transposed_daily_catgory_amount.fillna(0)

    transposed_daily_catgory_amount.columns = transposed_daily_catgory_amount.columns.str.replace(' ', '')
    transposed_daily_catgory_amount.columns = transposed_daily_catgory_amount.columns.str.replace('+', 'plus')
    transposed_daily_catgory_amount.columns = transposed_daily_catgory_amount.columns.str.lower()
    return transposed_daily_catgory_amount
    


############ daily level purchase category level aggregated sale value#############Purchase product category subcategory level budget
def daily_level_purchase_subcategory_aggregated(df_purchase_prod_daily,df_product_02):
    df_purchase_prod_cat=df_purchase_prod_daily[['product_id','dp_userid','purchase_datemapping', 'product_price_per_unit']]
    df_purchase_prod_cat
    
    ##########mappinng prod table
    
    df_purchase_prod_cat_sub=pd.merge(df_purchase_prod_cat,df_product_02[['product_id','product_category','product_subcategory']],how='left',on=['product_id'])
    
    df_purchase_prod_cat_sub.columns = df_purchase_prod_cat_sub.columns.str.replace(' ', '')
    df_purchase_prod_cat_sub.columns = df_purchase_prod_cat_sub.columns.str.replace('+', 'plus')
    df_purchase_prod_cat_sub.columns = df_purchase_prod_cat_sub.columns.str.lower()
    
    
    df_purchase_prod_cat_sub['product_category_subcat']=df_purchase_prod_cat_sub["product_category"].astype(str)+"_"+df_purchase_prod_cat_sub["product_subcategory"].astype(str)
    
    df_purchase_prod_cat_sub['product_category_subcat'] = 'avg_budget_daily_' + df_purchase_prod_cat_sub['product_category_subcat'].astype(str)
 
    
    daily_category_subcategory_amount=df_purchase_prod_cat_sub.groupby(['dp_userid','product_category_subcat','purchase_datemapping'])['product_price_per_unit'].sum()
    daily_category_subcategory_amount=daily_category_subcategory_amount.reset_index()
    daily_category_subcategory_amount.rename(columns={'product_price_per_unit':'product_cat_subcatpricetotal'},inplace=True)
    transposed_daily_category_subcategory_amount = daily_category_subcategory_amount.pivot(index=["dp_userid","purchase_datemapping"], columns="product_category_subcat", values="product_cat_subcatpricetotal")
    # Reset the index
    transposed_daily_category_subcategory_amount = transposed_daily_category_subcategory_amount.reset_index()
    
    transposed_daily_category_subcategory_amount=transposed_daily_category_subcategory_amount.fillna(0)
    
    transposed_daily_category_subcategory_amount.columns = transposed_daily_category_subcategory_amount.columns.str.replace(' ', '')
    transposed_daily_category_subcategory_amount.columns = transposed_daily_category_subcategory_amount.columns.str.replace('+', 'plus')
    transposed_daily_category_subcategory_amount.columns = transposed_daily_category_subcategory_amount.columns.str.lower()
    return transposed_daily_category_subcategory_amount
    



### total price daily by  a user in a day###added
def processing_purchase_daily_data(df_purchase_prod_daily):
    total_daily=df_purchase_prod_daily[["dp_userid","purchase_date","purchase_amount"]]
    
    total_daily['purchase_datemapping']=total_daily['purchase_date'].astype(str)
    total_daily["purchase_datemapping"]=total_daily["purchase_datemapping"].astype(str).str.split(" ").str[0]
    
    total_daily=total_daily.drop_duplicates()
   
    total_daily1=total_daily.groupby(["dp_userid","purchase_datemapping"])["purchase_amount"].sum()
    total_daily1=total_daily1.reset_index()
    total_daily1.rename(columns={'purchase_amount':'total_purchase_amt_daily'},inplace=True)

    return total_daily1
    


### calculating total no of units purchased by a user in a day####added
def calculating_metrics(df_purchase_prod_daily):
    total_prod_pur_daily=df_purchase_prod_daily[["dp_userid","purchase_date","product_price_per_unit"]]
    
    total_prod_pur_daily['purchase_datemapping']=total_prod_pur_daily['purchase_date'].astype(str)
    total_prod_pur_daily["purchase_datemapping"]=total_prod_pur_daily["purchase_datemapping"].astype(str).str.split(" ").str[0]
    
    
    total_prod_pur_daily=total_prod_pur_daily.groupby(['dp_userid','purchase_datemapping']).product_price_per_unit.count()
    total_prod_pur_daily=total_prod_pur_daily.reset_index()
    
    total_prod_pur_daily.rename(columns={'product_price_per_unit':'total_prod_purchased_daily'},inplace=True)
    return total_prod_pur_daily

   
################no of transactions in purchase data by user daily##added

def daily_level_purchasingtransaction_data(df_purchase_prod_daily):
    transacations_daily=df_purchase_prod_daily[['dp_userid','purchase_date','purchase_datemapping']]
    transacations_daily=transacations_daily.drop_duplicates()
    transacations_daily1=transacations_daily.groupby(['dp_userid','purchase_datemapping'])['purchase_date'].count()
    transacations_daily1=transacations_daily1.reset_index()
    
    transacations_daily1.rename(columns={'purchase_date':'transactions_count_daily'},inplace=True)

    return transacations_daily1


#######################purchase data processing
def merging_data(purchase_data_agg,Avg_purchaseorder_price,df_product_02):
    data_01=pd.merge(purchase_data_agg,Avg_purchaseorder_price,how='left',on=['dp_userid','purchase_datemapping'])
    df_product_03=df_product_02[['product_id','product_brand','product_category','product_discount','product_name','product_subcategory','product_price_per_unit']]
    data_01=pd.merge(data_01,df_product_03,how='left',on="product_id")
    data_01=data_01[['dp_userid','purchase_datemapping','product_id', 'purchase_channel','Avg_Order_price_dt','purchase_amount','purchase_discount','purchase_channel_name','purchase_channel_location','partition_date','product_brand','product_category','product_discount','product_name','product_subcategory','product_price_per_unit']]
    data_01["purchase_channel_name"]=data_01["purchase_channel_name"].str.strip()

    return data_01
        

def utility_function(data_01):
    last_trans_part_purchasedate=data_01.groupby(['dp_userid'])['purchase_datemapping','partition_date'].max()
    last_trans_part_purchasedate=last_trans_part_purchasedate.reset_index()
    
    last_trans_part_purchasedate.rename(columns={'purchase_datemapping':'last_transaction_date'},inplace=True)
    last_trans_part_purchasedate
    
    ############ daily level online/st0re level aggregated sale value
    channel_agg=data_01[['dp_userid','purchase_datemapping', 'product_price_per_unit','purchase_channel']]
    channel_agg
    
    ##########mappinng prod table
    
    channel_agg['purchase_channel'] = 'avg_budget_daily_' + channel_agg['purchase_channel'].astype(str)

    channel_agg1=channel_agg.groupby(['dp_userid','purchase_channel','purchase_datemapping'])['product_price_per_unit'].sum()
    channel_agg1=channel_agg1.reset_index()
    channel_agg1.rename(columns={'product_price_per_unit':'purchase_chanel_dailypricetotal'},inplace=True)
    channel_agg2 = channel_agg1.pivot(index=["dp_userid","purchase_datemapping"], columns="purchase_channel", values="purchase_chanel_dailypricetotal")
    # Reset the index
    channel_agg2 = channel_agg2.reset_index()

    channel_agg2=channel_agg2.fillna(0)
    channel_agg2.columns = channel_agg2.columns.str.replace(' ', '')
    channel_agg2.columns = channel_agg2.columns.str.replace('+', 'plus')
    channel_agg2.columns = channel_agg2.columns.str.lower()
    return last_trans_part_purchasedate,channel_agg2



def one_hot_encoding(data_01):
    data_01.columns = data_01.columns.str.replace(' ', '')
    data_01.columns = data_01.columns.str.replace('+', 'plus')
    data_01.columns = data_01.columns.str.lower()
    
    data_01['product_category_subcat']=data_01["product_category"].astype(str)+"_"+data_01["product_subcategory"].astype(str)
    
    ######## tranposing the categorical columns ### ( rightnow issue with numeric price - so filtering)
    #cat_cols = ['product_id','product_category','product_subcategory','product_brand','purchase_channel','purchase_channel_name','purchase_channel_location']
    
    cat_cols = ['product_category','product_category_subcat']
    
    cat_cols_to_drop = [col for col in data_01.columns if col not in cat_cols + ['dp_userid']]
    df_one_hot = pd.get_dummies(data_01.drop(columns=cat_cols_to_drop), columns=cat_cols)
    
    df_one_hot.columns = df_one_hot.columns.str.replace('product_category_subcat','avg_buying_frequency_daily')
    
    df_one_hot.columns = df_one_hot.columns.str.replace('product_category','avg_buying_frequency_daily')
    
    
    #merging tranposed categorical columns with master data
    
    df_one_hot=df_one_hot.drop(['dp_userid'],axis=1)
    
    data_02 = pd.concat([data_01, df_one_hot], axis=1)
    data_02.rename(columns={'purchase_amount':'total_purchase_amount',
                            'purchase_discount':'total_purchase_discount'},inplace=True)
    
    #### drop tranposed categorical columns from CAR data
    
    data_02=data_02.drop(['product_id','product_name','product_category','product_price_per_unit','product_discount','product_subcategory','product_brand','purchase_channel','purchase_channel_name','purchase_channel_name','purchase_channel_location'],axis=1)
   
    
    #############aggregated daily level purchase and product daily data

    data_03=data_02.groupby(['dp_userid', 'purchase_datemapping','avg_order_price_dt']).sum()
    data_03=data_03.reset_index()
    data_03.rename(columns={'purchase_datemapping':'purchase_date'},inplace=True)
    return data_03
    

#################avg buying frequency & cat and subcat already added in data_03

def adding_daily_total_purchase_total_trans_max_min_daily_cat_subcat_timespend(data_03,total_purchase_daily,total_prod_pur_daily,transacations_daily1,purchase_online_store,max_min_purchaseorder_pricedaily,transposed_daily_catgory_amount,transposed_daily_category_subcategory_amount,channel_agg2 ,last_trans_part_purchasedate):
    
    #########1.adding purchase online/store
    ## useful
    purchase_online_store.rename(columns={'purchase_datemapping':'purchase_date'},inplace=True)
    
    
    master_data_daily_level=pd.merge(data_03,purchase_online_store,how='left',on=["dp_userid","purchase_date"])
    #############################################################################################################
    
    
    #####Adding daily purchased amount 
    master_data_daily_level=master_data_daily_level.drop(['total_purchase_amount'],axis=1)
   
    total_purchase_daily.rename(columns={'purchase_datemapping':'purchase_date'},inplace=True)
    CAR_daily=pd.merge(master_data_daily_level,total_purchase_daily,how='left',on=["dp_userid","purchase_date"])
    
    #########adding total purchase product daily
    total_prod_pur_daily.rename(columns={'purchase_datemapping':'purchase_date'},inplace=True)
    CAR_daily1=pd.merge(CAR_daily,total_prod_pur_daily,how='left',on=["dp_userid","purchase_date"])
    
    #########adding total no of transactions daily
    transacations_daily1.rename(columns={'purchase_datemapping':'purchase_date'},inplace=True)
    CAR_daily2=pd.merge(CAR_daily1,transacations_daily1,how='left',on=["dp_userid","purchase_date"])
    
    #########adding purchase max_min_daily
    max_min_purchaseorder_pricedaily.rename(columns={'purchase_datemapping':'purchase_date'},inplace=True)
    CAR_daily3=pd.merge(CAR_daily2,max_min_purchaseorder_pricedaily,how='left',on=["dp_userid","purchase_date"])
    
    ###############################avg budget daily 
    #########1.adding daily channel online/store pricing
    channel_agg2.rename(columns={'purchase_datemapping':'purchase_date'},inplace=True)
    CAR_daily4=pd.merge(CAR_daily3,channel_agg2,how='left',on=["dp_userid","purchase_date"])
    
    
    #########2.adding daily category level pricing
    transposed_daily_catgory_amount.rename(columns={'purchase_datemapping':'purchase_date'},inplace=True)
    CAR_daily5=pd.merge(CAR_daily4,transposed_daily_catgory_amount,how='left',on=["dp_userid","purchase_date"])
    
    #########3.adding daily category subcategory  level pricing
    transposed_daily_category_subcategory_amount.rename(columns={'purchase_datemapping':'purchase_date'},inplace=True)
    CAR_daily5=pd.merge(CAR_daily5,transposed_daily_category_subcategory_amount,how='left',on=["dp_userid","purchase_date"])
    
  
    #########adding last transaction date and partiton date
    CAR_daily5=pd.merge(CAR_daily5,last_trans_part_purchasedate,how='left',on=["dp_userid"])
    
    ### last step for daily table
    CAR_daily5.columns = CAR_daily5.columns.str.replace(' ', '')
    CAR_daily5.columns = CAR_daily5.columns.str.replace('+', 'plus')
    CAR_daily5.columns = CAR_daily5.columns.str.lower()
    
    CAR_daily5 = CAR_daily5.loc[:,~CAR_daily5.columns.duplicated()]
    return CAR_daily5


######################Resampling daily level data for missing data points#############################################
def daily_resampling_for_missingdata(CAR_daily5):

    daily_resample=CAR_daily5[['dp_userid', 'purchase_date', 'avg_order_price_dt']]
    daily_resample['purchase_date'] = pd.to_datetime(daily_resample['purchase_date'], format='%Y-%m-%d')
    maxdate_date=daily_resample['purchase_date'].max()
    
    yesterday = datetime.now() - timedelta(1)
    yesterday=yesterday.strftime("%Y-%m-%d")
    
    mindate_date=daily_resample['purchase_date'].min()
    mindate_date=maxdate_date - timedelta(29)
  
    
    # Sort DataFrame by userid & date column in descending order
    daily_resample.sort_values(by=['dp_userid','purchase_date'], ascending = True, inplace = True)
    daily_resample['purchase_date']=daily_resample['purchase_date'].astype(str)

    
    # Create a dictionary to hold the data
    data = {'dp_userid':[], 'purchase_date':[], 'avg_order_price_dt':[]}
    
    # Loop through each row of the input dataframe
    for index, row in daily_resample.iterrows():
        # Extract the relevant information from the row
        dp_userid = row['dp_userid']
        
        purchase_date = datetime.strptime(row['purchase_date'], '%Y-%m-%d')
        avg_order_price = row['avg_order_price_dt']
        
        # Generate a date range from the start date to end date
        #start_date = '20-11-2022'
        start_date = mindate_date
        
        #end_date = yesterday
        end_date = maxdate_date
        date_range = pd.date_range(start_date, end_date, freq='D')
        
        # Loop through each date in the range and append a row to the data dictionary for that date
        for date in date_range:
            data['dp_userid'].append(dp_userid)
            data['purchase_date'].append(date.strftime('%Y-%m-%d'))
            if date == purchase_date:
                data['avg_order_price_dt'].append(avg_order_price)
            else:
                data['avg_order_price_dt'].append(0)
    
    # Convert the data dictionary to a dataframe
    output_daily_resample = pd.DataFrame(data)
    
    # Sort the dataframe by dp_userid and purchase_date
    output_daily_resample = output_daily_resample.sort_values(by=['dp_userid', 'purchase_date'])
    
    # Reset the index of the dataframe
    output_daily_resample = output_daily_resample.reset_index(drop=True)
    
    # Display the dataframe
    output_daily_resample=output_daily_resample.drop_duplicates()
    output_daily_resample1=output_daily_resample[['dp_userid','purchase_date']].drop_duplicates()
    
    output_daily_resample1=output_daily_resample1.reset_index(drop=True)
    return output_daily_resample1



###############logic to build dynamic weeks & months
def preprocessing_resampledata_dynamic_week_months(output_daily_resample1,CAR_daily5):
    output_daily_resample1.sort_values(by=['dp_userid','purchase_date'], ascending = False, inplace = True)
    
    output_daily_resample1['purchase_date'] = pd.to_datetime(output_daily_resample1['purchase_date'], format='%Y-%m-%d')
    output_daily_resample1['RANK'] = output_daily_resample1.groupby('dp_userid')['purchase_date'].rank(ascending=False)
    output_daily_resample2=output_daily_resample1.copy()
    
    
    ##############getting dynamic week no 
    output_daily_resample2["RANK"]=output_daily_resample2["RANK"]-1
    output_daily_resample2['weeklyrank']=output_daily_resample2["RANK"]/7
    
    output_daily_resample2["weekno"]=output_daily_resample2["weeklyrank"].astype(str).str.split(".").str[0]
    output_daily_resample2["weekno"]=output_daily_resample2["weekno"].astype(int)
    output_daily_resample2["weekno"]=output_daily_resample2["weekno"]+1
    
    
    ##############getting dynamic month no 
    
    output_daily_resample2['monthlyrank']=output_daily_resample2["RANK"]/30
    
    output_daily_resample2["month_no"]=output_daily_resample2["monthlyrank"].astype(str).str.split(".").str[0]
    output_daily_resample2["month_no"]=output_daily_resample2["month_no"].astype(int)
    output_daily_resample2["month_no"]=output_daily_resample2["month_no"]+1
    
    
    
    ################
    output_daily_resample3=output_daily_resample2[['dp_userid','purchase_date','weekno','month_no']]
    
    ##########merging master data with dynamic weeks and months
    print('resample',output_daily_resample3.columns)
    print(CAR_daily5.columns)
    output_daily_resample3['purchase_date']=output_daily_resample3['purchase_date'].astype(str)
    daily_data=pd.merge(output_daily_resample3,CAR_daily5,how='left',on=['dp_userid','purchase_date'])
    return daily_data
    
def weekly_and_monthly_derive_data(daily_data):
    #################weekly_derive feilds
    weekly_derive=daily_data.groupby(['dp_userid','weekno'])['total_purchase_amt_daily','total_prod_purchased_daily'].sum()
    weekly_derive=weekly_derive.reset_index()
    weekly_derive['avg_total_purchase_amt_weekly']=weekly_derive['total_purchase_amt_daily']/weekly_derive['total_prod_purchased_daily']
    weekly_derive.rename(columns={'total_purchase_amt_daily':'total_purchase_amt_weekly',
                                  'total_prod_purchased_daily':'total_prod_purchased_weekly'},inplace=True)
    weekly_derive=weekly_derive[['dp_userid','weekno','avg_total_purchase_amt_weekly']]
    weekly_derive['weekno'] = 'W' + weekly_derive['weekno'].astype(str)+'average_amountweekly'
    transposed_weekly = weekly_derive.pivot(index="dp_userid", columns="weekno", values="avg_total_purchase_amt_weekly")
 
    # Reset the index
    transposed_weekly = transposed_weekly.reset_index()
    transposed_weekly=transposed_weekly.fillna(0)
    
    #################monthly_derive feilds 
    monthly_derive=daily_data.groupby(['dp_userid','month_no'])['total_purchase_amt_daily','total_prod_purchased_daily'].sum()
    monthly_derive=monthly_derive.reset_index()
    monthly_derive['avg_total_purchase_amt_monthly']=monthly_derive['total_purchase_amt_daily']/monthly_derive['total_prod_purchased_daily']
    monthly_derive.rename(columns={'total_purchase_amt_daily':'total_purchase_amt_monthly',
                                  'total_prod_purchased_daily':'total_prod_purchased_monthly'},inplace=True)
    monthly_derive=monthly_derive[['dp_userid','month_no','avg_total_purchase_amt_monthly']]
    monthly_derive['month_no'] = 'M' + monthly_derive['month_no'].astype(str)+'average_amountmonthly'
    transposed_monthly = monthly_derive.pivot(index="dp_userid", columns="month_no", values="avg_total_purchase_amt_monthly")
 
    # Reset the index
    transposed_monthly = transposed_monthly.reset_index()
    transposed_monthly=transposed_monthly.fillna(0)
    
    ############merge monthly & weekly feilds in daily data
    daily_data_filtered1=pd.merge(daily_data,transposed_monthly,how='left',on=['dp_userid'])
    daily_data_filtered2=pd.merge(daily_data_filtered1,transposed_weekly,how='left',on=['dp_userid'])
    return daily_data_filtered2

def create_weekly_kpis(daily_data_filtered2):
    data_for_weekly=daily_data_filtered2[['dp_userid', 'purchase_date', 'weekno', 'month_no','total_purchase_amt_daily', 'total_prod_purchased_daily', 'transactions_count_daily']]
    weekly_kpis=data_for_weekly.groupby(['dp_userid','weekno'])['total_purchase_amt_daily', 'total_prod_purchased_daily', 'transactions_count_daily'].sum()
    weekly_kpis=weekly_kpis.reset_index()
    
    weekly_kpis.rename(columns={'total_purchase_amt_daily':'total_purchase_amt_weekly',
                                'total_prod_purchased_daily':'total_prod_purchased_weekly',
                                'transactions_count_daily':'transactions_count_weekly'},inplace=True)
 
    return weekly_kpis

 
#############weekly avg budegt & avg duration &"avg_budget_daily", "avg_duration_daily","avg_buying_frequency","avg_frequency_daily"
def create_purchase_category_data(daily_data_filtered2):
    prefixes = ["avg_buying_frequency_daily", "avg_frequency_daily","avg_duration_daily","avg_budget_daily"]
    purchase_category_daily = [col for col in daily_data_filtered2.columns if col.startswith(tuple(prefixes))]
    purchase_category_weekly=daily_data_filtered2[purchase_category_daily]
    purchase_category_weekly=purchase_category_weekly.sort_index(axis = 1)
    
    purchase_category_weekly2=pd.concat([purchase_category_weekly,daily_data_filtered2[['dp_userid','weekno','purchase_date']]],axis=1)
    purchase_category_weekly2=purchase_category_weekly2.sort_index(axis = 1)
    purchase_category_weekly2=purchase_category_weekly2.fillna(0)
 
    #purchase_category_weekly3=purchase_category_weekly2.groupby(['dp_userid','weekno']).sum()
    ###########avg value sum/7
    purchase_category_weekly3=purchase_category_weekly2.groupby(['dp_userid','weekno']).sum()*(1/7)
    purchase_category_weekly3=purchase_category_weekly3.reset_index()
    
    purchase_category_weekly3.columns = purchase_category_weekly3.columns.str.replace('daily','weekly')
  
    return purchase_category_weekly3
    


def aggregate_weeklykpis(purchase_category_weekly3,weekly_kpis):
    Weekly_kpi_agg=pd.merge(purchase_category_weekly3,weekly_kpis,how='left',on=['dp_userid','weekno'])
    return Weekly_kpi_agg


def preprocessing_monthly_kpi(daily_data_filtered2):
    data_for_monthly=daily_data_filtered2[['dp_userid', 'purchase_date', 'weekno', 'month_no','total_purchase_amt_daily', 'total_prod_purchased_daily', 'transactions_count_daily']]
    
    
    monthly_kpis=data_for_monthly.groupby(['dp_userid','month_no'])['total_purchase_amt_daily', 'total_prod_purchased_daily', 'transactions_count_daily'].sum()
    monthly_kpis=monthly_kpis.reset_index()
    
    monthly_kpis.rename(columns={'total_purchase_amt_daily':'total_purchase_amt_monthly',
                                'total_prod_purchased_daily':'total_prod_purchased_monthly',
                                'transactions_count_daily':'transactions_count_monthly'},inplace=True)
                                
    monthly_kpis
    return monthly_kpis

  
##########monthly avg budget & avg duration &"avg_budget_daily", "avg_duration_daily","avg_buying_frequency","avg_frequency_daily"
def monthly_avg_budget_duration(daily_data_filtered2):
    prefixes = ["avg_buying_frequency_daily", "avg_frequency_daily","avg_duration_daily","avg_budget_daily"]
    
    purchase_category_daily = [col for col in daily_data_filtered2.columns if col.startswith(tuple(prefixes))]
    
    purchase_category_monthly=daily_data_filtered2[purchase_category_daily]
    purchase_category_monthly=purchase_category_monthly.sort_index(axis = 1)
    
    purchase_category_monthly2=pd.concat([purchase_category_monthly,daily_data_filtered2[['dp_userid','month_no','purchase_date']]],axis=1)
    purchase_category_monthly2=purchase_category_monthly2.sort_index(axis = 1)
    purchase_category_monthly2=purchase_category_monthly2.fillna(0)
    #purchase_category_monthly3=purchase_category_monthly2.groupby(['dp_userid','month_no']).sum()
    ###########avg value sum/7
    purchase_category_monthly3=purchase_category_monthly2.groupby(['dp_userid','month_no']).sum()*(1/30)
    purchase_category_monthly3=purchase_category_monthly3.reset_index()
    
    purchase_category_monthly3.columns = purchase_category_monthly3.columns.str.replace('daily','monthly')
    return purchase_category_monthly3

def aggregate_mnthlykpis(purchase_category_monthly3,monthly_kpis):
    monthly_kpi_agg=pd.merge(purchase_category_monthly3,monthly_kpis,how='left',on=['dp_userid','month_no'])
    return monthly_kpi_agg

##################### Merging weekly and monthly derive feilds
def merging_dailydata_monthly_weekly(daily_data_filtered2,monthly_kpi_agg,Weekly_kpi_agg):
    daily_data_filtered3=pd.merge(daily_data_filtered2,monthly_kpi_agg,how='left',on=['dp_userid','month_no'])
    daily_data_filtered4=pd.merge(daily_data_filtered3,Weekly_kpi_agg,how='left',on=['dp_userid','weekno'])
    return daily_data_filtered4

#############filtering the user whose data is available on maxdate(yesterday in future)
def filtering_daily_data_max_date(daily_data_filtered4):
    daily_data_filtered_finalised=daily_data_filtered4.loc[daily_data_filtered4['purchase_date'] == daily_data_filtered4['purchase_date'].max()]
    daily_data_filtered_finalised=daily_data_filtered_finalised.loc[daily_data_filtered_finalised['total_prod_purchased_daily'] > 0 ]
    return daily_data_filtered_finalised  


def DS_CAR_CAR_preprocessing(daily_data_filtered_finalised):
    
    DS_CAR_daily=daily_data_filtered_finalised.copy()
    
    DS_CAR_daily.columns = DS_CAR_daily.columns.str.replace(" ","")
    DS_CAR_daily.columns = DS_CAR_daily.columns.str.replace('+', 'plus')
    DS_CAR_daily.columns = DS_CAR_daily.columns.str.lower()
    
    DS_CAR_daily.columns = DS_CAR_daily.columns.str.replace('__', '_')
    DS_CAR_daily.columns = DS_CAR_daily.columns.str.replace('___', '_')
    DS_CAR_daily.columns = DS_CAR_daily.columns.str.replace('-', '')
    DS_CAR_daily.columns = DS_CAR_daily.columns.str.replace("'", "")
    DS_CAR_daily.columns = DS_CAR_daily.columns.str.replace('__', '_')

    DS_CAR_partition_date=DS_CAR_daily[['dp_userid','partition_date']]
    DS_CAR_daily=DS_CAR_daily.drop(['partition_date'], axis=1)
    
    DS_CAR_daily=pd.merge(DS_CAR_daily,DS_CAR_partition_date,how='left',on=['dp_userid'])
    
    DS_CAR_daily['partition_date']=DS_CAR_daily['partition_date'].astype(int)
    
    DS_CAR_daily=DS_CAR_daily.fillna(0)
    return DS_CAR_daily
  


########################################### Site user ################################################################


########## read siteuser table who did navigation on last day.
def read_siteuser_data(partition_date):
    query = "SELECT * FROM {} WHERE (partition_date={}) and start_date is not null".format(stg_dp_siteuserdata, partition_date)

    df_siteuser_data = pd.read_sql(query,hive_connection)
    df_siteuser_data = pd.DataFrame(df_siteuser_data)
    ###################
    cols_remap = {key: key.split(".")[1] for key in df_siteuser_data.columns}
    df_siteuser_data.rename(columns=cols_remap, inplace=True)
                         
    df_siteuser_data_new = df_siteuser_data[['dp_userid','browser','device','operatingsystem','start_date','end_date','category','sub_category']]
    
    ############# filtering users who did navigated on last day ( for now maxdate) in  data. maxdate will be replaced with last day (current day - 1)

    df_siteuser_data_new['start_date_mapping']=df_siteuser_data_new['start_date'].astype(str)
    df_siteuser_data_new["start_date_mapping"]=df_siteuser_data_new["start_date_mapping"].astype(str).str.split(" ").str[0]
    
    
    max_nav_date_user=df_siteuser_data_new.groupby(['dp_userid'])['start_date_mapping'].max()
    max_nav_date_user=max_nav_date_user.reset_index()
    
    ###maxdate will be replaced with last day (current day -1)
    maxdate_date=df_siteuser_data_new["start_date_mapping"].max()
    max_nav_date_user['CARlastday_users']=np.where(max_nav_date_user['start_date_mapping']==maxdate_date,1,0)
    max_nav_date_user=max_nav_date_user.loc[max_nav_date_user['CARlastday_users']== 1]
    max_nav_date_user=max_nav_date_user[['dp_userid','CARlastday_users']]
    df_siteuser_data_new=pd.merge(df_siteuser_data_new,max_nav_date_user,how='left',on=['dp_userid'])
    df_siteuser_data_new=df_siteuser_data_new.loc[df_siteuser_data_new['CARlastday_users']== 1]
    df_siteuser_data1 = df_siteuser_data_new.copy()
    df_siteuser_data1=df_siteuser_data1.drop(['start_date_mapping','CARlastday_users'], axis=1)
    
    return df_siteuser_data1



# Get all possible site user categories and subcategories
def get_site_catsubcat(partition_date):
    query = "select category,sub_category from {} where partition_date = {} and category != '' and category is not null and sub_category != '' and sub_category is not null group by category ,sub_category ".format(stg_dp_siteuserdata, partition_date)

    df_siteuser_data = pd.read_sql(query,hive_connection)
    df_siteuser_data = pd.DataFrame(df_siteuser_data)
    df_siteuser_data['navigation_cat_subcat']=df_siteuser_data['category'].astype(str)+"_"+df_siteuser_data['sub_category'].astype(str)
    return df_siteuser_data['navigation_cat_subcat'].unique().tolist()



# adding a dummy site user with all possible categories and sub_categories in order to get all columns that we want
def add_dummy_site_user(df_site,partition_date):
    cat_subcat = get_site_catsubcat(partition_date)
    print('cat_subcat',cat_subcat)
    # creating an empty df
    df_columns = ['dp_userid', 'browser', 'device', 'operatingsystem', 'start_date', 'end_date', 'category', 'sub_category']
    df_catsub = pd.DataFrame(columns=df_columns)

    # in order to get device_hystory_***
    device_array = ['Tablet', 'Mobile', 'Desktop']

    # adding new user
    k = 0
    for csc in cat_subcat:
        x = csc.split("_")
        new_row = pd.Series({
                                'dp_userid' : 'user_dummy', 
                                'browser' : None, 
                                'device' : device_array[k], 
                                'operatingsystem' : None, 
                                'start_date' : datetime.strptime(str(partition_date), '%Y%m%d') - timedelta(days=1) + timedelta(seconds=1),
                                'end_date' : datetime.strptime(str(partition_date), '%Y%m%d') - timedelta(days=1) + timedelta(seconds=11),
                                'category' : x[0], 
                                'sub_category' : x[1]
                            })
        
        df_catsub = pd.concat([df_catsub, new_row.to_frame().T], ignore_index=True)
        k = k + 1
        if k == 3:
            k = 0

    df_site = pd.concat([df_site, df_catsub], ignore_index=True)

    return df_site


### SIte user data time spend preprocess
def preprocessing_siteuser_data(df_siteuser_data1):
    df_siteuser_data1["duration"]=df_siteuser_data1['end_date']-df_siteuser_data1['start_date']
    df_siteuser_data1["recency_days"] = df_siteuser_data1["duration"].dt.days.sum()
    #print(df_siteuser_data1["recency_days"])
    # Extract the total number of hours and minutes separately from the "recency" column
    df_siteuser_data1["duration_hours"] = df_siteuser_data1["duration"].dt.total_seconds() / 3600
    df_siteuser_data1["duration_minutes"] = df_siteuser_data1["duration"].dt.total_seconds() / 60
    df_siteuser_data1["duration_in_seconds"] = df_siteuser_data1["duration"].dt.total_seconds()
    
    df_siteuser_data2=df_siteuser_data1[['dp_userid','browser','device','operatingsystem','start_date','end_date','category','sub_category','duration_in_seconds']]
    df_siteuser_data2['start_date_mapping']=df_siteuser_data2['start_date'].astype(str)
    df_siteuser_data2["start_date_mapping"]=df_siteuser_data2["start_date_mapping"].astype(str).str.split(" ").str[0]
    
    df_siteuser_data2.rename(columns={'category':'navigation_category'},inplace=True)
    df_siteuser_data2['navigation_cat_subcat']=df_siteuser_data2['navigation_category'].astype(str)+"_"+df_siteuser_data2['sub_category'].astype(str)
    df_siteuser_data3=df_siteuser_data2[['dp_userid','start_date_mapping','device','duration_in_seconds','navigation_category','navigation_cat_subcat']]
    
    ######## tranposing the categorical columns ### 
    cat_cols = ['device','navigation_category','navigation_cat_subcat']
    cat_cols_to_drop = [col for col in df_siteuser_data3.columns if col not in cat_cols + ['dp_userid']]
    site_user_agg = pd.get_dummies(df_siteuser_data3.drop(columns=cat_cols_to_drop), columns=cat_cols)
    
    site_user_agg=site_user_agg.drop(['dp_userid'],axis=1)
    #merging tranposed categorical columns with master data
    site_user_agg2 = pd.concat([df_siteuser_data3, site_user_agg], axis=1)
    site_user_agg2=site_user_agg2.drop(['device'],axis=1)
    site_user_agg3=site_user_agg2.groupby(['dp_userid', 'start_date_mapping']).sum()
    
    
    site_user_agg3.columns = site_user_agg3.columns.str.replace('device','avg_frequency_daily')
    site_user_agg3.columns = site_user_agg3.columns.str.replace('navigation_category','avg_frequency_daily')
    site_user_agg3.columns = site_user_agg3.columns.str.replace('navigation_cat_subcat','avg_frequency_daily')
    
    site_user_agg3.columns = site_user_agg3.columns.str.replace(' ','')
    site_user_agg3.columns = site_user_agg3.columns.str.replace('+', 'plus')
    site_user_agg3.columns = site_user_agg3.columns.str.lower()

    site_user_agg3=site_user_agg3.reset_index()
    return df_siteuser_data2,site_user_agg3,site_user_agg2
    
  


######################Device history
def device_historical(df_siteuser_data2):
    df_siteuser_device=df_siteuser_data2[['dp_userid','start_date_mapping','device']]
   
    ######## tranposing the categorical columns ### 
    cat_cols = ['device']
   
    cat_cols_to_drop = [col for col in df_siteuser_device.columns if col not in cat_cols + ['dp_userid']]
    site_user_device = pd.get_dummies(df_siteuser_device.drop(columns=cat_cols_to_drop), columns=cat_cols)
   
    site_user_device=site_user_device.drop(['dp_userid'],axis=1)
    #merging tranposed categorical columns with master data
    site_user_device2 = pd.concat([df_siteuser_device, site_user_device], axis=1)
    site_user_device2=site_user_device2.drop(['device'],axis=1)
    
    site_user_device3=site_user_device2.groupby(['dp_userid', 'start_date_mapping']).sum()

    site_user_device3=site_user_device3.reset_index()
   
    prefixes = ['device']
    col = [col for col in site_user_device3.columns if col.startswith(tuple(prefixes))]
   
    site_user_device3[col] = np.where((site_user_device3[col] > 1),1,site_user_device3[col])
   
    #site_user_device3=site_user_device3.drop(['start_date_mapping'],axis=1)
   
    History_device=site_user_device3.groupby(['dp_userid']).sum()
    History_device=History_device.reset_index()
    History_device.columns = History_device.columns.str.replace('device','device_history')
    #History_device.columns = History_device.columns.str.strip().str.lower()
    ################# History_device will Be added to output dataframe key"History_device"
    #History_device_uc2=History_device.copy()
    return History_device


# History_device = device_historical(df_siteuser_data2)


def total_time_spend_per_user_and_last_naviga_date(df_siteuser_data1,df_siteuser_data2):
        
    last_trans_part_navdate=df_siteuser_data1.groupby(['dp_userid'])['end_date'].max()
    last_trans_part_navdate=last_trans_part_navdate.reset_index()
   
    last_trans_part_navdate.rename(columns={'end_date':'last_navigation_date'},inplace=True)
   
    last_trans_part_navdate['last_navigation_date']=last_trans_part_navdate['last_navigation_date'].astype(str)
    last_trans_part_navdate["last_navigation_date"]=last_trans_part_navdate["last_navigation_date"].astype(str).str.split(" ").str[0]
   
    
    ############ daily level site user level time spend in category
   
    df_siteuser_agg=df_siteuser_data2[['dp_userid','start_date_mapping', 'navigation_category','duration_in_seconds']]
   
    ##########mappinng prod table
   
    df_siteuser_agg['navigation_category'] = 'avg_duration_daily_' + df_siteuser_agg['navigation_category'].astype(str)
   
    df_siteuser_agg1=df_siteuser_agg.groupby(['dp_userid','navigation_category','start_date_mapping'])['duration_in_seconds'].sum()
    df_siteuser_agg1=df_siteuser_agg1.reset_index()
    df_siteuser_agg1.rename(columns={'duration_in_seconds':'duration_in_seconds_daily'},inplace=True)
    df_siteuser_agg2 = df_siteuser_agg1.pivot(index=["dp_userid","start_date_mapping"], columns="navigation_category", values="duration_in_seconds_daily")
    # Reset the index
    df_siteuser_agg2 = df_siteuser_agg2.reset_index()
    df_siteuser_agg2=df_siteuser_agg2.fillna(0)

    df_siteuser_agg2.columns = df_siteuser_agg2.columns.str.replace(' ', '')
    df_siteuser_agg2.columns = df_siteuser_agg2.columns.str.replace('+', 'plus')
    df_siteuser_agg2.columns = df_siteuser_agg2.columns.str.lower()
    return df_siteuser_agg2,last_trans_part_navdate


############ daily level site user level time spend in cat sub  category
def daily_total_spend_per_cat_user(df_siteuser_agg2,df_siteuser_data2):
    df_siteuser_agg2.columns = df_siteuser_agg2.columns.str.replace(' ', '')
    df_siteuser_agg2.columns = df_siteuser_agg2.columns.str.replace('+', 'plus')
    df_siteuser_agg2.columns = df_siteuser_agg2.columns.str.lower()
    
    cat_subcat = []
    for i in range(len(df_siteuser_data2['navigation_category'])):
        if df_siteuser_data2['sub_category'][i] == '':
            cat_subcat.append(np.nan)
        else:
            cat_subcat.append(df_siteuser_data2['navigation_category'][i]+"_"+df_siteuser_data2['sub_category'][i])

    df_siteuser_data2['navigation_cat_subcat'] = cat_subcat 
    # df_siteuser_data2['navigation_cat_subcat']=df_siteuser_data2['navigation_category'].astype(str)+"_"+df_siteuser_data2['sub_category'].astype(str)
   
  
    df_siteuser_agg=df_siteuser_data2[['dp_userid','start_date_mapping', 'navigation_cat_subcat','duration_in_seconds']]
    df_siteuser_agg_cat_subcat=df_siteuser_agg.copy()
   
  
    ##########mappinng prod table
   
    df_siteuser_agg_cat_subcat['navigation_cat_subcat'] = 'avg_duration_daily_' + df_siteuser_agg_cat_subcat['navigation_cat_subcat'].astype(str)
   
    df_siteuser_agg_cat_subcat1=df_siteuser_agg_cat_subcat.groupby(['dp_userid','navigation_cat_subcat','start_date_mapping'])['duration_in_seconds'].sum()
    df_siteuser_agg_cat_subcat1=df_siteuser_agg_cat_subcat1.reset_index()
    df_siteuser_agg_cat_subcat1.rename(columns={'duration_in_seconds':'duration_in_seconds_daily'},inplace=True)
    df_siteuser_agg_cat_subcat2 = df_siteuser_agg_cat_subcat1.pivot(index=["dp_userid","start_date_mapping"], columns="navigation_cat_subcat", values="duration_in_seconds_daily")
    # Reset the index
    df_siteuser_agg_cat_subcat2 = df_siteuser_agg_cat_subcat2.reset_index()
    df_siteuser_agg_cat_subcat2=df_siteuser_agg_cat_subcat2.fillna(0)
   
    df_siteuser_agg_cat_subcat2.columns = df_siteuser_agg_cat_subcat2.columns.str.replace(' ', '')
    df_siteuser_agg_cat_subcat2.columns = df_siteuser_agg_cat_subcat2.columns.str.replace('+', 'plus')
    df_siteuser_agg_cat_subcat2.columns = df_siteuser_agg_cat_subcat2.columns.str.lower()
    return df_siteuser_agg_cat_subcat2



############ daily level site user level time spend in device tablet mobile and desktop

def daily_site_user_time_spend_device(df_siteuser_agg2,df_siteuser_data2):
    df_siteuser_agg2.columns = df_siteuser_agg2.columns.str.replace(' ', '')
    df_siteuser_agg2.columns = df_siteuser_agg2.columns.str.replace('+', 'plus')
    df_siteuser_agg2.columns = df_siteuser_agg2.columns.str.lower()
    df_siteuser_data2['device']=df_siteuser_data2['device']

    df_siteuser_agg=df_siteuser_data2[['dp_userid','start_date_mapping', 'device','duration_in_seconds']]
    df_siteuser_agg_device=df_siteuser_agg.copy()
  
    ##########m
    df_siteuser_agg_device['navigation_device'] = 'avg_duration_daily_' + df_siteuser_agg_device['device'].astype(str)
    df_siteuser_agg_device1=df_siteuser_agg_device.groupby(['dp_userid','navigation_device','start_date_mapping'])['duration_in_seconds'].sum()
    df_siteuser_agg_device1=df_siteuser_agg_device1.reset_index()
    df_siteuser_agg_device1.rename(columns={'duration_in_seconds':'duration_in_seconds_daily'},inplace=True)
    df_siteuser_agg_device2 = df_siteuser_agg_device1.pivot(index=["dp_userid","start_date_mapping"], columns="navigation_device", values="duration_in_seconds_daily")
    # Reset the index
    df_siteuser_agg_device2 = df_siteuser_agg_device2.reset_index()
    df_siteuser_agg_device2=df_siteuser_agg_device2.fillna(0)
    df_siteuser_agg_device2.columns = df_siteuser_agg_device2.columns.str.replace(' ', '')
    df_siteuser_agg_device2.columns = df_siteuser_agg_device2.columns.str.replace('+', 'plus')
    df_siteuser_agg_device2.columns = df_siteuser_agg_device2.columns.str.lower()
    return df_siteuser_agg_device2  
    
                        

################Merging Site user data with rest of data at daily level
def merge_siteuserdata_dailylevel(site_user_agg3,site_user_agg2):
   
    #site_user_agg3.rename(columns={'start_date_mapping':'purchase_date'},inplace=True)
    #data_03.rename(columns={'purchase_datemapping':'purchase_date'},inplace=True)
   
    site_user_agg2=site_user_agg2.drop_duplicates()
   
    master_siteuser_data_daily_level=site_user_agg3
    return master_siteuser_data_daily_level


def daily_level_agg(master_siteuser_data_daily_level,df_siteuser_agg2,df_siteuser_agg_cat_subcat2,last_trans_part_navdate,df_siteuser_agg_device2):
    
    CAR_daily5_siteuser=pd.merge(master_siteuser_data_daily_level,df_siteuser_agg_device2,how='left',on=["dp_userid","start_date_mapping"])
    
    #########adding daily site category level time duration spent
    CAR_daily5_siteuser=pd.merge(CAR_daily5_siteuser,df_siteuser_agg2,how='left',on=["dp_userid","start_date_mapping"])
    
    #########adding daily site category subcategory level time duration  spent
    CAR_daily5_siteuser=pd.merge(CAR_daily5_siteuser,df_siteuser_agg_cat_subcat2,how='left',on=["dp_userid","start_date_mapping"])
    
    #########adding daily last_navdate
    CAR_daily5_siteuser=pd.merge(CAR_daily5_siteuser,last_trans_part_navdate,how='left',on=["dp_userid"])
    
    ### last step for daily table
    CAR_daily5_siteuser.columns = CAR_daily5_siteuser.columns.str.replace(' ', '')
    CAR_daily5_siteuser.columns = CAR_daily5_siteuser.columns.str.replace('+', 'plus')
    CAR_daily5_siteuser.columns = CAR_daily5_siteuser.columns.str.lower()
    
    CAR_daily5_siteuser = CAR_daily5_siteuser.loc[:,~CAR_daily5_siteuser.columns.duplicated()]
    CAR_daily5_siteuser.rename(columns={'start_date_mapping':'navigation_date'},inplace=True)
    return CAR_daily5_siteuser
   


def daily_resampling_for_missingdata_site_user(CAR_daily5_siteuser):
    
    ######################Resampling daily level data for missing data points#############################################
    daily_resample=CAR_daily5_siteuser[['dp_userid', 'navigation_date', 'duration_in_seconds']]
    daily_resample['navigation_date'] = pd.to_datetime(daily_resample['navigation_date'], format='%Y-%m-%d')
    maxdate_date=daily_resample.loc[daily_resample['dp_userid']!= 'user_dummy','navigation_date'].max()
    
    yesterday = datetime.now() - timedelta(1)
    yesterday=yesterday.strftime("%Y-%m-%d")
    
    mindate_date=daily_resample['navigation_date'].min()
    mindate_date=maxdate_date - timedelta(29)
    
    # Sort DataFrame by userid & date column in descending order
    daily_resample.sort_values(by=['dp_userid','navigation_date'], ascending = True, inplace = True)
    
    daily_resample['navigation_date']=daily_resample['navigation_date'].astype(str)
    
    ################resampling 
    # Create a dictionary to hold the data
    data = {'dp_userid':[], 'navigation_date':[], 'duration_in_seconds':[]}
    
    # Loop through each row of the input dataframe
    for index, row in daily_resample.iterrows():
        # Extract the relevant information from the row
        dp_userid = row['dp_userid']
        navigation_date = datetime.strptime(row['navigation_date'], '%Y-%m-%d')
        avg_order_price = row['duration_in_seconds']
        
        # Generate a date range from the start date to end date
        #start_date = '20-11-2022'
        start_date = mindate_date
        
        #end_date = yesterday
        end_date = maxdate_date
        date_range = pd.date_range(start_date, end_date, freq='D')
        
        # Loop through each date in the range and append a row to the data dictionary for that date
        for date in date_range:
            data['dp_userid'].append(dp_userid)
            data['navigation_date'].append(date.strftime('%Y-%m-%d'))
            if date == navigation_date:
                data['duration_in_seconds'].append(avg_order_price)
            else:
                data['duration_in_seconds'].append(0)
    
    # Convert the data dictionary to a dataframe
    output_daily_resample = pd.DataFrame(data)
    
    # Sort the dataframe by dp_userid and navigation_date
    output_daily_resample = output_daily_resample.sort_values(by=['dp_userid', 'navigation_date'])
    
    # Reset the index of the dataframe
    output_daily_resample = output_daily_resample.reset_index(drop=True)
    
    # Display the dataframe
    
    output_daily_resample=output_daily_resample.drop_duplicates()
    output_daily_resample_site_user=output_daily_resample[['dp_userid','navigation_date']].drop_duplicates()
    
    output_daily_resample_site_user=output_daily_resample_site_user.reset_index(drop=True)
    
    return output_daily_resample_site_user




###############logic to build dynamic weeks & months
 
def weekly_and_monthly_derive_data_site_user(output_daily_resample_site_user,CAR_daily5_siteuser):    
    output_daily_resample_site_user.sort_values(by=['dp_userid','navigation_date'], ascending = False, inplace = True)
    
    output_daily_resample_site_user['navigation_date'] = pd.to_datetime(output_daily_resample_site_user['navigation_date'], format='%Y-%m-%d')
    output_daily_resample_site_user['RANK'] = output_daily_resample_site_user.groupby('dp_userid')['navigation_date'].rank(ascending=False)
    output_daily_resample2=output_daily_resample_site_user.copy()
    
    
    ##############getting dynamic week no 
    output_daily_resample2["RANK"]=output_daily_resample2["RANK"]-1
    output_daily_resample2['weeklyrank']=output_daily_resample2["RANK"]/7
    
    output_daily_resample2["weekno"]=output_daily_resample2["weeklyrank"].astype(str).str.split(".").str[0]
    
    output_daily_resample2["weekno"]=output_daily_resample2["weekno"].astype(int)
    output_daily_resample2["weekno"]=output_daily_resample2["weekno"]+1
    
    
    ##############getting dynamic month no 
    
    output_daily_resample2['monthlyrank']=output_daily_resample2["RANK"]/30
    
    output_daily_resample2["month_no"]=output_daily_resample2["monthlyrank"].astype(str).str.split(".").str[0]
    
    output_daily_resample2["month_no"]=output_daily_resample2["month_no"].astype(int)
    output_daily_resample2["month_no"]=output_daily_resample2["month_no"]+1

    
    ################
    output_daily_resample3=output_daily_resample2[['dp_userid','navigation_date','weekno','month_no']]
    
    ##########merging master data with dynamic weeks and months
    
    output_daily_resample3['navigation_date']=output_daily_resample3['navigation_date'].astype(str)
    daily_data_filtered_siteuser=pd.merge(output_daily_resample3,CAR_daily5_siteuser,how='left',on=['dp_userid','navigation_date'])
    return daily_data_filtered_siteuser


def create_weekly_kpis_site_user(daily_data_filtered2):    
    prefixes = ["avg_frequency_daily","avg_duration_daily"]
    purchase_category_daily = [col for col in daily_data_filtered2.columns if col.startswith(tuple(prefixes))]
    purchase_category_weekly=daily_data_filtered2[purchase_category_daily]
    purchase_category_weekly=purchase_category_weekly.sort_index(axis = 1)
    purchase_category_weekly2=pd.concat([purchase_category_weekly,daily_data_filtered2[['dp_userid','weekno']]],axis=1)
    purchase_category_weekly2=purchase_category_weekly2.sort_index(axis = 1)
    purchase_category_weekly2=purchase_category_weekly2.fillna(0)
    ###########avg value sum/7
    purchase_category_weekly3=purchase_category_weekly2.groupby(['dp_userid','weekno']).sum()*(1/7)
    purchase_category_weekly3=purchase_category_weekly3.reset_index()
    purchase_category_weekly3.columns = purchase_category_weekly3.columns.str.replace('daily','weekly')
    return purchase_category_weekly3

def create_monthly_kpis_siteuser(daily_data_filtered2):    
    ##########monthly avg budget & avg duration &"avg_budget_daily", "avg_duration_daily","avg_buying_frequency","avg_frequency_daily"
    
    prefixes = ["avg_frequency_daily","avg_duration_daily"]
    
    purchase_category_daily = [col for col in daily_data_filtered2.columns if col.startswith(tuple(prefixes))]
    purchase_category_monthly=daily_data_filtered2[purchase_category_daily]
    purchase_category_monthly=purchase_category_monthly.sort_index(axis = 1)
    purchase_category_monthly2=pd.concat([purchase_category_monthly,daily_data_filtered2[['dp_userid','month_no']]],axis=1)
    purchase_category_monthly2=purchase_category_monthly2.sort_index(axis = 1)
    purchase_category_monthly2=purchase_category_monthly2.fillna(0)
    #purchase_category_monthly3=purchase_category_monthly2.groupby(['dp_userid','month_no']).sum()
    ###########avg value sum/30
    purchase_category_monthly3=purchase_category_monthly2.groupby(['dp_userid','month_no']).sum()*(1/30)
    purchase_category_monthly3=purchase_category_monthly3.reset_index()
    purchase_category_monthly3.columns = purchase_category_monthly3.columns.str.replace('daily','monthly')
    return purchase_category_monthly3


def merging_dailydata_monthly_weekly_siteuser(daily_data_filtered_siteuser,purchase_category_weekly_siteuser,purchase_category_monthly_siteuser):
    ##################### Merging weekly and monthly derive feilds
    daily_data_filtered3=pd.merge(daily_data_filtered_siteuser,purchase_category_monthly_siteuser,how='left',on=['dp_userid','month_no'])
    
    daily_data_filtered5=pd.merge(daily_data_filtered3,purchase_category_weekly_siteuser,how='left',on=['dp_userid','weekno'])
    
    daily_data_filtered5['partition_date'] = partition_date;
    daily_data_filtered5['partition_date']=daily_data_filtered5['partition_date'].astype(int)
    
    ############last day navigated users- last day navigation kpis
    DS_CAR_daily=daily_data_filtered5.loc[daily_data_filtered5['navigation_date'] == daily_data_filtered5['navigation_date'].max()]
    return DS_CAR_daily


# all functions related to purchase table
def purchase_functions():
    ################# purchase table ###################################
    df_product = get_product_data(partition_date)
    df_purchase_data = get_purchase_user_data(partition_date)
    
    if (df_product.shape[0]<1 or df_purchase_data.shape[0]<1):
        return pd.DataFrame()
    
    df_purchase_data = add_dummy_purchase_user(df_purchase_data,partition_date)
    df_purchase_data, max_trans_date_user = get_last_day_users(partition_date, df_purchase_data)
    purchase_data_agg = prep_purchase_data(df_purchase_data) 
    purchase_data_agg,df_product_02 = transforming_product_data(df_product,purchase_data_agg)
    df_purchase_prod_daily = merging_purchase_prod_daily(purchase_data_agg,df_product_02)
    Avg_purchaseorder_price = calculating_avg_purchaseorder_price(df_purchase_prod_daily)
    max_min_purchaseorder_pricedaily = daily_price_statistics(df_purchase_prod_daily)
    purchase_online_store = daily_level_purchase_transactions_history(df_purchase_prod_daily)
    transposed_daily_catgory_amount = daily_level_purchase_category_aggregated(df_purchase_prod_daily,df_product_02)
    transposed_daily_category_subcategory_amount = daily_level_purchase_subcategory_aggregated(df_purchase_prod_daily,df_product_02)
    total_purchase_daily = processing_purchase_daily_data(df_purchase_prod_daily)
    total_prod_pur_daily = calculating_metrics(df_purchase_prod_daily)
    transacations_daily1 = daily_level_purchasingtransaction_data(df_purchase_prod_daily)
    data_01 = merging_data(purchase_data_agg,Avg_purchaseorder_price,df_product_02)
    last_trans_part_purchasedate,channel_agg2 = utility_function(data_01)
    data_03 = one_hot_encoding(data_01)
    CAR_daily5 = adding_daily_total_purchase_total_trans_max_min_daily_cat_subcat_timespend(data_03,total_purchase_daily,total_prod_pur_daily,transacations_daily1,purchase_online_store,max_min_purchaseorder_pricedaily,transposed_daily_catgory_amount,transposed_daily_category_subcategory_amount,channel_agg2 ,last_trans_part_purchasedate)
    
    output_daily_resample1 = daily_resampling_for_missingdata(CAR_daily5)
    daily_data = preprocessing_resampledata_dynamic_week_months(output_daily_resample1,CAR_daily5)
    daily_data_filtered2 = weekly_and_monthly_derive_data(daily_data)
    weekly_kpis = create_weekly_kpis(daily_data_filtered2) 
    purchase_category_weekly3 = create_purchase_category_data(daily_data_filtered2)
        
    Weekly_kpi_agg = aggregate_weeklykpis(purchase_category_weekly3,weekly_kpis)
    monthly_kpis = preprocessing_monthly_kpi(daily_data_filtered2)
    purchase_category_monthly3 = monthly_avg_budget_duration(daily_data_filtered2)
    monthly_kpi_agg = aggregate_mnthlykpis(purchase_category_monthly3,monthly_kpis)
    daily_data_filtered4 = merging_dailydata_monthly_weekly(daily_data_filtered2,monthly_kpi_agg,Weekly_kpi_agg)
    daily_data_filtered_finalised = filtering_daily_data_max_date(daily_data_filtered4)
    DS_CAR_daily = DS_CAR_CAR_preprocessing(daily_data_filtered_finalised)
    DS_CAR_daily = DS_CAR_daily.drop(['partition_date'], axis=1)
    DS_CAR_daily.rename(columns = {'weekno':'weekno_purchase'}, inplace = True)
    DS_CAR_daily.rename(columns = {'month_no':'month_no_purchase'}, inplace = True)
    return DS_CAR_daily
    
    
# all functions related to siteuser table

def site_users_functions():
    df_siteuser_data1 = read_siteuser_data(partition_date)
    if df_siteuser_data1.shape[0]<1:
        return pd.DataFrame()
        
    df_siteuser_data1 = add_dummy_site_user(df_siteuser_data1,partition_date)
    df_siteuser_data2,site_user_agg3,site_user_agg2 = preprocessing_siteuser_data(df_siteuser_data1)
    History_device = device_historical(df_siteuser_data2)
    
    df_siteuser_agg2,last_trans_part_navdate = total_time_spend_per_user_and_last_naviga_date(df_siteuser_data1,df_siteuser_data2)
    df_siteuser_agg_cat_subcat2 = daily_total_spend_per_cat_user(df_siteuser_agg2,df_siteuser_data2)
    df_siteuser_agg_device2 = daily_site_user_time_spend_device(df_siteuser_agg2,df_siteuser_data2)
    master_siteuser_data_daily_level = merge_siteuserdata_dailylevel(site_user_agg3,site_user_agg2)
    CAR_daily5_siteuser = daily_level_agg(master_siteuser_data_daily_level,df_siteuser_agg2,df_siteuser_agg_cat_subcat2,last_trans_part_navdate,df_siteuser_agg_device2)
    output_daily_resample_site_user = daily_resampling_for_missingdata_site_user(CAR_daily5_siteuser)
    daily_data_filtered_siteuser = weekly_and_monthly_derive_data_site_user(output_daily_resample_site_user,CAR_daily5_siteuser)
    purchase_category_weekly_siteuser = create_weekly_kpis_site_user(daily_data_filtered_siteuser)
    purchase_category_monthly_siteuser = create_monthly_kpis_siteuser(daily_data_filtered_siteuser)
    
    DS_CAR_daily_site = merging_dailydata_monthly_weekly_siteuser(daily_data_filtered_siteuser,purchase_category_weekly_siteuser,purchase_category_monthly_siteuser)
    
    DS_CAR_daily_site = pd.merge(DS_CAR_daily_site, History_device, how='left', on=['dp_userid'])

    car_userbehaviour_site = DS_CAR_daily_site.copy()
    car_userbehaviour_site = car_userbehaviour_site.drop(['partition_date'], axis=1)
    car_userbehaviour_site = car_userbehaviour_site.fillna(0)
    car_userbehaviour_site = car_userbehaviour_site.replace(np.nan,0)
    
    # remove special characters
    car_userbehaviour_site.columns = car_userbehaviour_site.columns.str.replace("'", '')
    car_userbehaviour_site.columns = car_userbehaviour_site.columns.str.replace("-", '')
    
    car_userbehaviour_site['dp_userid']=car_userbehaviour_site['dp_userid'].astype(str)
    car_userbehaviour_site['navigation_date']=car_userbehaviour_site['navigation_date'].astype(str)
    car_userbehaviour_site['last_navigation_date']=car_userbehaviour_site['last_navigation_date'].astype(str)
    
    #####################################################################################
    car_userbehaviour_site.rename(columns = {'weekno':'weekno_siteuser'}, inplace = True)
    car_userbehaviour_site.rename(columns = {'month_no':'month_no_siteuser'}, inplace = True)
    return car_userbehaviour_site
    

def merge_siteuser_purchase(car_userbehaviour_purchase,car_userbehaviour_site):
    if((car_userbehaviour_purchase.shape[0]>1) and (car_userbehaviour_site.shape[0]>1)) :
        car_userbehaviour_purchase['dp_userid']=car_userbehaviour_purchase['dp_userid'].astype(str)
        car_userbehaviour_purchase['purchase_date']=car_userbehaviour_purchase['purchase_date'].astype(str)
        car_userbehaviour_purchase['last_transaction_date']=car_userbehaviour_purchase['last_transaction_date'].astype(str)
        
        # merging siteuser and purchase table
        dtype = dict(dp_userid=str)
        car_userbehaviour = car_userbehaviour_purchase.astype(dtype).merge(car_userbehaviour_site.astype(dtype), how = 'outer',on='dp_userid')
        
    elif(car_userbehaviour_site.shape[0]>1):
        car_userbehaviour = car_userbehaviour_site
    elif(car_userbehaviour_purchase.shape[0]>1):
        car_userbehaviour = car_userbehaviour_purchase
    else:
        return pd.DataFrame()
    
    car_userbehaviour['partition_date'] = partition_date
    # removing dummy user
    car_userbehaviour = car_userbehaviour.loc[car_userbehaviour['dp_userid'] != 'user_dummy']
    car_userbehaviour=car_userbehaviour.fillna(0)
    print(car_userbehaviour.info())
    
    #Identify float columns and round values to 2 decimal places
    float_columns = car_userbehaviour.select_dtypes(include='float')
    car_userbehaviour[float_columns.columns] = float_columns.round(2)
    return car_userbehaviour


def main(partition_date):
    if (len(BUCKET_NAME) > 1):
        try:
            ################# purchase table ###################################
            car_userbehaviour_purchase = purchase_functions()
            
            ############################# site user ########################
            car_userbehaviour_site = site_users_functions()
            
            print('purchase',car_userbehaviour_purchase.shape)
            print('site user',car_userbehaviour_site.shape)

            # merge both table
            car_userbehaviour = merge_siteuser_purchase(car_userbehaviour_purchase,car_userbehaviour_site)
            if(car_userbehaviour.shape[0]<1):
                print('Does not have records in purchase and site user tabel.')
                return 0
            
            if(car_userbehaviour_site.shape[0]>1):
                car_userbehaviour['navigation_date'] = car_userbehaviour['navigation_date'].astype("string")
                car_userbehaviour['last_navigation_date'] = car_userbehaviour['last_navigation_date'].astype("string")
            
            if(car_userbehaviour_purchase.shape[0]>1):
                car_userbehaviour['purchase_date'] = car_userbehaviour['purchase_date'].astype("string")
                car_userbehaviour['last_transaction_date'] = car_userbehaviour['last_transaction_date'].astype("string")

            
            # # #  # Enable Arrow-based columnar data transfers
            # sc.conf.set("spark.sql.execution.arrow.pyspark.enabled", "true")
            
            car_userbehvaiour_sparkDF = sqlContext.createDataFrame(car_userbehaviour)
            cursor = hive_connection.cursor()
            
            # if the tables are creating first time then line 1503 should be uncommented.
            # cursor.execute("DROP TABLE IF EXISTS DP_Car_User_Behaviour")
            
            spark_session.sql("DROP TABLE IF EXISTS DS_CAR_userbehvaiour_temp")
            print("DM3Info Table DS_CAR_userbehvaiour_temp dropped")
            if car_userbehvaiour_sparkDF.head(1):
                car_userbehvaiour_sparkDF.write.saveAsTable("DS_CAR_userbehvaiour_temp")
                print("DM3Info Table DS_CAR_userbehvaiour_temp created")
            else:
                print("DM3Info Table DS_CAR_userbehvaiour_temp could not be created, dataframe is empty")
            
            query="select * from DS_CAR_userbehvaiour_temp"
            
            df_create = pd.read_sql(query,hive_connection)
            df_create = pd.DataFrame(df_create)
            cols_remap = {key: key.split(".")[1] for key in df_create.columns}
            df_create.rename(columns=cols_remap, inplace=True)
            df_create = rename_and_remove_underscore(df_create)
            new_col_str = convert_df_dtypes(df_create)
            
            query_dynamic_table = """CREATE TABLE IF NOT EXISTS DP_Car_User_Behaviour({}) 
            STORED AS ORC 
            LOCATION 's3://{}/data/hive/default/DP_Car_User_Behaviour' 
            TBLPROPERTIES ('transactional'='true')""".format(new_col_str, BUCKET_NAME)
            
            cursor.execute(query_dynamic_table)
            
            #### checking if table has records for this partition_date
            query = "SELECT count(*) FROM DP_Car_User_Behaviour WHERE partition_date ={}".format(partition_date)
            record_check = pd.read_sql(query,hive_connection)
            record_df = pd.DataFrame(record_check)
            print(record_df)
            
               
            # Check if DataFrame is empty
            if record_df.empty:
                print('The DataFrame is empty.')
            else:
                if (record_check['_c0'][0] > 1):
                    cursor.execute("DELETE FROM DP_Car_User_Behaviour WHERE partition_date = {}".format(partition_date))
            
            # Load data to hive table    
            print('loading the data into hive table')
            load_to_hive(car_userbehvaiour_sparkDF)
            
            ############### code to write to S3
            query="select * from DP_Car_User_Behaviour"
            dp_car_user_behaviour = pd.read_sql(query,hive_connection)
            dp_car_user_behaviour = pd.DataFrame(dp_car_user_behaviour)
            cols_remap = {key: key.split(".")[1] for key in dp_car_user_behaviour.columns}
            dp_car_user_behaviour.rename(columns=cols_remap, inplace=True)
            # dp_car_user_behaviour = rename_and_remove_underscore(dp_car_user_behaviour)
            path = "data/outbound/crm_analytics/DP_Car_User_Behaviour/DP_Car_User_Behaviour.csv"
            write_data_to_csv_on_s3(dp_car_user_behaviour, BUCKET_NAME, path)
            
            hive_connection.close()
            print('code completed')
            return 0
        except Exception as e:
            print(e)
            traceback.print_tb(e.__traceback__)
    else:
        print("Pass correct Bucket")



#__name__ = "__main__"
if __name__ == "__main__":
    # partition_date = 20230509
    # BUCKET_NAME= "amap-dm-product-dev-s3-data"
    stg_dp_siteuserdata = 'TRF_DP_Siteuserdata'
    stg_dp_product_attribute = 'TRF_DP_Product_Attribute'
    stg_dp_purchase_userdata = 'stg_dp_purchase_userdata'
    partition_date = int(sys.argv[1])  # in YYYYMMDD format  
    BUCKET_NAME = sys.argv[5] 
    
    spark_session = SparkSession.builder \
        .config("hive.exec.dynamic.partition.mode", "nonstrict") \
        .enableHiveSupport() \
        .getOrCreate()
    spark_session.sql(f"use default")
    
    # Get Context
    spark_context = SparkContext.getOrCreate()
    hive_connection = create_hive_connection()
    car_userbehaviour_purchase = main(partition_date)