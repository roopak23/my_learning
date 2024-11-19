import os
import sys
import logging
import datetime, pytz
import pandas as pd
import pymysql
from io import StringIO
import boto3
import requests
from time import gmtime, strftime

# Get Stack Name
rds_host  = os.environ['ENDPOINT']
name = os.environ['USERNAME']
password = os.environ['PASSWORD']
bucket = os.environ['BUCKET']
sns_topic_arn = os.environ['SNS_TOPIC_ARN']
env = os.environ['ENVIRONMENT']
SUMO_HTTP_ENDPOINT = os.environ['SUMO_HTTP_ENDPOINT']

rundate = int(datetime.datetime.now(pytz.timezone('Australia/Sydney')).strftime('%Y%m%d'))
today = datetime.datetime.now(pytz.timezone('Australia/Sydney')).strftime('%Y-%m-%d')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    try:
        monnitoring_log(rundate)
        return "Function executed Successfully"
    
    except Exception as e:
        logger.error("Monitoring Log Failed : {}".format(e))
        
def trigger_sns(subject, message):

    response = ''
 
    ## mesage atributes that can be used as filter for the recipients
    messageAttributes = {
        'Status': {
            'DataType': 'String.Array',
            'StringValue':  "Success"
  
        }
    }
    
    sns = boto3.client('sns')
    response = sns.publish( TopicArn=sns_topic_arn, Subject=subject, Message=message, MessageAttributes=messageAttributes)
				
    return str({'sent': False , 'subject': subject, 'text': message,'messageAttributes':messageAttributes, 'response': response})

def sumologic_log(subject, message):

    session = requests.Session()
    headers = {"Content-Type": "text/html", "Accept" : "application/json"}
    msg = subject + "\n" +  message
    r = session.post(SUMO_HTTP_ENDPOINT, headers=headers, data=msg)
    
def data_extract(db_name, table_name):
    """
    This function fetches content from mysql RDS instance
    """
    try:
        conn = pymysql.connect(host = rds_host, user=name, passwd=password, db=db_name)
    
        result = pd.read_sql("Select * from {table_name}".format(table_name = table_name), conn)
        row_count = result.shape[0]
        # Check row_count returned from query
        if(row_count == 0):
            print("query returned 0-rows")
            return result
            
        else:
        
            return result

    except:
        logger.error("ERROR: Unexpected error: Could not connect to MySql instance.")
        sys.exit()
       
def write_data_to_csv_on_s3(dataframe, filename, bucket):
    """ Write a dataframe to a CSV on S3 """
    try:
    
        print("Writing {} records to {}".format(len(dataframe), filename))
    
        csv_buffer = StringIO()
        dataframe.to_csv(csv_buffer, sep=",", index=False)
        s3_resource = boto3.resource("s3")
        s3_resource.Object(bucket, filename).put(Body=csv_buffer.getvalue())
    
    except:
        logger.error("ERROR: Unexpected error: Could not load the file to S3 Bucket.")
        sys.exit()
    
def monnitoring_log(rundate):
    '''
    Main Lambda function method
    '''
    try:
        downstream = data_extract('monitoring','usecases_downstream')
        sa_push = data_extract('monitoring','sa_pushstatus')
        
        sa_push = sa_push[sa_push['rundate'] == rundate]
        downstream = downstream[['usecase_name', 'downstream_system', 'downstreamtable_list']]
        downstream['downstreamtable_list'] = downstream['downstreamtable_list'].str.split(',')
        downstream = downstream.explode('downstreamtable_list')

        success= []
        failure= []
        
        for index, row in downstream.iterrows():
            if row['downstreamtable_list'] in [item['object_name'] for index, item in sa_push.iterrows()] and rundate in [item['rundate'] for index, item in sa_push.iterrows()]:
                DownStreamTableList = row['downstreamtable_list']
                UseCaseName = row['usecase_name']
                success.append({"DownStreamTableList": DownStreamTableList, "UseCaseName": UseCaseName})

            else:
                DownStreamTableList = row['downstreamtable_list']
                UseCaseName = row['usecase_name']
                failure.append({"DownStreamTableList": DownStreamTableList, "UseCaseName": UseCaseName})
                
        success_df = pd.DataFrame(data = success , columns = ['DownStreamTableList', 'UseCaseName'])
        failure_df = pd.DataFrame(data = failure , columns = ['DownStreamTableList', 'UseCaseName'])
        
        if downstream.shape[0] == success_df.shape[0]:
            success_df = pd.merge(success_df, sa_push, left_on="DownStreamTableList", right_on="object_name").drop('DownStreamTableList', axis=1)
            log = success_df[['UseCaseName', 'object_name', 'number_of_recs_processed']]
            write_data_to_csv_on_s3(log, "monitoring-logs/Success_{}.csv".format(rundate), bucket)
            usecase = ', '.join(log.UseCaseName.unique())
            subject = "[AMAP][{}] - ETL Pipeline sucessfully completed [{}]" .format(env, today)
            message = "Hi All,\n \nETL Pipeline for day {} executed sucessfully for usecase {}.\n \nPlease find below the S3 location for the detailed report. \nS3 Path - s3://{}/monitoring-logs/Success_{}.csv\n \nRegards,\nAMAP DM Team".format(today, usecase, bucket, rundate)
            trigger_sns(subject, message)
            
        else:
            task_details = data_extract('airflow','task_fail')
            task_details = task_details[task_details['start_date'] == max(task_details['start_date'])].filter(task_details[['task_id', 'dag_id']])
            group = task_details.iloc[0]['task_id'].split('.')[0]
            dag_id = task_details.iloc[0]['dag_id']
            failure_df[['group', 'dag_id']] = [group,dag_id]
            usecase = ', '.join(failure_df.UseCaseName.unique())
            write_data_to_csv_on_s3(failure_df, "monitoring-logs/Failure_{}.csv".format(rundate), bucket)
            subject = "[AMAP][{}] - ETL Pipeline Failed [{}]" .format(env, today)
            message = "Hi All,\n \nETL Pipeline for day {} failed for usecase {}. Kindly check '{}' group from '{}' Dag.\n \nPlease find below the S3 path for the detailed report.\nS3 Path - s3://{}/monitoring-logs/Failure_{}.csv\n \nRegards,\nAMAP DM Team".format(today, usecase, group, dag_id, bucket, rundate)
            trigger_sns(subject, message)
            sumologic_log(subject, message)
            
    except Exception as e:
        logger.error("Monitoring Log Failed : {}".format(e))
