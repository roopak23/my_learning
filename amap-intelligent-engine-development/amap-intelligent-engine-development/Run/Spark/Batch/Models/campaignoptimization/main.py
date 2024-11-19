# Spark Imports
from pyspark.context import SparkContext
from pyspark.sql.types import StructType,StructField, StringType, IntegerType
from pyspark.sql import SparkSession

#Importing libraries
import datetime
import sqlite3

# import pymysql
import traceback
import sys
import pandas as pd
import numpy as np
import warnings

# Custom Import
sys.path.append('/tmp/Libraries')
from ie_hive_connection import IEHiveConnection

warnings.filterwarnings('ignore')

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


#Start to load all the required input tables: 
# Function to load 'trf_fact_input' table. Also we are calculating 'forecasted' (Goal) field here.
def load_trf_fact_input(hive_connection,partition_date):
    query = "SELECT * FROM trf_fact_input WHERE (partition_date={})".format(partition_date) 
    trf_fact_input=pd.read_sql(query,hive_connection)
    trf_fact_input = pd.DataFrame(trf_fact_input)
    trf_fact_input.columns = [i.replace("trf_fact_input.", "") for i in trf_fact_input.columns]
    # trf_fact_input = trf_fact_input[trf_fact_input.date == trf_fact_input.date.max()]
    trf_fact_input['predicted_units']=trf_fact_input['predicted_units'].fillna('0')
    trf_fact_input['forecasted'] = trf_fact_input.predicted_units + trf_fact_input.quantity_delivered
    return trf_fact_input

# Function to load 'trf_product' table
def load_trf_prod(hive_connection, partition_date):
    query = "SELECT * FROM trf_product WHERE (partition_date={})".format(partition_date) 
    trf_prod=pd.read_sql(query,hive_connection)
    trf_prod = pd.DataFrame(trf_prod)
    trf_prod.columns = [i.replace("trf_product.", "") for i in trf_prod.columns]
    trf_prod.rename(columns = {'ad_format_id':'product_suggestion_id'}, inplace = True)
    return trf_prod


# Function to load 'trf_campaign' table only for GAM and DV360 campaign lines (this is done by joining 'trf_campaign' and 'stg_sa_ad_ops_system' and applying adserver_type in ('GAM', 'DV360') filter)
def load_trf_campaign(hive_connection, partition_date):
    query = "SELECT c.* FROM trf_campaign c join stg_sa_ad_ops_system s on ((c.system_id=s.adserver_id) AND (c.partition_date=s.partition_date)) where (s.adserver_type in ('GAM','DV360') and c.partition_date = {})".format(partition_date)
    trf_campaign=pd.read_sql(query,hive_connection)
    trf_campaign = pd.DataFrame(trf_campaign)
    trf_campaign.columns = [i.replace("c.", "") for i in trf_campaign.columns]
    trf_campaign['end_date'] = pd.to_datetime(trf_campaign['end_date'], dayfirst = True)
    trf_campaign = trf_campaign.drop(['adserver_target_remote_id', 'adserver_target_name', 'adserver_target_type', 'adserver_target_category'],1).drop_duplicates().reset_index(drop = True)
    return trf_campaign


# Function to form 'trf_industry' dataframe from trf_campaign for getting top 10 audiences
def load_trf_industry(df,filter_rank):
    df = df[['industry','commercial_audience','audience_name', 'tech_line_id']]
    trf_industry = df.groupby(['industry','commercial_audience','audience_name'])['tech_line_id'].nunique().reset_index()
    trf_industry.rename(columns = {'tech_line_id':'distinct_orders', 'commercial_audience':'audience_suggestion_commercial', 'audience_name':'audience_name_suggestion_commercial'}, inplace = True)
    trf_industry['ranking'] = trf_industry.groupby('industry')['distinct_orders'].rank("dense", ascending=False)
    trf_industry = trf_industry[trf_industry.ranking.astype('float') <= filter_rank]
    return trf_industry


