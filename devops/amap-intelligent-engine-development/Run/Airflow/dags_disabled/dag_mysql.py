# Airflow General
from airflow import DAG
from datetime import timedelta
import pendulum
from airflow.utils.dates import days_ago
from airflow.utils.task_group import TaskGroup

# Hive
from airflow.providers.apache.hive.operators.hive import HiveOperator
from airflow.providers.apache.hive.transfers.hive_to_mysql import HiveToMySqlOperator

# Mysql
from airflow.providers.mysql.operators.mysql import MySqlOperator

# Livy
from airflow.providers.apache.livy.operators.livy import LivyOperator

# SSH
from airflow.providers.ssh.operators.ssh import SSHOperator
from airflow.providers.sftp.operators.sftp import SFTPOperator

# Airflow operators
from airflow.operators.trigger_dagrun import TriggerDagRunOperator

# Core Imports
import os
import yaml
import json


# Support Functions
def import_config(path: str) -> dict:
    with open(path, "r") as ymlfile:
        cfg = yaml.load(ymlfile.read(), Loader=yaml.SafeLoader) or {}

    return cfg


# Load DAG Configurations
ROOT_PATH="/opt/airflow/dags"
dag_conf = import_config(ROOT_PATH + '/scripts/installation/variables.yaml')

# Evaluate configs
for i in dag_conf['Tables'].keys():
    dag_conf['Tables'][i] = eval(dag_conf['Tables'][i])

# Some Variables
default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": days_ago(1),
    "email": ["airflow@airflow.com"],
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    'catchup': False,
    "retry_delay": timedelta(minutes=2),
}

template_searchpath = [
    dag_conf['DAG']['MYSQL_PATH'] + '/MysqlCreation'
]

# ======== DAG ========
with DAG('MySQL_Tables_Installation', default_args=default_args, schedule_interval=None, tags=['Infra'], template_searchpath=template_searchpath) as dag:


    ## Create DB Tables
    groups = {}
    with TaskGroup("Creation", tooltip="Create DB Tables") as create_section:
        for id in set([i.split('_')[0] for i in os.listdir(dag_conf['DAG']['MYSQL_PATH'] + '/MysqlCreation')]):
            groups[id] = TaskGroup(id, tooltip="Create {} Tables".format(id))

        for filename in os.listdir(dag_conf['DAG']['MYSQL_PATH'] + "/MysqlCreation"):
            run_mysql = MySqlOperator(
                    task_group=groups[filename.split('_')[0]],
                    task_id='create_{}'.format(filename[0:-4]),
                    mysql_conn_id='my_mysql',
                    sql=filename
                    )
        # Since there are too many levels we need to reduce parallelism
        REDUCTION_FACTOR = 3
        key = list(groups.keys())
        key.sort(key=str.lower)
        for k in range(0, len(groups), REDUCTION_FACTOR):
            now = key[k:k+REDUCTION_FACTOR]
            for i in range(len(now)-1):
                groups[now[i]] >> groups[now[i+1]]












   

    ## Terminate EMR
    #terminate_cluster = TriggerDagRunOperator (
    #    task_id='terminate_cluster',
    #    trigger_dag_id="{}_terminate_cluster".format(dag_conf['Environment']['NAME'].lower()),
    #    wait_for_completion= True,
    #    poke_interval= 60
    #)

    # Create flow
    #
    #create_cluster >> create_section 
    #>> prep_section >> ingest_section >> agg_section >> seg_section >> mig_section #>> terminate_cluster

