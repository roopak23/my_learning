import os
from pyhive import hive


def _get_hive_host() -> str:
    return os.getenv("MASTER_STATIC_IP")


def _get_hive_port() -> int:
    return 10000


def _get_hive_username() -> str:
    return "hadoop"


def _get_hive_configuration() -> dict:
    return {'hive.txn.manager': 'org.apache.hadoop.hive.ql.lockmgr.DbTxnManager'}


class IEHiveConnection(hive.Connection):
    def __init__(
            self,
            host=_get_hive_host(),
            port=_get_hive_port(),
            scheme=None,
            username=_get_hive_username(),
            database='default',
            auth=None,
            configuration=None,
            kerberos_service_name=None,
            password=None,
            check_hostname=None,
            ssl_cert=None,
            thrift_transport=None
    ):
        if configuration is None:
            configuration = _get_hive_configuration()
        super().__init__(
            host=host,
            port=port,
            scheme=scheme,
            username=username,
            database=database,
            auth=auth,
            configuration=configuration,
            kerberos_service_name=kerberos_service_name,
            password=password,
            check_hostname=check_hostname,
            ssl_cert=ssl_cert,
            thrift_transport=thrift_transport
        )

