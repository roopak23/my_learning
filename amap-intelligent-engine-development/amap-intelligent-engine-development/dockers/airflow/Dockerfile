# AUTHOR: Saverio "Kaspar" Ferrara
# DESCRIPTION: Basic Airflow container with Hive connectors and additional pip packages
# BUILD: read the README.md file

#FROM apache/airflow:2.0.0-python3.8
FROM PARAMS.ECR_REPO/airflow:PARAMS.AIRFLOW_VERSION

# Switch to Airflow user
USER 50000
	
# COPY Dags and Spark files to Docker image
ADD dags /opt/airflow/dags
ADD Spark /opt/airflow/dags/Spark/

# Copy the entrypoint script that will rename the aws_cluster_template.yaml with variables during runtime
# COPY --chown=airflow:airflow entrypoint.sh /opt/airflow
# # ENTRYPOINT ["sh", "-c", "echo", "ASDFASDFASDFASDFASDFASDFASDFASDFASDF"]
# ENTRYPOINT ["bash", "-c", "./entrypoint.sh"]
# Installed in base image:
# apache-airflow[async,aws,azure,celery,dask,elasticsearch,gcp,kubernetes,mysql,postgres,redis,slack,ssh,statsd,virtualenv]

# EOF