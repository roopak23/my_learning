import os
from io import BytesIO
import subprocess
from pyarrow import fs


class ClasspathSetter:
    __instance = None

    def __new__(cls):
        if cls.__instance is None:
            cls.__instance = object.__new__(cls)
            _add_classpath_env_variable()
        return cls.__instance


def _add_classpath_env_variable() -> None:
    classpath = subprocess.run("$HADOOP_HOME/bin/hadoop classpath --glob",  # $HADOOP_HOME=/lib/hadoop
                               capture_output=True,
                               text=True,
                               shell=True).stdout.strip()
    if os.environ.get("CLASSPATH", None):
        if classpath not in os.environ["CLASSPATH"]:
            os.environ["CLASSPATH"] = f'{os.environ["CLASSPATH"]}:{classpath}'
    else:
        os.environ["CLASSPATH"] = classpath


def pkl_from_hdfs(path: str) -> BytesIO:
    try:
        pkl_file = open(path, 'rb')
    except FileNotFoundError:
        ClasspathSetter()
        hdfs = fs.HadoopFileSystem('default', 8020)
        with hdfs.open_input_file(path) as hdfs_f:
            pkl_file = BytesIO(hdfs_f.read())
            hdfs_f.close()
            del hdfs_f
    return pkl_file