# Function to load 'trf_inventory_check' table
def load_trf_inv(hive_connection, partition_date):
    query = "SELECT c.* FROM trf_inventory_check c join stg_sa_ad_ops_system s on ((c.system_id=s.adserver_id) AND (c.partition_date=s.partition_date)) where (s.adserver_type in ('GAM') and c.partition_date = {})".format(partition_date)
    trf_inv=pd.read_sql(query,hive_connection)
    trf_inv = pd.DataFrame(trf_inv)
    trf_inv.columns = [i.replace("c.", "") for i in trf_inv.columns]
    trf_inv['date'] = pd.to_datetime(trf_inv['date'], dayfirst = True)
    return trf_inv


#Function to import all the required input tables
def load_tables(partition_date, filter_rank):
    trf_fact_input = load_trf_fact_input(hive_connection, partition_date)
    print("trf_fact_input imported sucessfully.")
    trf_prod = load_trf_prod(hive_connection, partition_date)
    print("trf_prod imported sucessfully.")
    trf_campaign = load_trf_campaign(hive_connection, partition_date)
    print("trf_campaign imported sucessfully.")
    trf_inv = load_trf_inv(hive_connection, partition_date)
    print("trf_inv imported sucessfully.")
    trf_industry = load_trf_industry(trf_campaign, filter_rank)
    print("trf_industry imported sucessfully.")
    return trf_fact_input, trf_prod, trf_campaign, trf_inv, trf_industry


#The suggestions will be provided only for the GAM and DV360 campaigns that have been flagged as "underdelivering" (trf_fact_input.flag_optimisation = '1'):
def extract_underdelivery_lines(trf_fact_input, trf_campaign):
    trf_fact_input = trf_fact_input[(trf_fact_input.flag_optimisation == 1) | (trf_fact_input.flag_optimisation == '1')]
    print("Inside extract_underdelivery_lines")
    print(trf_fact_input.shape)
    expanded_df = trf_campaign.merge(trf_fact_input, on='tech_line_id', suffixes=('', '_delme'), how='inner')
    expanded_df = expanded_df[[c for c in expanded_df.columns if not c.endswith('_delme')]]
    print('Filtered underdelivery lines')
    return expanded_df


#Search and filter the products from trf_products for underdelivery lines aligned with line audience, objective, media_type, size, metric and cost.
def find_new_product(df,trf_prod):
    product_suggestion_df = df.merge(trf_prod, left_on = ['mediatype', 'metric', 'creative_size', 'unit_price'] , right_on = ['media_type','metric','size', 'unit_price'], suffixes=('', '_delme'), how='inner')
    product_suggestion_df = product_suggestion_df[[c for c in product_suggestion_df.columns if not c.endswith('_delme')]]
    product_suggestion_df['objective_list'] = product_suggestion_df.objective_list.apply(lambda x: x.split(';') if isinstance(x, str) else 'None')
    product_suggestion_df.objective = product_suggestion_df.objective.astype('str')
    product_suggestion_df['flag_objective'] = product_suggestion_df.apply(lambda x: 1 if x.objective == 'nan' or x.objective_list == 'None' or x.objective in x.objective_list else 0, axis=1)
    product_suggestion_df['audience_list'] = product_suggestion_df.audience_list.apply(lambda x: x.split(';') if isinstance(x, str) else 'None')
    product_suggestion_df['original_audience_name'] = product_suggestion_df.commercial_audience.apply(lambda x: x.split(';') if isinstance(x, str) else 'None')
    product_suggestion_df['flag_audience'] = product_suggestion_df.apply(lambda x: 1 if x.audience_list == 'None' or set(x.original_audience_name).issubset(set(x.audience_list)) else 0, axis=1)
    product_suggestion_df = product_suggestion_df[(product_suggestion_df.flag_objective == 1)&(product_suggestion_df.flag_audience ==1)&(product_suggestion_df.ad_format_id != product_suggestion_df.product_suggestion_id)]
    columns_to_remove = ['flag_objective','flag_audience','objective_list','audience_list', 'original_audience_name']
    product_suggestion_df.drop(columns_to_remove, 1, inplace = True) 
    product_suggestion_df['original_value'] = product_suggestion_df.apply(lambda x:x.ad_format_id if (x.ad_format_id != 'nan' or x.ad_format_id!='') else 'None', axis=1)
    product_suggestion_df['recommendation_type'] = 'PRODUCT'
    print("product_suggestion_df formed")
    return product_suggestion_df.drop_duplicates().reset_index(drop=True)


