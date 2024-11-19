from dag_generator import create_dag
#
ROOT_PATH = "/opt/airflow/dags"
audience = create_dag('audience_cdp_mapping_config.yaml')

# EOF
