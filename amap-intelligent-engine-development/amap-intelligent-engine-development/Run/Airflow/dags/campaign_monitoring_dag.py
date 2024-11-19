from dag_generator import create_dag
from dag_generator_models import create_ml_dag

#
ROOT_PATH = "/opt/airflow/dags"

cm_ml = create_ml_dag(case_name='DM_Model_Campaign_Monitoring',
                      model_foldernames=['campaignoptimization'],
                      tags=['Campaign_Monitoring'])
campaign_monitoring = create_dag('campaign_monitoring_config.yaml')

# EOF
