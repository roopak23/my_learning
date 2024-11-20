from dag_generator import create_dag
from dag_generator_models import create_ml_dag
#
ROOT_PATH = "/opt/airflow/dags"

audience_ml = create_ml_dag(case_name='DM_Model_Audience_Lookalike',
                             model_foldernames=['audiencelookalike'],
                             tags=['Audience_CDP'])

audience_ml_training = create_ml_dag(case_name='DM_Model_Audience_Lookalike_Training',
                             model_foldernames=['audiencelookalike'],
                             tags=['Audience_CDP','Training'],
                             training=True)

audience = create_dag('audience_cdp_config.yaml')

# EOF