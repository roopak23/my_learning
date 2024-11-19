# Airflow General
from airflow import DAG
from datetime import timedelta
import pendulum
from requests import Request
from requests.auth import AuthBase

from airflow.operators.empty import EmptyOperator
from airflow.providers.http.operators.http import SimpleHttpOperator

# Some Variables
default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": pendulum.datetime(2020, 1, 1),
    "email": ["airflow@airflow.com"],
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 0,
    'catchup': False,
    "retry_delay": timedelta(minutes=2),
}
ROOT_PATH = "/opt/airflow/dags"

"""
Define connection with at least:
    Connection Id:      segmentation_api_http
    Connection Type:    HTTP
    Host:               <without specific endpoint>
    Login:              airflow
    Password:           <token from header "Authorization: Basic <token>">
    Port:               <if needed>
"""


class HTTPSegToolAuth(AuthBase):
    def __init__(self, username: str, password: str):
        self.username: str = username
        self.password: str = password

    def __call__(self, request: Request):
        request.headers['Authorization'] = f'Basic {self.password}'
        return request


# ======== DAG ========
with DAG('DM_Segtool_Audience_API_Call', default_args=default_args, schedule_interval=None, tags=['Audience'], template_searchpath=[], max_active_runs=1) as dag:

    start = EmptyOperator(task_id='Start')

    api_request = SimpleHttpOperator(
        task_id='Call_Segmentation_Tool_API',
        method='POST',
        http_conn_id='segmentation_api_http',
        endpoint='seg-tool-be/rest/campaign_segment/refresh',
        response_check=lambda response: 'JSESSIONID' in response.cookies,
        auth_type=HTTPSegToolAuth,
        log_response=True,
        data=''
    )

    stop = EmptyOperator(task_id='Stop', trigger_rule='none_failed')

    start >> api_request >> stop
# EOF