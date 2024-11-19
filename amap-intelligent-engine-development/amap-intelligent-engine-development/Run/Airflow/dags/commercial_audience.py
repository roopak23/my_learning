# Airflow General
from airflow import DAG
from datetime import timedelta
from airflow.utils.task_group import TaskGroup
from airflow.models import Variable
import pendulum
import os
import yaml

from airflow.operators.empty import EmptyOperator

# Livy
from airflow.providers.apache.livy.operators.livy import LivyOperator

# SSH
from airflow.providers.ssh.operators.ssh import SSHOperator

# Airflow operators
from airflow.operators.trigger_dagrun import TriggerDagRunOperator

# Custom operator
from scripts.model_manager.sftp_get_multiple_files_operator import SFTPBatchOperator

# Some Variables
default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": pendulum.datetime(2020, 1, 1),
    "email": ["airflow@airflow.com"],
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 0,
    'catchup': False,
    "retry_delay": timedelta(minutes=2),
}
# Support Functions
def import_config(path: str) -> dict:
    with open(path, "r") as ymlfile:
        cfg = yaml.load(ymlfile.read(), Loader=yaml.SafeLoader) or {}

    return cfg


# Load DAG Configurations
ROOT_PATH = "/opt/airflow/dags"
dag_conf = import_config(ROOT_PATH + '/scripts/batch/variables.yaml')

# ======== DAG ========
with DAG('Commercial_Audience', default_args=default_args, schedule_interval=None, tags=['Commercial_Audience'], template_searchpath=[], max_active_runs=1) as dag:

    start = EmptyOperator(task_id='Start')
    
    # Create Hive Cluster
    create_cluster = TriggerDagRunOperator(
        task_id='Create_Cluster',
        trigger_dag_id="{}_Cluster_Create".format(
            dag_conf['Environment']['NAME'].upper()),
        wait_for_completion=True,
        poke_interval=60
    )
    
    with TaskGroup("Preparation") as preparation_steps:
        
        copy_to_machine = SFTPBatchOperator(
            task_id='copy_to_machine',
            ssh_conn_id='my_emr_ssh',
            local_folder=dag_conf['DAG']['FILE_PATH'] + '/Commercial_audience/',
            remote_folder=f"/tmp/Commercial_audience/",
            create_intermediate_dirs=True
        )
    
    with TaskGroup("Execution", tooltip="Run Data Extraction Script") as execution_steps:
        url = Variable.get('url')
        source_bucket = Variable.get('source_bucket')
        client_id = Variable.get('client_id')
        client_secret = Variable.get('client_secret')
        client_name = Variable.get('client_name')
        version = Variable.get('version') 
        run_script = SSHOperator(
            task_id='Execute_Script',
            ssh_conn_id='my_emr_ssh',
            command='python3 /tmp/Commercial_audience/commercial_audience_exec.py  {} {} {} {} {} {}'.format(url,source_bucket,client_id,client_secret,client_name,version),
            cmd_timeout = 60*20
        )

    stop = EmptyOperator(task_id='Stop', trigger_rule='none_failed')

    start >> create_cluster >> preparation_steps >> execution_steps >> stop
# EOF
