# Airflow General
from airflow import DAG
from datetime import timedelta
import pendulum
from airflow.utils.dates import days_ago

# EMR
from airflow.providers.amazon.aws.operators.emr import EmrTerminateJobFlowOperator

# Mysql
from airflow.providers.mysql.hooks.mysql import MySqlHook

# Airflow operators
from airflow.operators.python import BranchPythonOperator
from airflow.operators.python import PythonOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.providers.http.hooks.http import HttpHook

# Core Imports
import yaml


# Support Functions
def import_config(path: str) -> dict:
    with open(path, "r") as ymlfile:
        cfg = yaml.load(ymlfile.read(), Loader=yaml.SafeLoader) or {}

    return cfg

def check_cluster() -> str:
    try:
        response = HttpHook(http_conn_id="my_livy_http", method="GET").run(endpoint="batches/")
        print(response)
        # if i can connect the cluster exists
        return 'cluster_id'
    except:
        # if i cannot it does not exist
        print('The Cluster does not exist')
        return 'cluster_not_exists'

def get_cluster_id() -> str:
    mysql_hook = MySqlHook(mysql_conn_id="airflow_db")
    record = mysql_hook.get_records(sql='SELECT value FROM xcom WHERE dag_id = "AWS_Cluster_Create" AND task_id = "create_job_flow" ORDER BY timestamp DESC LIMIT 1')

    return record[0][0].decode("utf-8").replace('"','')

# Some Variables
default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": days_ago(1),
    "email": ["airflow@airflow.com"],
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    'catchup': False,
    "retry_delay": timedelta(minutes=2),
}

template_searchpath = [
    "scripts/cluster"
]

# ======== DAG ========
with DAG('AWS_Cluster_Terminate', default_args=default_args, schedule_interval=None, tags=['Infra'], template_searchpath=template_searchpath, max_active_runs=1) as dag:

    # Check if the cluster exists
    check_cluster_exists = BranchPythonOperator(
        task_id = 'check_cluster',
        python_callable = check_cluster
    )

    # Get Cluster id
    cluster_id = PythonOperator(
        task_id = 'cluster_id',
        python_callable = get_cluster_id
    )

    # Terminate the cluster
    cluster_remover = EmrTerminateJobFlowOperator(
        task_id = 'remove_cluster',
        job_flow_id = "{{ task_instance.xcom_pull(task_ids='cluster_id', key='return_value') }}",
        aws_conn_id = 'my_aws'
    )

    # Nothing to do
    cluster_not_exists = DummyOperator(
        task_id = 'cluster_not_exists',
        trigger_rule = 'none_failed'
    )

    check_cluster_exists >> [cluster_id, cluster_not_exists]
    cluster_id >> cluster_remover

# EOF
