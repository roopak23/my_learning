# Airflow General
from airflow import DAG
from datetime import timedelta
import pendulum
from airflow.utils.task_group import TaskGroup
from airflow.operators.empty import EmptyOperator

# MySQL
from airflow.providers.mysql.operators.mysql import MySqlOperator

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
class MySQLInstallFileName:
    file_name: str
    is_view: bool


@dataclass
class MySQLInstallCase:
    name: str
    has_table: bool
    has_view: bool
    files: list[MySQLInstallFileName]


def get_cases_with_install_configs(pipelines_configs_path: str) -> list[MySQLInstallCase]:
    cases_with_configs: list[MySQLInstallCase] = []
    configs_yamls = [config_yaml_name for config_yaml_name in os.listdir(pipelines_configs_path) if 'config.yaml' in config_yaml_name]

    for config_yaml_name in configs_yamls:
        config: Config = import_config(f'{pipelines_configs_path}/{config_yaml_name}')
        if not config.get('MySQL_Creation', None):
            continue

        case_name: str = config['Name']
        case_creation_cfg: Config = config['MySQL_Creation']
        mysql_files: list[MySQLInstallFileName] = []
        case_has_table, case_has_view = False, False

        for table_name in case_creation_cfg.get('Tables', []):
            case_has_table = True
            mysql_files.append(MySQLInstallFileName(file_name=table_name, is_view=False))

        for view_name in case_creation_cfg.get('Views', []):
            case_has_view = True
            mysql_files.append(MySQLInstallFileName(file_name=view_name, is_view=True))

        cases_with_configs.append(MySQLInstallCase(name=case_name, has_table=case_has_table, has_view=case_has_view, files=mysql_files))

    return cases_with_configs


# Load DAG Configurations
ROOT_PATH: str = "/opt/airflow/dags"
DAG_CONFIG: Config = import_config(ROOT_PATH + '/scripts/batch/variables.yaml')

installation_path: str = DAG_CONFIG['DAG']['INSTALLATION_PATH']
configs_path: str = DAG_CONFIG['DAG']['PIPELINES_CONFIGS_PATH']
mysql_creation_path: str = installation_path + '/MysqlCreation'

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

template_searchpath = [
    mysql_creation_path
]


# ======== DAG ========
with DAG('MySQL_Installation', default_args=DEFAULT_ARGS, schedule_interval=None, tags=['Infra'],
         template_searchpath=template_searchpath) as dag:
    start = EmptyOperator(task_id='Start', trigger_rule='none_failed')
    end = EmptyOperator(task_id='End', trigger_rule='none_failed')

    with TaskGroup("Creation", tooltip="Create DB Tables") as create_section:
        cases_and_configs: list[MySQLInstallCase] = get_cases_with_install_configs(configs_path)

        for case in cases_and_configs:
            case_section = TaskGroup(f"{case.name}", tooltip=f"Create {case.name} MySQL Objects")
            if case.has_table:
                table_section = TaskGroup(f"Tables_{case.name}", tooltip=f"Create Tables", parent_group=case_section)
            if case.has_view:
                view_section = TaskGroup(f"Views_{case.name}", tooltip=f"Create Views", parent_group=case_section)

            for file in case.files:
                run_mysql = MySqlOperator(
                    task_group=view_section if file.is_view else table_section,
                    task_id=f'Create_{file.file_name[5:-4] if file.is_view else file.file_name[6:-4]}',
                    mysql_conn_id='my_mysql',
                    sql=file.file_name
                )
            if case.has_table and case.has_view:
                [table_section >> view_section]

    start >> create_section >> end

