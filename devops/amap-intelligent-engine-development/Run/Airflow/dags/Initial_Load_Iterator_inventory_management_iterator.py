from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.operators.dagrun_operator import TriggerDagRunOperator
from airflow.utils.dates import days_ago
from airflow.models.param import Param
from datetime import datetime, timedelta, date

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': days_ago(1), 
}

with DAG(
    dag_id="Initial_Load_Iterator_inventory_management",
    default_args=default_args,
    schedule_interval=None,  
    catchup=False,
) as dag:
    
        dag_name = 'Inventory_Management_Initial_Load'
        start_date_dt = date.today() - timedelta(days=32)
        end_date_dt = date.today() - timedelta(days=1)
        
     
        tasks = []
        current_date = start_date_dt
    
        while current_date <= end_date_dt:
            task = TriggerDagRunOperator(
                task_id=f'{dag_name}_{current_date.strftime("%Y_%m_%d")}',
                trigger_dag_id= dag_name,
                conf={'ENDDATE': current_date.strftime("%Y%m%d")},
                wait_for_completion = True,
                dag = dag   
            )
            tasks.append(task)
            current_date += timedelta(days=1)

        for i in range(len(tasks) - 1):
            tasks[i] >> tasks[i + 1]
   