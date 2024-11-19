# Airflow General
from airflow import DAG
from datetime import timedelta
import pendulum
from airflow.utils.dates import days_ago
from airflow.utils.task_group import TaskGroup

# HTTP/s
from airflow.providers.http.hooks.http import HttpHook
from airflow.providers.http.operators.http import SimpleHttpOperator

# Airflow operators
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.operators.python import PythonOperator

# Livy
from airflow.providers.apache.livy.operators.livy import LivyOperator
from airflow.hooks.base import BaseHook

# SSH
from airflow.providers.ssh.operators.ssh import SSHOperator
from airflow.providers.sftp.operators.sftp import SFTPOperator

# Custom operator
from scripts.model_manager.sftp_get_multiple_files_operator import SFTPBatchOperator

# Core Imports
import os
import copy
from time import sleep
import yaml
#import binpacking
from itertools import chain, repeat


# Support Functions
def import_config(path: str) -> dict:
    with open(path, "r") as ymlfile:
        cfg = yaml.load(ymlfile.read(), Loader=yaml.SafeLoader) or {}

    return cfg


'''
def bin_groups(groups: dict, reduction_factor: int, is_list: bool = False, val_pos: int = None) -> list:
    sort_dict = {}
    if is_list:
        for id in groups.keys():
            sort_dict[id] = groups[id][val_pos]

    bins = sorted(binpacking.to_constant_volume(sort_dict, sum(
        sort_dict.values()) / (reduction_factor + 1)), key=len, reverse=True)

    return [list(chain(i, repeat(None, times=len(bins[0])-len(i)))) for i in bins]
'''


def generate_model_input(dag_conf: dict, foldername: str, remove: list, mysql_conn=None) -> list:
    # Remove columns from dict
    model_vars = copy.deepcopy(dag_conf['Direct'][foldername])
    for key in remove:
        model_vars.pop(key, None)

    # Adding end_date
    variables = list(model_vars.values())
    variables.append(eval(dag_conf['Tables']['ENDDATE']))

    if mysql_conn:
        variables.append(mysql_conn.host)
        variables.append(mysql_conn.login)
        variables.append(mysql_conn.password)
        variables.append(mysql_conn.port)

    return variables


def mm_sensor(http_conn_id: str, endpoint: str, run_id: str, poke_interval=60, **kargs) -> bool:
    # Possible statuses: NOT_STARTED, RUNNING, ERROR, SUCCESS, NOT_EXECUTED
    while True:
        try:
            # Check status of the run
            response = HttpHook(http_conn_id=http_conn_id, method="GET").run(
                endpoint=endpoint.format(run_id))
            response = response.json()

            # If it went well return
            if "SUCCESS" in response["run_status"]:
                return response["run_status"]

            # If not fail badly
            elif "ERROR" in response["run_status"]:
                print(response)
                exit(1)

        except Exception as e:
            print(e)
            exit(1)

        # Sleep between each cycle
        print('Poking - status: {}'.format(response["run_status"]))
        sleep(poke_interval)


# Some Variables
default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": days_ago(1),
    "email": ["airflow@airflow.com"],
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 0,
    'catchup': False,
    "retry_delay": timedelta(minutes=1),
}

template_searchpath = [
    "scripts/model_manager"
]

# Load DAG Configurations
ROOT_PATH = "/opt/airflow/dags"
dag_conf = import_config(ROOT_PATH + '/scripts/model_manager/variables.yaml')
dag_conf_aws = import_config(ROOT_PATH + '/scripts/batch/variables.yaml')
mysql_conn = BaseHook.get_connection(conn_id="my_mysql")


