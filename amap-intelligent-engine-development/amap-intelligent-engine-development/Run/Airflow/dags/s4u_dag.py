from dag_generator import create_dag
from dag_generator_models import create_ml_dag
#
ROOT_PATH = "/opt/airflow/dags"

s4u_ml = create_ml_dag(case_name='DM_Model_Purchase_Behaviour',
                       model_foldernames=['purchasebehaviour'],
                       tags=['Suggested_For_You'])

s4u_ml_training = create_ml_dag(case_name='DM_Model_Purchase_Behaviour_Training',
                       model_foldernames=['purchasebehaviour'],
                       tags=['Suggested_For_You','Training'],
                       training=True)

s4u = create_dag('s4u_config.yaml')

# EOF