#Search and filter audiences most brought by advertisers from trf_industry table with the same industry.
def find_new_audience(df, trf_industry):
    audience_suggestion_df = df.merge(trf_industry, left_on = 'industry', right_on = 'industry', how = 'inner')
    audience_suggestion_df = audience_suggestion_df[audience_suggestion_df.apply(lambda x: x.audience_suggestion_commercial not in x.commercial_audience, axis = 1)]
    audience_suggestion_df['original_value'] = audience_suggestion_df.apply(lambda x:x.commercial_audience if (x.commercial_audience != 'nan' or x.commercial_audience!='') else 'None', axis=1)
    audience_suggestion_df['recommendation_type'] = 'AUDIENCE'
    print("audience_suggestion_df formed")
    return audience_suggestion_df.reset_index(drop=True)


#Priority configuration suggestions:Provide a new configuration with higher priority. In case of non existence of priority in old scenerio, default priority value 6 or 4 will be allotted as a new priority for 'STANDARD' or 'SPONSORSHIP' line_type respectively 
def find_new_priority(priority, line_type, parameters):
    if line_type=='STANDARD':
        pr_list=6
    else:
        pr_list=4
    try:
        priority = int(priority)
    except:
        pass
    if isinstance(priority, int):
        new_priorities = parameters['priority'][line_type]
        pr_list = list(filter(lambda value: value >= priority, new_priorities))
        if len(pr_list)>1:
            pr_list= pr_list[1]
        else:
            pr_list= pr_list[0]
    return pr_list


#Forming the dataframe for Priority Configuration
def find_new_priority_configuration(df, parameters):
    df['priority_suggestion'] = df.apply(lambda x: find_new_priority(x.priority, x.line_type, parameters), axis =1)
    df = df.explode('priority_suggestion').reset_index(drop=True)
    df['original_value'] = df.apply(lambda x:x.priority if (x.priority != 'nan' or x.ad_format_id!='') else 'None', axis=1)
    df['recommendation_type'] = 'PRIORITY'
    df['priority_suggestion'] = df['priority_suggestion'].astype(str).replace('\.0', '', regex=True)
    print("priority_configuration_suggestion_df formed")
    return df


#Frequency Capp configuration suggestions: Provide a new frequency capping configuration (old freq capp + 1) with respect to current frequency capping. In case of non existence of frequency capping in old scenerio the default value 1 as a new frequency capping will be allotted.
def find_new_freq_cap(freq_cap):
    freq_return =1
    try:
        freq_cap = int(freq_cap)
    except:
        pass
    if isinstance(freq_cap, int):
           freq_return=freq_cap + 1
    return freq_return


#Forming the dataframe for Frequency Capping Configuration
def find_new_freqcapp_configuration(df):
    df['freq_suggestion'] = df.apply(lambda x: find_new_freq_cap(x.frequency_capping_quantity), axis =1)
    df['original_value'] = df.apply(lambda x:x.frequency_capping_quantity if (x.frequency_capping_quantity != 'nan' or x.frequency_capping_quantity!='') else 'None', axis=1)
    df['recommendation_type'] = 'FREQUENCY'
    print("frequency_configuration_suggestion_df formed")
    return df


#Concatenating all the suggestions for underdelivery campaigns
def search_new_suggestions(df, trf_prod, trf_industry, parameters):
    product_suggestion_df = find_new_product(df, trf_prod)
    audience_suggestion_df = find_new_audience(df, trf_industry)
    configuration_suggestion_df_priority = find_new_priority_configuration(df, parameters)
    configuration_suggestion_df_frequency = find_new_freqcapp_configuration(df)
    suggestion_df = pd.concat([product_suggestion_df, audience_suggestion_df, configuration_suggestion_df_priority,configuration_suggestion_df_frequency]).reset_index(drop=True)
    print('suggestions_df formed')
    return suggestion_df


