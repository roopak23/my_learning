# Airflow General
from airflow import DAG
from datetime import timedelta
import pendulum
from airflow.utils.dates import days_ago
from airflow.utils.task_group import TaskGroup

# EMR
from airflow.providers.amazon.aws.operators.emr import EmrCreateJobFlowOperator
from airflow.providers.amazon.aws.sensors.emr import EmrJobFlowSensor

# Airflow operators
from airflow.operators.python import BranchPythonOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.providers.http.hooks.http import HttpHook
from airflow.providers.ssh.operators.ssh import SSHOperator
from scripts.model_manager.sftp_get_multiple_files_operator import SFTPBatchOperator

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
        return 'cluster_exists'
    except:
        # if i cannot it does not exist
        print('The Cluster does not exist')
        return 'create_job_flow'

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

ROOT_PATH="/opt/airflow/dags"

# ======== DAG ========
with DAG('AWS_Cluster_Create', default_args=default_args, schedule_interval=None, tags=['Infra'], template_searchpath=template_searchpath, max_active_runs=1) as dag:

    # Check if the cluster exists
    check_cluster_exists = BranchPythonOperator(
        task_id='check_cluster',
        python_callable=check_cluster
    )

    # Create Hive Cluster
    create_job_flow = EmrCreateJobFlowOperator(
        task_id='create_job_flow',
        job_flow_overrides=import_config(ROOT_PATH + '/scripts/cluster/aws_cluster_template.yaml'),
        aws_conn_id='my_aws',
        emr_conn_id='emr_default' # Just a dummy value, the JOB_FLOW_OVERRIDES will be used
    )

    # Check Cluster readiness
    cluster_ready = EmrJobFlowSensor(
        task_id='wait_job_flow',
        job_flow_id="{{ task_instance.xcom_pull(task_ids='create_job_flow', key='return_value') }}",
        target_states=['WAITING'],
        aws_conn_id='my_aws'
    )

    cluster_exists = DummyOperator(
        task_id = 'cluster_exists',
        trigger_rule = 'none_failed'
    )

    foldername = 'Libraries'
    with TaskGroup("preparation", tooltip=f"Prepare {foldername} files") as prep_section:
        copy_libraries_to_machine = SFTPBatchOperator(
            task_id=f'copy_{foldername}',
            ssh_conn_id='my_emr_ssh',
            local_folder=f'/opt/airflow/dags/Spark/Batch/{foldername}',
            remote_folder=f'/tmp/{foldername}/',
            regexp_mask=".*.py",
            create_intermediate_dirs=True
        )

        copy_libraries_to_hdfs = SSHOperator(
            task_id=f'copy_hdfs_{foldername}',
            ssh_conn_id='my_emr_ssh',
            command=f'hadoop fs -put -f /tmp/{foldername} /tmp/'
        )

        copy_libraries_to_machine >> copy_libraries_to_hdfs


    # Order
    create_job_flow >> cluster_ready >> prep_section >> cluster_exists
    check_cluster_exists >> [create_job_flow, cluster_exists]


# EOF