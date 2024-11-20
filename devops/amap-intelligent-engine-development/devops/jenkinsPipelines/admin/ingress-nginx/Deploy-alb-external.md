# External ALB

filename: alb-external.yaml

The external ALB is used to enable external access to the API Layer and Keycloak. The ALB is controlled by AWS Load Balancer Controller.

Prerequisites: 
- AWS Load Balancer Controller should be deployed in the Kubernetes Cluster. Refer to the documentation on deploying. 
- AWS Certificate ARN
- Route53 public hosted zone

## Jenkins Pipelines
- **deploy_alb_external_dev** - Currently there is one Jenkins pipeline to deploy the alb-external yaml to the DEV environment. That is hardcoded with the values required to deploy to DEV. 

TODO: 
Create generic pipeline that can deploy to other environments. 

AWS Load Balancer Controller docs:
*https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html*