#Load product technical catalogue from stg_sa_adformatspec, stg_sa_afsadslot and trf_sa_ad_slot.
#Here we are getting the 'technical_product_suggestion_id' (original_tech_product_id) for all the suggestions.
def load_adserver_adslot_id(df, partition_date):
    list_adformats = list(df[df.product_suggestion_id.notnull()].product_suggestion_id.unique()) + list(df.ad_format_id.unique())
    adformats = str(list_adformats).replace('[','(').replace(']',')')
    query = "SELECT T2.ad_format_id as product_suggestion_id, T4.adserver_adslotid as technical_product_suggestion_id "
    query += "FROM stg_sa_adformatspec AS T2   "
    query += "JOIN stg_sa_afsadslot AS T3 ON T3.afsid = T2.afsid  "
    query += "JOIN trf_sa_ad_slot AS T4 ON T4.sa_adslot_id = T3.sa_adslot_id  "
    query += f"WHERE T2.partition_date =  {partition_date}  "
    query += f"AND T3.partition_date  = {partition_date} "
    query += f"AND T4.partition_date  = {partition_date} "
    query += f"AND T2.ad_format_id IN {adformats}"
    technical_products = pd.read_sql(query,hive_connection)
    technical_products = pd.DataFrame(technical_products)
    technical_products = technical_products.groupby('product_suggestion_id')['technical_product_suggestion_id'].unique().reset_index()
    df_technical = df.merge(technical_products, on = 'product_suggestion_id', how = 'left').merge(technical_products, left_on = 'ad_format_id', right_on = 'product_suggestion_id', how = 'left', suffixes=('', '_delme'))
    df_technical.rename(columns={df_technical.columns[-1]:'original_tech_product_id'}, inplace=True)
    df_technical = df_technical[[c for c in df_technical.columns if not c.endswith('_delme')]]
    print('Technical products imported')
    return df_technical 


# Function to extract adserver_target_remote_id for different audiences
def extract_audience_from_taxonomy(x, taxonomy):
    try:
        return taxonomy[taxonomy.taxonomy_segment_name.isin(x.split(';'))].platform_segment_unique_id.unique()
    except:
        return np.nan


#Loading audience technical catalogue from stg_sa_market_targeting and stg_sa_targeting (join is done based on target_id)
#Here we are getting the 'adserver_target_remote_id' for all the audience suggestions
def load_platform_name(df, partition_date):
    query1 = "SELECT * FROM stg_sa_market_targeting WHERE (partition_date={})".format(partition_date)
    stg_audience1 = pd.read_sql(query1,hive_connection)
    stg_audience1 = pd.DataFrame(stg_audience1)
    stg_audience1.columns = [i.replace("stg_sa_market_targeting.", "") for i in stg_audience1.columns]
    query2 = "SELECT * FROM stg_sa_targeting WHERE (partition_date={})".format(partition_date)
    stg_audience2 = pd.read_sql(query2,hive_connection)
    stg_audience2 = pd.DataFrame(stg_audience2)
    stg_audience2.columns = [i.replace("stg_sa_targeting.", "") for i in stg_audience2.columns]
    taxonomy= stg_audience1.merge(stg_audience2, on ='target_id', suffixes=('', '_delme'))
    taxonomy = taxonomy[['adserver_target_remote_id', 'commercial_audience_id']]
    taxonomy.rename(columns = {'commercial_audience_id':'taxonomy_segment_name', 'adserver_target_remote_id':'platform_segment_unique_id'}, inplace = True)
    taxonomy.platform_segment_unique_id = taxonomy.platform_segment_unique_id.astype('str')
    df['original_audience_technical'] = df.commercial_audience.apply(lambda x: extract_audience_from_taxonomy(x, taxonomy))
    df['suggestion_audience_technical'] = df.audience_suggestion_commercial.apply(lambda x: extract_audience_from_taxonomy(x, taxonomy))
    print('Technical audiences imported')
    return df


