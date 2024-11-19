# Airflow General
from airflow import DAG
from datetime import timedelta
from airflow.utils.task_group import TaskGroup
from airflow.hooks.base import BaseHook
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
with DAG('Backend_Override_Utility', default_args=default_args, schedule_interval='45 20 * * *', tags=['Backend_Override_Utility'], template_searchpath=[], max_active_runs=1,catchup =  False) as dag:

    start = EmptyOperator(task_id='Start')

    import yaml

    def import_config(path: str) -> dict:
        with open(path, "r") as ymlfile:
            cfg = yaml.load(ymlfile.read(), Loader=yaml.SafeLoader) or {}
        return cfg

    config_yaml_name = "variables.yaml"
    ROOT_PATH = "/opt/airflow/dags"
    DAG_CONFIG = import_config(ROOT_PATH + '/scripts/batch/variables.yaml')
    PIPELINES_DIR = ROOT_PATH + '/scripts/batch/'
    pipeline_config = import_config(f'{PIPELINES_DIR}/{config_yaml_name}')
    pipeline_config = {**DAG_CONFIG, **pipeline_config}
    bucket_name = pipeline_config['Environment']['BUCKET_NAME']
    
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
            local_folder=dag_conf['DAG']['FILE_PATH'] + '/Backend_Override_Utility/',
            remote_folder=f"/tmp/Backend_Override_Utility/",
            create_intermediate_dirs=True
        )
    
    with TaskGroup("Execution", tooltip="Run Data Extraction Script") as execution_steps:
    
        mysql_conn = BaseHook.get_connection(conn_id="my_mysql")
        host = mysql_conn.host
        login = mysql_conn.login
        password = mysql_conn.password

        run_script = SSHOperator(
            task_id='Execute_Script',
            ssh_conn_id='my_emr_ssh',
            command='python3 /tmp/Backend_Override_Utility/Backend_Override_Utility_exec.py {} {} {} {} '.format(host,login,password,bucket_name),
            cmd_timeout = 60*1200
        )

    stop = EmptyOperator(task_id='Stop', trigger_rule='none_failed')

    start >> create_cluster >> preparation_steps >> execution_steps >> stop
# EOF
