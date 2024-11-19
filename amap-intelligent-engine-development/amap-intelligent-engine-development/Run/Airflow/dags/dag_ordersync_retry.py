from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.hooks.base import BaseHook
from airflow.utils.dates import days_ago
from airflow.providers.mysql.hooks.mysql import MySqlHook
import json
import requests
import time
from datetime import timedelta,datetime



def get_credentials():
    api_conn = BaseHook.get_connection('my_api_http_conn')  # Use the connection ID from Airflow
    extra = json.loads(api_conn.extra)  # Parse the JSON stored in the "Extra" field

    conn_data = {}
    conn_data["api_client_id"] = extra.get('client_id')
    conn_data["api_password"] = api_conn.get_password()
    conn_data["api_username"] = api_conn.login
    conn_data["api_host"] = api_conn.host
    conn_data["ordersync_endpoint"] =  extra.get('ordersync_endpoint')
    conn_data["keycloak_endpoint"] =  extra.get('keycloak_endpoint')
    
    return conn_data
    

def get_token(conn_data):
    
    if  not conn_data:
        conn_data =  get_credentials()
   

    params = {
        "client_id": conn_data["api_client_id"],
        "username":  conn_data["api_username"],
        "password": conn_data["api_password"],
        "grant_type": "password"
    }
    
    
    # HTTP POST request to get the bearer token
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    response = requests.post(f"{conn_data['api_host']}{conn_data['keycloak_endpoint']}", headers=headers, data=params)
    
  
    response.raise_for_status()  # Raise an error if the request failed
    response_data = response.json()


    if "access_token" in response_data:
        token = response_data['access_token']
        # Store the token in XCom for use in subsequent tasks
    else:
        raise ValueError("Bearer token not found in response")
    
    return token


def process_api_records():
   
   
    conn_data =  get_credentials()
   
    mysql_hook = MySqlHook(mysql_conn_id='my_mysql')  # MySQL connection ID from Airflow
    query = "SELECT id, message, status, \
                    market_order_id, market_order_details_id \
               FROM api_order_message_queue \
              WHERE (attempt_count < max_attempts or max_attempts < 10 ) \
                AND (status = 'ERROR' OR (status in ('NEW', 'IN_PROGRESS') and update_datetime <  NOW() - INTERVAL 5 HOUR ) )  \
            ORDER BY cast(id as SIGNED) LIMIT 50" 
             
    records = mysql_hook.get_records(query)

   

    

    # Process each record one by one
    for record in records:
        
        record_id = record[0]  #  First column is the record ID
        market_order_details_id = record[4]
        market_order_id = record[3]
        print(f"Processing record {record_id}")
        ordersync_payload = json.loads(record[1])  
        # put the message id indide the payload
        ordersync_payload["line"][0]["queueId"] = record_id # there is always one line in the message
        
        mysql_hook.run(sql= f"UPDATE api_order_message_queue set max_attempts = greatest(max_attempts,least(attempt_count + 5,10 )), update_datetime=NOW() where id = {record_id}")
        mysql_hook.run(sql= f"UPDATE api_order_process_state set status = 'ERROR'  WHERE market_order_details_id = '{market_order_details_id}' and  market_order_id = '{market_order_id}'")

        headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {get_token(conn_data)} "  # Use the retrieved  token
        }
        
        # Make the POST request with the JSON message as payload
        response = requests.put(f"{conn_data['api_host'] }{ conn_data['ordersync_endpoint'] }", headers=headers, data = json.dumps(ordersync_payload))

        # Check the API response status
        if response.status_code == 200:
            print(f"Successfully sent request for record {record_id}")

            # wait for the record status to change to 'COMPLETED'
            wait_for_api(mysql_hook, record_id)
        else:
            print(f"Failed to process record {record_id}, status code: {response.status_code} , message: {response.reason} ")


def wait_for_api(mysql_hook, record_id, max_wait_time=300, check_interval=10):
    """
    Wait for the record status to change to 'COMPLETED'.
    """
    start_time = time.time()
    
    while (time.time() - start_time) < max_wait_time:
        # Query the current status of the record
        status = mysql_hook.get_first(f"SELECT status FROM api_order_message_queue WHERE id = {record_id}")[0]

        # Check if the status has changed to 'COMPLETED'
        
        if status  in ('COMPLETED'):
            print(f"Record {record_id} has been marked as 'COMPLETED'. Proceeding to the next record.")
            return 0
        
        if status  in 'ERROR':
            print(f"Record {record_id} has been marked as 'ERROR'. Restarting from begigning.")
            return  1

        # If the status is not 'COMPLETED', wait for a while before checking again
        print(f"Waiting for record {record_id} to be marked as 'COMPLETED'... Checking again in {check_interval} seconds.")
        time.sleep(check_interval)
    
    print(f"Record {record_id} was not marked as 'COMPLETED' within the given time limit.") 
    return  1

# DAG Definition
with DAG( dag_id='API_OrderSync_Retry',  schedule_interval = timedelta(minutes=10) ,   max_active_runs = 1, 
            default_args = {
            "retries": 2,
            'start_date': datetime(2024, 1, 1),
            'retry_delay': timedelta(minutes=1)
            },
            catchup = False
) as dag:
    process_data = PythonOperator(
            task_id='process_api_records',
            python_callable=process_api_records
        )

    process_data