# Applying 'load_adserver_adslot_id' and 'load_platform_name' functions on suggestion_df. Also deleting the unwanted fields in suggestion_df
def load_technical_catalogue(df, partition_date):
    technical_products = load_adserver_adslot_id(df, partition_date)
    technical_products = load_platform_name(technical_products, partition_date)
    drop_col = ['tech_line_name', 'market_order_id', 'market_order_line_details_id', 'carrier_targeting', 'custom_targeting','daypart_targeting', 'device_targeting', 'geo_targeting','os_targeting', 'time_slot_targeting', 'weekpart_targeting','creative_ad_type', 'discount_ds', 'discount_ssp', 'budget_cumulative_delivered', 'budget_cumulative_expected','budget_daily_delivered', 'remaining_budget', 'daily_expected_pacing', 'actual_pacing', 'flag_optimisation_temp','breadcrumb','daily_quantity_expected', 'cumulative_quantity_expected','cumulative_quantity_delivered', 'relative_quantity_delivered', 'delta_perc','size','adserver_id','distinct_orders','ranking']
    technical_products.drop(drop_col, 1, inplace=True)
    return technical_products


#For confirming the availability of inventory in 'trf_inventory_check' table for all the recommendations
def run_inventory_check(df, trf_inv):
    ok_list = []
    for num, (original_prod, sugg_prod, original_aud, sugg_aud, metric, goal, end_date, remaining_days) in enumerate(zip(df.original_tech_product_id, df.technical_product_suggestion_id, df.original_audience_technical, df.suggestion_audience_technical, df.metric, df.forecasted, df.end_date, df.remaining_days)):
        if str(sugg_prod) == 'nan':
            sugg_prod = original_prod
        if str(sugg_aud) == 'nan':
            sugg_aud = original_aud
        if end_date <= trf_inv['date'].max():
            trf_temp = trf_inv[(trf_inv.remote_id.isin(list(sugg_prod)))&(trf_inv.audience_id.astype('str').isin(list(sugg_aud)))&(trf_inv.metric == metric)&(trf_inv['date'] <= end_date)]
            available_quantities = trf_temp.availability.sum()
            if available_quantities >= goal:
                ok_list.append(num)
        else:
            trf_temp = trf_inv[(trf_inv.remote_id.astype('str').isin(list(sugg_prod)))&(trf_inv.audience_id.astype('str').isin(list(sugg_aud)))&(trf_inv.metric == metric)&(trf_inv['date'] <= end_date)]
            available_quantities = remaining_days*trf_temp.availability.sum()/len(trf_inv['date'].unique())
            if available_quantities >= goal:
                ok_list.append(num)
    df = df[df.index.isin(ok_list)].reset_index(drop=True)
    if len(df) > 0:
        print('Inventory check status: ok')
    return df


#Function reform the id's
def extract_from_list(id):
    id = str(id).replace('[','').replace(']','').replace(' ',';').replace("'","")
    return id


#Configuration Types based on currently implemented records of priority and frequency_capping_quantity for underdelivery campaigns are determined
def extract_configuration_type(row):  
    if (row['recommendation_type'] == 'FREQUENCY'):
        conf_type = 'FREQUENCY'
    elif (row['recommendation_type'] =='PRIORITY'):
        conf_type = 'PRIORITY'
    return conf_type


# Extracting the new configuration values for FREQUENCY and PRIORITY
def extract_configuration(row):  
    conf_type = extract_configuration_type(row)
    if conf_type == 'FREQUENCY':
        new_config = str(row['freq_suggestion'])
    elif conf_type == 'PRIORITY':
        new_config = str(row['priority_suggestion'])
    return new_config


