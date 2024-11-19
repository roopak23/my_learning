from dag_generator import create_dag
from dag_generator_models import create_ml_dag
#
ROOT_PATH = "/opt/airflow/dags"

inventory_ml = create_ml_dag(case_name='DM_Model_Inventory_Management',
                             model_foldernames=['inventory_forecast'],
                             tags=['Inventory_Management'])
inventory = create_dag('inventory_management_config.yaml')

# EOF
