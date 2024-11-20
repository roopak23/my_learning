from dag_generator import create_dag

#
ROOT_PATH = "/opt/airflow/dags"

inventory = create_dag('inventory_management_initial_load_config.yaml')

# EOF
