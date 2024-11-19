# Airflow General
from airflow import DAG
from datetime import timedelta

from airflow.exceptions import AirflowSkipException
from airflow.utils.task_group import TaskGroup
from airflow.hooks.base import BaseHook
from airflow.models import Variable
from airflow.models.param import Param

# Hive
from airflow.providers.apache.hive.operators.hive import HiveOperator
from airflow.providers.apache.hive.transfers.hive_to_mysql import HiveToMySqlOperator

# Mysql
from airflow.providers.mysql.operators.mysql import MySqlOperator

# Livy
from airflow.providers.apache.livy.operators.livy import LivyOperator

# SSH
from airflow.providers.ssh.operators.ssh import SSHOperator

# Airflow operators
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.operators.empty import EmptyOperator
from airflow.providers.amazon.aws.sensors.s3 import S3KeySensor
# Custom operator
from scripts.model_manager.sftp_get_multiple_files_operator import SFTPBatchOperator

# Core Imports
import pendulum
import yaml
import json

"""
Variables which can be added in Airflow UI Admin/Variables
     skip_trigger_create: str = true  <= skips Cluster_Create task instantly.
     skip_trigger_terminate: str = true <= skips Cluster_Terminate task instantly.
     skip_models: str = true <= skips task which triggers model pipeline instantly.
     skip_w4f: str = true <= skips specific w4f task on timeout.
 """


# Support Functions
class TriggerDagRunOperatorWithSkip(TriggerDagRunOperator):
    def __init__(self, *, skip: bool = False, **kwargs, ) -> None:
        super().__init__(**kwargs)
        self.skip: bool = skip

    def execute(self, context):
        if self.skip:
            raise AirflowSkipException
        super().execute(context)


def import_config(path: str) -> dict:
    with open(path, "r") as ymlfile:
        cfg = yaml.load(ymlfile.read(), Loader=yaml.SafeLoader) or {}
    return cfg


# Load DAG standard configurations
ROOT_PATH = "/opt/airflow/dags"
DAG_CONFIG = import_config(ROOT_PATH + '/scripts/batch/variables.yaml')
PIPELINES_DIR = ROOT_PATH + '/scripts/batch/pipelines'
mysql_conn = BaseHook.get_connection(conn_id="my_mysql")

# Some Variables
DEFAULT_ARGS = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": pendulum.datetime(2020, 1, 1),
    "email": ["airflow@airflow.com"],
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    'catchup': False,
    "retry_delay": timedelta(minutes=2),
}


