from dag_generator import create_dag
#
ROOT_PATH = "/opt/airflow/dags"
etl_daily_run = create_dag('etl_daily_run_config.yaml')

# EOF