# ======== DAG ========
def create_ml_dag(case_name: str, model_foldernames: list, tags: list = None, training = False):
    if not tags:
        tags = []
    tags.append('ML_Model')
    dag = DAG(case_name, default_args=default_args, schedule_interval=None,
              tags=["Model_Manager"] if dag_conf["DAG"]["model_manager"] else tags,
              template_searchpath=template_searchpath)
    with dag:
        # Create Hive Cluster
        create_cluster = TriggerDagRunOperator(
            task_id='create_cluster',
            trigger_dag_id=f"{dag_conf['DAG']['ENV'].upper()}_Cluster_Create",
            wait_for_completion=True,
            poke_interval=30
        )

        if dag_conf["DAG"]["model_manager"]:
            # Trigger the execution of the pipelines
            with TaskGroup("Run", tooltip="Trigger execution") as trigger_run:
                for pipe in dag_conf['Pipelines']:
                    values = list(pipe.values())[0]
                    run_pipeline = SimpleHttpOperator(
                        task_id='run_{}'.format(list(pipe.keys())[0]),
                        http_conn_id=dag_conf['Connection'],
                        endpoint=dag_conf['Endpoints']['RUN'],
                        method='POST',
                        data='"pipeline": { "pipeline_id": {{ values["pipeline_id"] }}, "version_id":{{ values["version_id"] }} }'
                    )

            # Wait for the pipelines to finish
            with TaskGroup("Wait", tooltip="Wait execution") as wait_run:
                for pipe in dag_conf['Pipelines']:
                    name = list(pipe.keys())[0]
                    task = PythonOperator(
                        task_id='wait_{}'.format(name),
                        python_callable=mm_sensor,
                        op_kwargs={
                            'http_conn_id': dag_conf['Connection'],
                            'endpoint': dag_conf['Endpoints']['WAIT'],
                            'run_id': "{{ task_instance.xcom_pull(task_ids = 'Run.run_' + {{ name }}, key = 'return_value') }}",
                            'poke_interval': 60
                        }
                    )

            # Order
            create_cluster >> trigger_run >> wait_run

        else:
            foldernames = os.listdir(dag_conf['DAG']['FILE_PATH'])

            # Move folders
            with TaskGroup("Preparation", tooltip="Prepare model files") as prep_section:

                for foldername in foldernames:
                    name_prefix: str = foldername.split('_')[0]
                    config: dict = dag_conf['Direct'][name_prefix]

                    if config['active'] and foldername in model_foldernames:
                        copy_to_machine = SFTPBatchOperator(
                            task_id='copy_{}'.format(foldername),
                            ssh_conn_id='my_emr_ssh',
                            local_folder=dag_conf['DAG']['FILE_PATH'] +
                            '/' + foldername + '/',
                            remote_folder='/tmp/' + foldername + '/',
                            regexp_mask=".*",
                            create_intermediate_dirs=True
                        )

                        copy_to_hdfs = SSHOperator(
                            task_id='copy_hdfs_{}'.format(foldername),
                            ssh_conn_id='my_emr_ssh',
                            command='hadoop fs -put -f /tmp/{} /tmp'.format(
                                foldername)
                        )
                        if config['trained'] and training == False :

                            copy_s3_files  = SSHOperator(
                            task_id='copy_s3_to_emr_{}'.format(foldername),
                            ssh_conn_id = 'my_emr_ssh',
                            command = 'aws s3 sync s3://{}/{}/{}/ /tmp/{}/saved_model/'.format(dag_conf_aws['Environment']['BUCKET_NAME'],dag_conf['DAG']['MLModels'],foldername,foldername),
                            )

                            copy_s3_files >> copy_to_machine >> copy_to_hdfs

                        copy_to_machine >> copy_to_hdfs

                foldername = 'Libraries'
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

            with TaskGroup("Run", tooltip="Run model files") as run_section:

                models = {}
                for foldername in foldernames:
                    name_prefix: str = foldername.split('_')[0]
                    config: dict = dag_conf['Direct'][name_prefix]

                    # Check if model is Active
                    if config['active'] and foldername in model_foldernames:
                        # Read Variables
                        variables = generate_model_input(dag_conf, foldername.split(
                            '_')[0], ['active', 'engine', 'weight', 'trained' ], mysql_conn)
                        
                        if training == False:
                            variables.append('scoring')
                        else:
                            variables.append('training')
                        # Check the type
                        if config['engine'] == 'pyspark':
                            py_files: list = ['/tmp/{}/{}'.format(foldername, filename) for filename in os.listdir(
                                dag_conf['DAG']['FILE_PATH']+"/" + foldername) if filename != "main.py"]
                            py_files.append('/tmp/Libraries/*')
                            run_model = LivyOperator(
                                task_id='run_{}'.format(foldername),
                                livy_conn_id='my_livy',
                                proxy_user='hadoop',
                                #driver_memory='1g',
                                #executor_memory='1g',
                                file='/tmp/{}/main.py'.format(foldername),
                                py_files=py_files,
                                args=variables,
                                polling_interval=60,
                                conf={
                                    "spark.sql.sources.partitionOverwriteMode": "dynamic"
                                }
                            )

                        elif config['engine'] == 'python':
                            run_model = SSHOperator(
                                task_id='run_{}'.format(foldername),
                                ssh_conn_id='my_emr_ssh',
                                command='cd /tmp/{foldername} && python3 main.py {args}'.format(
                                    foldername=foldername, args=variables)
                            )

                        # Add model and weight to the list
                        models[foldername] = [run_model, config['weight']]

            if training == True:
                with TaskGroup("Conclusion", tooltip="Conclude model files") as conc_section:
                    for foldername in foldernames:
                        name_prefix: str = foldername.split('_')[0]
                        config: dict = dag_conf['Direct'][name_prefix]

                # Check if model is Active
                        if config['active'] and foldername in model_foldernames and config['trained'] :

                            copy_model = SSHOperator(
                                task_id='copy_emr_to_s3_{}'.format(foldername),
                                ssh_conn_id='my_emr_ssh',
                                command='aws s3 sync /tmp/{}/saved_model/ s3://{}/{}/{}/ --exact-timestamps'.format(foldername,dag_conf_aws['Environment']['BUCKET_NAME'],dag_conf['DAG']['MLModels'],foldername)
                            )

                            backup_model = SSHOperator(
                                task_id='copy_emr_to_s3_backup{}'.format(foldername),
                                ssh_conn_id='my_emr_ssh',
                                command='aws s3 sync /tmp/{}/saved_model/ s3://{}/{}/backup/{}/{}/ --exact-timestamps'.format(foldername,dag_conf_aws['Environment']['BUCKET_NAME'],dag_conf['DAG']['MLModels'],foldername,eval(dag_conf['Tables']['ENDDATE']))
                            )


                            backup_model >>  copy_model
        """
        # Bin tasks to reduce parallelism
                bins = bin_groups(
                    models, dag_conf['DAG']['MODELS_REDUCTION'], True, 1)
                for j in range(len(bins[0])):
                    for i in range(len(bins)-1):
                        try:
                            models.get(bins[i][j])[0] >> models.get(
                                bins[i+1][j])[0]
                        except:
                            pass
        
        """


        # Order of the groups
        if training == True:
             create_cluster >> prep_section >> run_section >> conc_section
        else:
            create_cluster >> prep_section >> run_section

    return dag

# EOF