#Forming the final output table as per requirement
def create_trf_onnet_model_output(suggestion_df): 
    suggestion_list = []
    for enum, i in suggestion_df.iterrows():
        if i['recommendation_type'] == 'PRODUCT':
            suggestion_list.append([i['tech_line_id'],i['tech_order_id'],i['metric'],enum,i['recommendation_type'],extract_from_list(i['technical_product_suggestion_id']),extract_from_list(i['product_suggestion_id']),i['original_value'],i['predicted_units'],i['partition_date']])
        elif i['recommendation_type'] == 'AUDIENCE':
            suggestion_list.append([i['tech_line_id'],i['tech_order_id'],i['metric'],enum,i['recommendation_type'],extract_from_list(i['suggestion_audience_technical']),extract_from_list(i['audience_suggestion_commercial']),i['original_value'],i['predicted_units'],i['partition_date']])
        elif i['recommendation_type'] == 'PRIORITY':
            suggestion_list.append([i['tech_line_id'],i['tech_order_id'],i['metric'],enum,i['recommendation_type'],'',extract_configuration(i),i['original_value'],i['predicted_units'],i['partition_date']])
        elif i['recommendation_type'] == 'FREQUENCY':
            suggestion_list.append([i['tech_line_id'],i['tech_order_id'],i['metric'],enum,i['recommendation_type'],'',extract_configuration(i),i['original_value'],i['predicted_units'],i['partition_date']])
    trf_onnet_model_output = pd.DataFrame(suggestion_list, columns = ['tech_line_id','tech_order_id','unit_type','model_id','optimization_type','technical_id','commercial_id','original_value','original_predicted_units','partition_date'])
    print('trf_onnet_model_output created')
    return trf_onnet_model_output
    
    
#Exploding the 'technical_id' field
def explode_techid(trf_onnet_model_output):
    trf_onnet_model_output.original_predicted_units=trf_onnet_model_output.original_predicted_units.astype(int)
    trf_onnet_model_output.partition_date=trf_onnet_model_output.partition_date.astype(int)
    trf_onnet_model_output['key']=trf_onnet_model_output['tech_line_id'].astype(str)+"___"+trf_onnet_model_output['tech_order_id'].astype(str)+"___"+trf_onnet_model_output['unit_type'].astype(str)+"___"+trf_onnet_model_output['model_id'].astype(str)+"___"+trf_onnet_model_output['optimization_type'].astype(str)+"___"+trf_onnet_model_output['commercial_id'].astype(str)+"___"+trf_onnet_model_output['original_value'].astype(str)+"___"+trf_onnet_model_output['original_predicted_units'].astype(str)+"___"+trf_onnet_model_output['partition_date'].astype(str)
    trf_onnet_model_output1=trf_onnet_model_output[["key","technical_id"]]
    tech_split = trf_onnet_model_output1['technical_id'].str.split(';',expand=True)
    df2 = pd.concat([trf_onnet_model_output1,tech_split], axis=1)
    df2=df2.drop(['technical_id'], axis=1)
    df3=df2.set_index('key').stack().droplevel(1).reset_index(name='technical_id')
    df3["tech_line_id"]=df3["key"].astype(str).str.split("___").str[0]
    df3["tech_order_id"]=df3["key"].astype(str).str.split("___").str[1]
    df3["unit_type"]=df3["key"].astype(str).str.split("___").str[2]
    df3["optimization_type"]=df3["key"].astype(str).str.split("___").str[4]
    df3["commercial_id"]=df3["key"].astype(str).str.split("___").str[5]
    df3["original_value"]=df3["key"].astype(str).str.split("___").str[6]
    df3["original_predicted_units"]=df3["key"].astype(str).str.split("___").str[7]
    df3["partition_date"]=df3["key"].astype(str).str.split("___").str[8]
    df3 = df3.drop('key', axis=1)
    
    #Reforming the 'model_id' field
    start = 1
    df3.insert(9, 'model_id', range(start, start + df3.shape[0]))

    #Reforming the trf_onnet_model_output with int datatype for partition_date and original_predicted_units
    trf_onnet_model_output=df3
    trf_onnet_model_output.original_predicted_units=trf_onnet_model_output.original_predicted_units.astype(int)
    trf_onnet_model_output.partition_date=trf_onnet_model_output.partition_date.astype(int)
    trf_onnet_model_output=trf_onnet_model_output[['tech_line_id','tech_order_id','unit_type','model_id','optimization_type','technical_id','commercial_id','original_value','original_predicted_units','partition_date']]
    trf_onnet_model_output['technical_id'] = trf_onnet_model_output['technical_id'].str.replace('\W', '', regex=True)
    trf_onnet_model_output['original_value']=trf_onnet_model_output['original_value'].str.replace('nan', '')
    
    #Converting the trf_onnet_model_output form Pandas to Spark dataframe to save it as Hive Table
    #Changing the datatypes of trf_onnet_model_output Dataframe as per the requirements:
    mySchema = StructType([StructField("tech_line_id", StringType(), True),
            StructField("tech_order_id", StringType(), True),
            StructField("unit_type", StringType(), True),
            StructField("model_id", StringType(), True),
            StructField("optimization_type", StringType(), True),
            StructField("technical_id", StringType(), True),
            StructField("commercial_id", StringType(), True),
            StructField("original_value", StringType(), True),
            StructField("original_predicted_units", IntegerType(), True),
            StructField("partition_date", IntegerType(), True)])
    sparkDF2 = spark_session.createDataFrame(trf_onnet_model_output, schema=mySchema)
    print((sparkDF2.count(), len(sparkDF2.columns)))
    print("The 'trf_onnet_model_output' sparkdf conversion completed")
    return sparkDF2
   
    
