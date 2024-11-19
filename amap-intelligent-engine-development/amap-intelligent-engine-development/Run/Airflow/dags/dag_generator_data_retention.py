# Airflow General
from airflow import DAG
from datetime import timedelta
import pendulum
from airflow.utils.task_group import TaskGroup
from airflow.operators.empty import EmptyOperator

# Livy
from airflow.providers.apache.livy.operators.livy import LivyOperator

# Core Imports
from dataclasses import dataclass
import os
import yaml


# Support Functions
class Config(dict):
    pass


def import_config(path: str) -> Config:
    with open(path, "r") as ymlfile:
        cfg = yaml.load(ymlfile.read(), Loader=yaml.SafeLoader) or {}

    return cfg


@dataclass
class DataRetention:
    table_name: str
    number_of_days: int


@dataclass
class DataRetentionCase:
    name: str
    data_retention_list: list[DataRetention]


def get_cases_with_install_configs(pipelines_configs_path: str) -> list[DataRetentionCase]:
    cases_with_configs: list[DataRetentionCase] = []
    configs_yamls = [config_yaml_name for config_yaml_name in os.listdir(pipelines_configs_path) if 'config.yaml' in config_yaml_name]

    for config_yaml_name in configs_yamls:
        config: Config = import_config(f'{pipelines_configs_path}/{config_yaml_name}')
        if not config.get('Data_Retention', None):
            continue

        config_name: str = config['Name']
        retention_groups = config['Data_Retention']['Retention_Groups']
        dr_list: list[DataRetention] = []
        for retention_group in retention_groups:
            tables = retention_group['Tables']
            retention_period = retention_group['Retention_period']

            for table in tables:
                dr_list.append(DataRetention(table_name=table, number_of_days=retention_period))

        cases_with_configs.append(DataRetentionCase(name=config_name, data_retention_list=dr_list))

    return cases_with_configs


# Load DAG Configurations
ROOT_PATH: str = "/opt/airflow/dags"
DAG_CONFIG: Config = import_config(ROOT_PATH + '/scripts/batch/variables.yaml')

configs_path: str = DAG_CONFIG['DAG']['PIPELINES_CONFIGS_PATH']
end_date = eval(DAG_CONFIG['Tables']['ENDDATE'])


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


# ======== DAG ========
with DAG('Hive_Data_Purge', default_args=DEFAULT_ARGS, schedule_interval=None, tags=['Infra']) as dag:
    start = EmptyOperator(task_id='Start', trigger_rule='none_failed')
    end = EmptyOperator(task_id='End', trigger_rule='none_failed')

    with TaskGroup("Hive_Data_Housekeeping", tooltip="Retain Data in Hive Tables") as hive_data_retention_section:
        cases_and_configs: list[DataRetentionCase] = get_cases_with_install_configs(configs_path)

        for case in cases_and_configs:
            case_section = TaskGroup(f"{case.name}", tooltip=f"Data Retention of {case.name} Hive Objects")
            for dr in case.data_retention_list:
                run_data_retention = LivyOperator(
                    task_id=dr.table_name,
                    task_group=case_section,
                    livy_conn_id='my_livy',
                    proxy_user='hadoop',
                    driver_memory='1g',
                    executor_memory='1g',
                    file='/tmp/Libraries/data_retention.py',
                    py_files=['/tmp/Libraries/ie_hive_connection.py'],
                    args=[dr.table_name, dr.number_of_days, end_date],
                    polling_interval=60,
                    trigger_rule='none_failed',
                    conf={"spark.sql.sources.partitionOverwriteMode": "dynamic"}
                )

    start >> hive_data_retention_section >> end
