import os
import boto3
import logging
from datetime import date

# Init Logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Get Stack Name
ENVIRONMENT = os.environ['ENVIRONMENT']
FOUNDATION_CAPACITY = int(os.environ['FOUNDATION_CAPACITY'])
DATA_CAPACITY = int(os.environ['DATA_CAPACITY'])
MANAGEMENT_CAPACITY = int(os.environ['MANAGEMENT_CAPACITY'])

FOUNDATION_MIN_CAPACITY = int(os.environ['FOUNDATION_MIN_CAPACITY'])
DATA_MIN_CAPACITY = int(os.environ['DATA_MIN_CAPACITY'])
MANAGEMENT_MIN_CAPACITY = int(os.environ['MANAGEMENT_MIN_CAPACITY'])

# Protected Instance list (this instances will not be started)
ec2_protected = os.environ['EXCLUDE']

# Configure Executor
ec2_client = boto3.resource('ec2')
scale_client = boto3.client('autoscaling')


def lambda_handler(event, context):
    if 'start' in event['action']:
        start_machines()
    elif 'stop' in event['action']:
        stop_machines()
    else:
        logger.warn("Event not recognized: {}".format(event))
        return 500


def set_desired_capacity(capacity):

    autoscale_groups = eval(os.environ['ASGs'])

    response = ''
    target_capacity = 0
    min_capacity    = 0

    for group in autoscale_groups:

        logger.info("Set capacity for: {}".format(group))

        # Use 'capacity' to check if we want to start or stop the instances. If we want to start the instances, then we check each group and assign the right number of target workers per group. TODO: Set to environment variables
        if capacity == 1:
            if 'foundation' in group:
                target_capacity = FOUNDATION_CAPACITY
                min_capacity = FOUNDATION_MIN_CAPACITY
            if 'management' in group:
                target_capacity = MANAGEMENT_CAPACITY
                min_capacity = MANAGEMENT_MIN_CAPACITY
            if 'data' in group:
                target_capacity = DATA_CAPACITY
                min_capacity = DATA_MIN_CAPACITY

        try:
            logger.info("Set capacity to {} for group {}".format(target_capacity, group))
            response = scale_client.update_auto_scaling_group(
                AutoScalingGroupName=group,
                DesiredCapacity=target_capacity,
                MinSize = min_capacity
            )
            logger.info("Set capacity for group {} completed".format(group))
        except Exception as e:
            logger.error("Autoscaling capacity change fail: {}".format(e))

    return response


def start_machines():
    # ===================== EC2 =====================
    # Get Active EC2 Instances
    ec2_instances = ec2_client.instances.filter(Filters=[{'Name': 'tag:Product', 'Values': [
                                                'amap']}, {'Name': 'instance-state-name', 'Values': ['stopped']}])

    # Remove Protected
    stopped_ec2_ids = [
        ec2_instance.id for ec2_instance in ec2_instances if ec2_instance.id not in ec2_protected]

    response = set_desired_capacity(1)

    try:
        
        if stopped_ec2_ids:
            #ec2_client.instances.filter(InstanceIds=stopped_ec2_ids).start() commented to reduce cost, Ec2 to be started manuualy
            logger.info('Starting instances: {}'.format(str(stopped_ec2_ids)))

        return 200
    except Exception as e:
        # Any Error will be logged
        logger.warn(e)
        return e


def stop_machines():
    # ===================== EC2 =====================
    # Get Active EC2 Instances
    ec2_instances = ec2_client.instances.filter(Filters=[{'Name': 'tag:Product', 'Values': [
                                                'amap']}, {'Name': 'instance-state-name', 'Values': ['running']}])

    # Terminate the EMR and get instance list
    emr_ids = stop_emr()

    # Filter out EMR IDs
    running_ec2_ids = [i.id for i in ec2_instances if i.id not in emr_ids]
    response = set_desired_capacity(0)

    if running_ec2_ids:
        for machine in running_ec2_ids:
            try:
                ec2_client.instances.filter(InstanceIds=[machine]).stop()
                logger.info('Stopping instances: {}'.format(
                    str(running_ec2_ids)))

            except Exception as e:
                # Any Error will be logged
                logger.warn(e)
    else:
        logger.info('No EC2s to stop...')

    return 200


def stop_emr():
    # Create connector
    emr_conn = boto3.client("emr")

    # Get existing cluster
    cluster_ids = emr_conn.list_clusters(
        ClusterStates=['STARTING', 'BOOTSTRAPPING', 'RUNNING', 'WAITING'])

    # Try to shut it down
    emr_ids = []
    for cluster in cluster_ids['Clusters']:
        if cluster:
            try:
                # TODO: It only works for 1 at the moment
                cluster_id = cluster['Id']

                # Get instance ids
                response = emr_conn.list_instances(ClusterId=cluster_id)
                emr_ids.append([i['Ec2InstanceId']
                               for i in response['Instances']])

                # Terminate clusters
                logger.info("Terminating Cluster: {}".format(cluster_id))
                response = emr_conn.terminate_job_flows(
                    JobFlowIds=[cluster_id])
            except Exception as e:
                logger.warn(e)
        else:
            logger.info('No EMR cluster to stop...')

    # Return instance list
    return emr_ids