#Function to load the final output dataframe in Hive table of default.trf_onnet_model_output
def load_to_hive(df, table_name, partitioned: str, today: str) -> None:
    df.show()
    if df.head(1):
        conn = IEHiveConnection()
        cursor = conn.cursor()
        spark_session.sql("drop table if exists trf_onnet_model_output_temp")
        df.write.mode('overwrite').saveAsTable("trf_onnet_model_output_temp")
        cursor.execute("insert into table trf_onnet_model_output select * from trf_onnet_model_output_temp")
        spark_session.sql("drop table if exists trf_onnet_model_output_temp")
        print("The data is inserted in trf_onnet_model_output")
        conn.close()
    else:
        print("[DM3][ERROR] The DF has not elements, please check the validation rules")


def main(parameters):
      #try:
        trf_fact_input, trf_prod, trf_campaign, trf_inv, trf_industry = load_tables(parameters['partition_date'], parameters['num_industry_audience'])
        underdelivery_df = extract_underdelivery_lines(trf_fact_input, trf_campaign)
        if len(underdelivery_df)>1:
            suggestion_df = search_new_suggestions(underdelivery_df, trf_prod, trf_industry, parameters)
            suggestion_df = load_technical_catalogue(suggestion_df, parameters['partition_date'])
            # suggestion_df = run_inventory_check(suggestion_df, trf_inv)
            trf_onnet_model_output = create_trf_onnet_model_output(suggestion_df)
            print(trf_onnet_model_output.shape)
            sparkDF2=explode_techid(trf_onnet_model_output)
            print(parameters['partition_date'])
            load_to_hive(sparkDF2, 'trf_onnet_model_output', 'partition_date', parameters['partition_date'])
            return 0
        else:
            print("Either no data available in trf_fact_input table for the given partition date or no records available meeting the required criteria for underdelivery campaign")
      #except Exception as e:
         #pass


#Parameters of the priority:
__name__ = "__main__"
if __name__ == "__main__":
    parameters = {
        # INSERT PARAMETERS INARIABLES.YAML
        # 'partition_date' : 20230522,
        'num_industry_audience': 10,
        'priority':{
            'STANDARD': [6,8,10],
            'SPONSORSHIP': [4]
        },
        'partition_date': sys.argv[1]  # Always last value
    }

    print(f'[DM3][INFO] [MAIN] partition date: {parameters["partition_date"]}')
    
    try:
        hive_connection = create_hive_connection()
        spark_session = SparkSession.builder \
            .config("hive.exec.dynamic.partition.mode", "nonstrict") \
            .enableHiveSupport() \
            .getOrCreate()
        spark_session.sql(f"USE default")
        spark_context = SparkContext.getOrCreate()
        spark_context.setLogLevel("INFO")
        trf_onnet_model_output = main(parameters)
    except Exception as e:
        print(e)
        traceback.print_tb(e.__traceback__)
