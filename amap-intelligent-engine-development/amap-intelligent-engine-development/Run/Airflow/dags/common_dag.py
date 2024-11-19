from dag_generator import create_dag
#
ROOT_PATH = "/opt/airflow/dags"
common = create_dag('common_config.yaml')

# EOF