# DAG
def create_dag(config_yaml_name):
    # Variables
    pipeline_config = import_config(f'{PIPELINES_DIR}/{config_yaml_name}')
    pipeline_config = {**DAG_CONFIG, **pipeline_config}

    for i in pipeline_config['Tables'].keys():
        pipeline_config['Tables'][i] = Variable.get(i, eval(str(pipeline_config['Tables'][i])))

    batch_dir = pipeline_config['DAG']['FILE_PATH']
    installation_path: str = pipeline_config['DAG']['INSTALLATION_PATH']
    
    creation_dir = batch_dir + '/Creation'
    ingestion_dir = batch_dir + '/Ingestion'
    aggregation_dir = batch_dir + '/Aggregation'
    migration_dir = batch_dir + '/Migration'
    execution_dir = batch_dir + '/Execution'
    libraries_dir = batch_dir + '/Libraries'
    mysql_creation_path = installation_path + '/MysqlCreation'
    
    template_searchpath = [
        creation_dir,
        ingestion_dir,
        aggregation_dir,
        migration_dir,
        execution_dir,
        libraries_dir,
        mysql_creation_path
    ]
    pipeline_steps = [step.lower() for step in pipeline_config['Steps'].keys()]
    end_date = pipeline_config['Tables']['ENDDATE']
    tags = pipeline_config.get('Tags', ['DEV'])
    skip_models: bool = True if str(Variable.get('skip_models', 'false')).lower() == 'true' else False

    dag = DAG(pipeline_config['Name'], 
              default_args=DEFAULT_ARGS, 
              schedule_interval=None, 
              tags=tags,
              params={"ENDDATE": Param(type="string", default=end_date,minimum=20000101,maximum=21001231,description="ENDDATE")},
              template_searchpath=template_searchpath)

    with dag:
        # Ordinal operators
        start = EmptyOperator(task_id='Start')
        end = EmptyOperator(task_id='End')

        end_date= "{{ params.ENDDATE }}"
        
        # Hive cluster
        if 'create_cluster' in pipeline_steps:
            skip_trigger_create: bool = True if str(
                Variable.get('skip_trigger_create', 'false')).lower() == 'true' else False
            create_cluster = TriggerDagRunOperatorWithSkip(
                task_id='Create_Cluster',
                trigger_dag_id=f"{pipeline_config['Environment']['NAME'].upper()}_Cluster_Create",
                wait_for_completion=True,
                poke_interval=60,
                skip=skip_trigger_create
            )

        if 'terminate_cluster' in pipeline_steps:
            skip_trigger_terminate: bool = True if str(
                Variable.get('skip_trigger_terminate', 'false')).lower() == 'true' else False
            terminate_cluster = TriggerDagRunOperatorWithSkip(
                task_id='Terminate_Cluster',
                trigger_dag_id=f"{pipeline_config['Environment']['NAME'].upper()}_Cluster_Terminate",
                wait_for_completion=True,
                poke_interval=60,
                skip=skip_trigger_terminate
            )

        # Create DB tables
        if 'creation' in pipeline_steps:
            with TaskGroup('Creation', tooltip='Create DB Tables') as creation:
                with TaskGroup('Creation_Steps', tooltip='Create DB Tables') as creation_steps:
                    creation_file_list = pipeline_config['Steps']['Creation']['Files']
                    groups = {}

                    for ext_sys_id in set(filename.split('_')[0] for filename in creation_file_list):
                        groups[ext_sys_id] = TaskGroup(ext_sys_id, tooltip=f'Create {ext_sys_id} Tables')

                    for filename in creation_file_list:
                        run_spark = HiveOperator(
                            task_group=groups[filename.split('_')[0]],
                            task_id=f"{filename[:-4]}_create",
                            hql=filename,
                            hive_cli_conn_id='my_hive_cli',
                            hiveconfs={
                                "hive.txn.manager": "org.apache.hadoop.hive.ql.lockmgr.DbTxnManager",
                                "hiveconf hive.support.concurrency": "true",
                                "hive.exec.dynamic.partition.mode": "nonstrict"},
                            params={
                                'HIVE_DATA_PATH': pipeline_config['Environment']['HIVE_DATA_PATH'],
                                'ROOTPATH': pipeline_config['Environment']['BUCKET_NAME'],
                                'TABLEHOST': pipeline_config['Environment']['TABLEHOST']
                            }
                        )

                    groups

                start_creation = EmptyOperator(task_id='Start_Creation', trigger_rule='none_failed')
                end_creation = EmptyOperator(task_id='End_Creation', trigger_rule='none_failed')
                start_creation >> creation_steps >> end_creation

        # Preparation of env
        if 'preparation' in pipeline_steps:
            with TaskGroup("Preparation", tooltip="Prepare EMR for ETL run") as preparation:
                with TaskGroup("Preparation_Steps", tooltip="Prepare EMR for ETL run") as preparation_steps:
                    processes: dict = {"Ingestion": ingestion_dir, "Aggregation": aggregation_dir, "Libraries": libraries_dir}

                    for name, local_dir in processes.items():
                        copy_to_machine = SFTPBatchOperator(
                            task_id=f"Copy_{name}",
                            ssh_conn_id='my_emr_ssh',
                            local_folder=local_dir,
                            remote_folder=f"/tmp/{name}/",
                            regexp_mask=".*.py",
                            create_intermediate_dirs=True
                        )

                        copy_to_hdfs = SSHOperator(
                            task_id=f"Copy_HDFS_{name}",
                            ssh_conn_id='my_emr_ssh',
                            command=f"hadoop fs -put -f /tmp/{name} /tmp/",
                            cmd_timeout = 60
                        )

                        copy_to_machine >> copy_to_hdfs

                start_preparation = EmptyOperator(task_id='Start_Preparation', trigger_rule='none_failed')
                end_preparation = EmptyOperator(task_id='End_Preparation', trigger_rule='none_failed')
                start_preparation >> preparation_steps >> end_preparation

        # Execute additional scripts
        if 'additional_scripts' in pipeline_steps:
            with TaskGroup("Additional_Scripts", tooltip="Run Additional Scripts") as additional_scripts:
                with TaskGroup("Scripts", tooltip="Run Additional Scripts") as scripts:
                    scripts_dict = pipeline_config['Steps']['Additional_Scripts']
                    for code in scripts_dict.keys():
                        exec(scripts_dict[code])

                start_additional_scripts = EmptyOperator(task_id='Start_Additional_Scripts', trigger_rule='none_failed')
                end_additional_scripts = EmptyOperator(task_id='End_Additional_Scripts', trigger_rule='none_failed')
                start_additional_scripts >> scripts >> end_additional_scripts

        # Ingest files
        if 'ingestion' in pipeline_steps:
            with TaskGroup("Ingestion", tooltip="Ingest into Hive") as ingestion:
                with TaskGroup("Ingestion_Steps", tooltip="Ingest into Hive") as ingestion_steps:
                    ingestion_parameters = pipeline_config['Steps']['Ingestion'].get('Parameters', {})
                    ingestion_storage = ingestion_parameters.get('storageName', pipeline_config['Environment']['BUCKET_NAME'])
                    ingestion_file_dir = ingestion_parameters.get('remoteDir', pipeline_config['Environment']['INPUT_FILES_DIR'])
                    rejected_file_dir = ingestion_parameters.get('rejectedFilesDir', pipeline_config['Environment']['REJECTED_FILES_DIR'])
                    ingestion_envname = ingestion_parameters.get('environment', pipeline_config['Environment']['NAME'])

                    ingestion_task_list = pipeline_config['Steps']['Ingestion']['Tasks']
                    groups = {}

                    for ext_sys_id in set(task['task_id'].split('_')[1] for task in ingestion_task_list):
                        groups[ext_sys_id] = TaskGroup(ext_sys_id, tooltip=f"Ingest {ext_sys_id} Tables")

                    for task in ingestion_task_list:
                        import_task = LivyOperator(
                            task_id=task['task_id'] if task['task_id'].endswith(
                                "_ingest") else f"{task['task_id']}_ingest",
                            task_group=groups[task['task_id'].split('_')[1]],
                            livy_conn_id='my_livy',
                            proxy_user='hadoop',
                            driver_memory=Variable.get('emr_spark_driver_memory', default_var='2g'),
                            executor_memory=Variable.get('emr_spark_executor_memory', default_var='2g'),
                            file='/tmp/Ingestion/ingestion.py',
                            py_files=['/tmp/Ingestion/data_quality.py', '/tmp/Libraries/ie_hive_connection.py'],
                            args=[
                                ingestion_storage,
                                f"{ingestion_file_dir}/{end_date}/",
                                ingestion_envname,
                                task['task_id'],
                                json.dumps(task),
                                json.dumps(import_config(f"{ingestion_dir}/Validators/{task['validator']}")),
                                end_date,
                                rejected_file_dir
                            ],
                            polling_interval=60,
                            conf={
                                'spark.sql.sources.partitionOverwriteMode': 'dynamic'
                            }
                        )

                    groups

                start_ingestion = EmptyOperator(task_id='Start_Ingestion', trigger_rule='none_failed')
                end_ingestion = EmptyOperator(task_id='End_Ingestion', trigger_rule='none_failed')
                start_ingestion >> ingestion_steps >> end_ingestion

        # Check if files are on S3
        if 'wait_for_files' in pipeline_steps and 'ingestion' in pipeline_steps:
            with TaskGroup("Wait_4_Files", tooltip="Wait for Files uploaded to S3") as wait_for_files:
                with TaskGroup("W4F_Steps", tooltip="Wait for Files uploaded to S3") as wait_for_files_steps:
                    groups = {}
                    tasks = ingestion_task_list
                    skip_w4f: bool = True if str(Variable.get('skip_w4f', 'false')).lower() == 'true' else False

                    for ext_sys_id in set(i['task_id'].split('_')[1] for i in tasks):
                        groups[ext_sys_id] = TaskGroup(ext_sys_id, tooltip=f"Wait for {ext_sys_id} Files")

                    for task in tasks:
                        task['task_id'] = task['task_id'].replace("_ingest", "") + "_w4f"

                        if not task.get('schedule_enabled', False) or skip_w4f:
                            poke_interval = 2
                            timeout = 31
                            retries = 1
                            soft_fail: bool = True
                        else:
                            poke_interval = task.get('poke_interval', 60)
                            timeout = task.get('timeout', 601)
                            retries = 2
                            soft_fail: bool = False

                        wait_for_a_file = S3KeySensor(
                            task_id=f"{task['task_id']}",
                            task_group=groups[task['task_id'].split('_')[1]],
                            bucket_name=ingestion_storage,
                            bucket_key=f"{ingestion_file_dir}/{end_date}/{task['pattern'].replace('.', '*')}",
                            wildcard_match=True,
                            poke_interval=poke_interval,
                            timeout=timeout,
                            aws_conn_id='my_aws',
                            retries=retries,
                            soft_fail=soft_fail
                        )

                        groups

                start_w4f = EmptyOperator(task_id='Start_W4F', trigger_rule='none_failed')
                end_w4f = EmptyOperator(task_id='End_W4F', trigger_rule='none_failed')
                start_w4f >> wait_for_files_steps >> end_w4f

        # Execute aggregation
        if 'aggregation' in pipeline_steps:
            with TaskGroup("Aggregation", tooltip="Run Aggregation Scripts") as aggregation:
                with TaskGroup("Aggregation_Steps", tooltip="Run Aggregation Scripts") as aggregation_steps:
                    aggregation_task_list = pipeline_config['Steps']['Aggregation']['Tasks']
                    aggregation_task_list = [task for task in aggregation_task_list if task['active']]
                    task_names = {}

                    for task in aggregation_task_list:
                        run_spark = None
                        if 'aggregation' in task['task_type']:
                            run_spark = HiveOperator(
                                task_id=task['taskid'],
                                hql=task['file_name'],
                                hive_cli_conn_id='my_hive_cli',
                                hiveconfs={
                                    "hive.txn.manager": "org.apache.hadoop.hive.ql.lockmgr.DbTxnManager",
                                    "hiveconf hive.support.concurrency": "true",
                                    "hive.exec.dynamic.partition.mode": "nonstrict"}

                                
                            )
                        elif 'temp_booked' in task['task_type']:
                            run_spark = MySqlOperator(
                                task_id=task['taskid'],
                                sql=task['file_name'],
                                mysql_conn_id='my_mysql',
                                autocommit=True,
                                trigger_rule='none_failed'
                            )
                        elif 'pyspark' in task['task_type']:
                            run_spark = LivyOperator(
                                task_id=task['taskid'],
                                livy_conn_id='my_livy',
                                proxy_user='hadoop',
                                driver_memory=Variable.get('emr_spark_driver_memory', default_var='2g'),
                                executor_memory=Variable.get('emr_spark_executor_memory', default_var='2g'),
                                file='/tmp/Aggregation/' + task['file_name'],
                                py_files=['/tmp/Libraries/*'],
                                args=[
                                    end_date,
                                    mysql_conn.host,
                                    mysql_conn.login,
                                    mysql_conn.password,
                                    pipeline_config['Environment']['BUCKET_NAME']
                                ],
                                polling_interval=60,
                                trigger_rule='none_failed',
                                conf={
                                    "spark.sql.sources.partitionOverwriteMode": "dynamic"
                                }
                            )
                        elif 'execute_model' in task['task_type']:
                            run_spark = TriggerDagRunOperatorWithSkip(
                                task_id=task['taskid'],
                                trigger_dag_id=task['options'],
                                wait_for_completion=True,
                                poke_interval=60,
                                skip=skip_models,
                                trigger_rule='none_failed',
                                conf={"ENDDATE": end_date}
                            )
                        # Append task to collector
                        task_names[task["taskid"]] = run_spark

                    # Connect each AGG task to their dependencies
                    for task in aggregation_task_list:
                        if task["dependencies_task"] == []:
                            continue
                        else:
                            [task_names[i] for i in task["dependencies_task"]] >> task_names[task["taskid"]]

                start_aggregation = EmptyOperator(task_id='Start_Aggregation', trigger_rule='none_failed')
                end_aggregation = EmptyOperator(task_id='End_Aggregation', trigger_rule='none_failed')
                start_aggregation >> aggregation_steps >> end_aggregation

        # Execute ML DAG
        if 'execute_models' in pipeline_steps:
            model_dag_id: str = pipeline_config['Steps']['Execute_Models']

            execute_models = TriggerDagRunOperatorWithSkip(
                task_id=model_dag_id,
                trigger_dag_id=model_dag_id,
                wait_for_completion=True,
                poke_interval=60,
                skip=skip_models,
                conf={"ENDDATE": end_date}
            )
        
        # Execute aggregation
        if 'post_aggregation' in pipeline_steps:
            with TaskGroup("Post_Aggregation", tooltip="Run Post Aggregation Scripts") as post_aggregation:
                with TaskGroup("Aggregation_Steps", tooltip="Run Aggregation Scripts") as aggregation_steps:
                    aggregation_task_list = pipeline_config['Steps']['Post_Aggregation']['Tasks']
                    aggregation_task_list = [task for task in aggregation_task_list if task['active']]
                    task_names = {}

                    for task in aggregation_task_list:
                        run_spark = None
                        if 'aggregation' in task['task_type']:
                            run_spark = HiveOperator(
                                task_id=task['taskid'],
                                hql=task['file_name'],
                                hive_cli_conn_id='my_hive_cli',
                                hiveconfs={
                                    "hive.txn.manager": "org.apache.hadoop.hive.ql.lockmgr.DbTxnManager",
                                    "hiveconf hive.support.concurrency": "true",
                                    "hive.exec.dynamic.partition.mode": "nonstrict"}
                            )
                        elif 'temp_booked' in task['task_type']:
                            run_spark = MySqlOperator(
                                task_id=task['taskid'],
                                sql=task['file_name'],
                                mysql_conn_id='my_mysql',
                                autocommit=True,
                                trigger_rule='none_failed'
                            )
                        elif 'pyspark' in task['task_type']:
                            run_spark = LivyOperator(
                                task_id=task['taskid'],
                                livy_conn_id='my_livy',
                                proxy_user='hadoop',
                                # driver_memory =Variable.get('emr_spark_driver_memory_post_agg', default_var='2g'),
                                # executor_memory =  Variable.get('emr_spark_executor_memory_post_agg', default_var='2g'),
                                # num_executors = int(Variable.get('emr_spark_num_executors_post_agg', default_var = 5)),
                                file='/tmp/Aggregation/' + task['file_name'],
                                py_files=['/tmp/Libraries/*'],
                                args=[
                                    end_date,
                                    mysql_conn.host,
                                    mysql_conn.login,
                                    mysql_conn.password,
                                    pipeline_config['Environment']['BUCKET_NAME']
                                ],
                                polling_interval=60,
                                trigger_rule='none_failed',
                                conf={
                                    "spark.sql.sources.partitionOverwriteMode": "dynamic"
                                }
                            )
                        elif 'execute_model' in task['task_type']:
                            run_spark = TriggerDagRunOperatorWithSkip(
                                task_id=task['taskid'],
                                trigger_dag_id=task['options'],
                                wait_for_completion=True,
                                poke_interval=60,
                                skip=skip_models,
                                trigger_rule='none_failed',
                                conf={"ENDDATE": end_date}
                            )
                        # Append task to collector
                        task_names[task["taskid"]] = run_spark

                    # Connect each AGG task to their dependencies
                    for task in aggregation_task_list:
                        if task["dependencies_task"] == []:
                            continue
                        else:
                            [task_names[i] for i in task["dependencies_task"]] >> task_names[task["taskid"]]

                start_aggregation = EmptyOperator(task_id='Start_Aggregation', trigger_rule='none_failed')
                end_aggregation = EmptyOperator(task_id='End_Aggregation', trigger_rule='none_failed')
                start_aggregation >> aggregation_steps >> end_aggregation
                
        # Execute Migration from Hive to other DB
        if 'migration' in pipeline_steps:
            with TaskGroup("Migration", tooltip="Run Migration Scripts") as migration:
                with TaskGroup("Migration_Steps", tooltip="Run Migration Scripts") as migration_steps:
                    migration_task_list = pipeline_config['Steps']['Migration']['Tasks']
                    migration_task_list = [task for task in migration_task_list if task['active']]
                    task_names = {}
                    for task in migration_task_list:
                        if 'migration' in task['task_type']:
                            move_to_mysql = HiveToMySqlOperator(
                                task_id=task['taskid'],
                                sql=task['file_name'],
                                mysql_table=task['file_name'][4:-4],
                                mysql_conn_id='my_mysql',
                                mysql_preoperator="""
                                    DROP PROCEDURE IF EXISTS ddp_{table_name};
                                    CREATE PROCEDURE ddp_{table_name}()
                                    BEGIN
                                        IF EXISTS ( SELECT *
                                                FROM information_schema.columns
                                                WHERE table_name = '{table_name}'
                                                AND column_name = 'partition_date'
                                                AND table_schema = '{schema_name}' ) THEN
                                            DELETE FROM {schema_name}.{table_name} WHERE partition_date = {end_date};
                                        ELSE
                                            TRUNCATE TABLE {schema_name}.{table_name};
                                        END IF;
                                    END;
                                    CALL ddp_{table_name}();
                                    DROP PROCEDURE IF EXISTS ddp_{table_name};
                                    """.format(
                                    table_name=task['file_name'][4:-4],
                                    schema_name='data_activation',
                                    end_date=end_date
                                ),
                                hiveserver2_conn_id='my_hive',
                                hive_conf={
                                    "hive.txn.manager": "org.apache.hadoop.hive.ql.lockmgr.DbTxnManager"}
                            )
                        task_names[task["taskid"]] = move_to_mysql

                    # Connect each MIG task to their dependencies
                    for task in migration_task_list:
                        if task["dependencies_task"] == []:
                            continue
                        else:
                            [task_names[i] for i in task["dependencies_task"]] >> task_names[task["taskid"]]

                start_migration = EmptyOperator(task_id='Start_Migration', trigger_rule='none_failed')
                end_migration = EmptyOperator(task_id='End_Migration', trigger_rule='none_failed')
                start_migration >> migration_steps >> end_migration

        # Trigger other pipelines
        if 'trigger_pipelines' in pipeline_steps:
            trigger_config = pipeline_config['Steps']['Trigger_Pipelines']
            trigger_name = trigger_config.get('Name', 'Trigger_Pipelines')

            with TaskGroup(trigger_name, tooltip=f"{trigger_name} pipelines") as trigger_pipelines:
                with TaskGroup(f"{trigger_name}_Steps", tooltip=f"{trigger_name} pipelines") as trigger_pipelines_steps:

                    with TaskGroup("Run_Pipelines", tooltip="Run case pipelines") as run_pipelines:
                        for sub_pipeline in trigger_config['Tasks']:
                            globals()[sub_pipeline.lower()] = TriggerDagRunOperator(
                                task_id=sub_pipeline,
                                trigger_dag_id=sub_pipeline,
                                wait_for_completion=True,
                                poke_interval=int(trigger_config.get('Poke_Interval', 60)),
                                retries=0,
                                execution_date='{{ts}}',
                                reset_dag_run=True,
                                conf={"ENDDATE": end_date}
                            )

                        if trigger_config.get('Tasks_Order'):
                            for line in trigger_config['Tasks_Order']:
                                eval(str(line).lower())

                    if trigger_config.get('Mark_Scheduled', False):
                        with TaskGroup("Mark_Pipelines_Scheduled",
                                       tooltip="Mark case pipelines as scheduled") as schedule_pipelines:
                            for sub_pipeline in trigger_config['Tasks']:
                                schedule_pipeline = MySqlOperator(
                                    task_id=f'Mark_{sub_pipeline}_Scheduled',
                                    sql="""
                                    INSERT INTO
                                        data_activation.etl_traffic_lights (component_name, process_date, state,
                                        create_datetime, modified_datetime, run_id)
                                    VALUES
                                        ('{{ params.pipeline_name }}', {{ params.ENDDATE }}, 'SCHEDULED', NOW(), NOW(), '{{ run_id }}')
                                    ON DUPLICATE KEY UPDATE
                                        component_name='{{ params.pipeline_name }}', process_date={{ params.ENDDATE }}, state='SCHEDULED',
                                        create_datetime=create_datetime, modified_datetime=NOW(), run_id='{{ run_id }}'
                                    """,
                                    mysql_conn_id='my_mysql',
                                    autocommit=True,
                                    params={
                                        'pipeline_name': sub_pipeline
                                    }
                                )

                        schedule_pipelines >> run_pipelines

                start_trigger_pipelines = EmptyOperator(task_id=f'Start_{trigger_name}', trigger_rule='none_failed')
                end_trigger_pipelines = EmptyOperator(task_id=f'End_{trigger_name}', trigger_rule='none_failed')
                start_trigger_pipelines >> trigger_pipelines_steps >> end_trigger_pipelines

        # Execute SQL Scripts on MySql DB
        if 'execution' in pipeline_steps:
            with TaskGroup("Execution", tooltip="Run Execution Scripts") as execution:
                with TaskGroup("Execution_Steps", tooltip="Run Execution Scripts") as execution_steps:
                    execution_task_list = pipeline_config['Steps']['Execution']['Tasks']
                    execution_task_list = [task for task in execution_task_list if task['active']]
                    task_names = {}

                    for task in execution_task_list:
                        execute_task = None
                        if 'mysql_execution' in task['task_type']:
                            execute_task = MySqlOperator(
                                task_id=task["taskid"],
                                sql=task["file_name"],
                                mysql_conn_id='my_mysql',
                                autocommit=True
                            )

                        # Append task to collector
                        task_names[task["taskid"]] = execute_task

                    # Connect each AGG task to their dependencies
                    for task in execution_task_list:
                        if task["dependencies_task"] == []:
                            continue
                        else:
                            [task_names[i] for i in task["dependencies_task"]] >> task_names[task["taskid"]]

                start_execution = EmptyOperator(task_id='Start_Execution', trigger_rule='none_failed')
                end_execution = EmptyOperator(task_id='End_Execution', trigger_rule='none_failed')
                start_execution >> execution_steps >> end_execution

        # Mark pipeline completed
        if 'mark_completed' in pipeline_steps:
            with TaskGroup("Mark_Pipeline_Completed", tooltip="Mark pipeline completed") as mark_completed:
                with TaskGroup("Mark_Completed_Steps", tooltip="Mark pipeline completed") as mark_completed_steps:
                    mark_running = MySqlOperator(
                        task_id='Mark_Pipeline_Running',
                        sql="""
                        INSERT INTO
                            data_activation.etl_traffic_lights (component_name, process_date, state,
                            create_datetime, modified_datetime, run_id)
                        VALUES
                            ('{{ params.pipeline_name }}', {{ params.ENDDATE }}, 'RUNNING', NOW(), NOW(), '{{ run_id }}')
                        ON DUPLICATE KEY UPDATE
                            component_name='{{ params.pipeline_name }}', process_date={{ params.ENDDATE }}, state='RUNNING',
                            create_datetime=create_datetime, modified_datetime=NOW(), run_id='{{ run_id }}'
                        """,
                        mysql_conn_id='my_mysql',
                        trigger_rule='always',
                        autocommit=True,
                        params={
                            'pipeline_name': pipeline_config['Name']
                        }
                    )
                    mark_success = MySqlOperator(
                        task_id='Mark_Pipeline_Successful',
                        sql="""
                        UPDATE
                            data_activation.etl_traffic_lights SET state='COMPLETED', modified_datetime = NOW()
                        WHERE
                            component_name='{{ params.pipeline_name }}' AND run_id = '{{ run_id }}' AND
                            process_date={{ params.ENDDATE }}
                        """,
                        mysql_conn_id='my_mysql',
                        autocommit=True,
                        params={
                            'pipeline_name': pipeline_config['Name']
                        }
                    )
                    mark_fail = MySqlOperator(
                        task_id='Mark_Pipeline_Failed',
                        sql="""
                        UPDATE
                            data_activation.etl_traffic_lights SET state='FAILED', modified_datetime = NOW()
                        WHERE
                            component_name='{{ params.pipeline_name }}' AND run_id = '{{ run_id }}' AND
                            process_date={{ params.ENDDATE }}
                        """,
                        mysql_conn_id='my_mysql',
                        trigger_rule='one_failed',
                        autocommit=True,
                        params={
                            'pipeline_name': pipeline_config['Name']
                        }
                    )

                    [mark_running, mark_fail, mark_success]

                start_mark_completed = EmptyOperator(task_id='Start_Mark_Completed', trigger_rule='none_failed')
                end_mark_completed = EmptyOperator(task_id='End_Mark_Completed', trigger_rule='none_failed')

                start_mark_completed >> mark_completed_steps >> end_mark_completed

        # Build operators dependencies
        if not pipeline_config.get('Steps_Order'):
            eval(f"start >> {' >> '.join(step for step in pipeline_steps)} >> end")
        else:
            for line in pipeline_config.get('Steps_Order'):
                eval(line.lower())

    return dag

# EOF