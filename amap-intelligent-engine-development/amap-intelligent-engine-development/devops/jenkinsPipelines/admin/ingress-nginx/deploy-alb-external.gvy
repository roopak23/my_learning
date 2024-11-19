pipeline {
    agent any
     environment{
        BRANCH_NAME="${env.GIT_BRANCH.split('/').size() == 1 ? env.GIT_BRANCH.split('/')[-1] : env.GIT_BRANCH.split('/')[1..-1].join('/')}"
        EKS_NAMESPACE="default"
    }
    parameters {
        booleanParam(name: 'DoYouWantDryRun', defaultValue: false, description: 'Click if you want a dry run only (no building).')
    }
    stages {
        stage("Checkout Repo") {
          steps {
            cleanWs()
            checkout scm
          }
        }
         stage('Install Prereqs and set variables') {
            steps {
                script {         
                    def getEnv = '''
                            branch=$BRANCH_NAME
                            if [ \$branch = "development" ]; then 
                               env="dev"
                            elif  [ \$branch = "environment/SIT" ];  then
                               env="sit"
                            elif  [ \$branch = "environment/UAT" ];  then
                               env="uat"
                            elif  [ \$branch = "environment/PROD" ];  then
                               env="prod"
                            else
                               env="dev"
                            fi
                            echo $env | sed 's#/#-#g'
                    '''
                    env.ENVIRONMENT=sh(script:getEnv,returnStdout: true).trim()
                   
                    dir("${workspace}/devops/scripts") {
                        sh """
                            chmod +x install-prereqs.sh
                            ./install-prereqs.sh
                            chmod +x ../../devops/scripts/set-eks-cluster.sh 
                            chmod +x ../../devops/scripts/update_params.py
                        """
                    }
                    
                    dir("${workspace}/appconfig/${env.ENVIRONMENT}") {
                        env.AWS_REGION=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.AWS_REGION").value' aws-load-balancer-controller.yaml ''' , returnStdout: true).trim()
                        env.EKS_CLUSTER_NAME=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.EKS_CLUSTER_NAME").value' aws-load-balancer-controller.yaml ''' , returnStdout: true).trim()
                        
                    }
                }
            }
        }
        stage("Configure Load Balancer Controler") {
            steps {
                dir("${workspace}/charts/aws-load-balancer-controller") {
                    script {
                        sh """
                            export PATH=/usr/local/bin:$PATH

                            #set cluster config
                            ../../devops/scripts/set-eks-cluster.sh ${env.AWS_REGION} ${env.EKS_CLUSTER_NAME} ${env.EKS_NAMESPACE}
                            
                            #update environment variables
                            python3 --version
                            python3 ../../devops/scripts/update_params.py ../../appconfig/${ENVIRONMENT}/aws-load-balancer-controller.yaml values-dm3.yaml values-${ENVIRONMENT}.yaml
                            
                            cat values-${env.ENVIRONMENT}.yaml 
                        """
                    }
                }
            }
        }
        stage("Deploy Loab Balancer Controler") {
            steps {
                dir("${workspace}/charts/aws-load-balancer-controller") {
                    script {
                        sh """

                            kubectl create namespace dm --dry-run=client -o yaml | kubectl apply -f -
                            #helm repo add eks https://aws.github.io/eks-charts
                            #helm repo update

                            if [ ${DoYouWantDryRun} == false ]; then
                                echo "Performing without --dry-run"
                                command_param=""
                            else
                                echo "Performing with --dry-run"
                                command_param="--dry-run"
                            fi

                        helm upgrade --install -n default aws-load-balancer-controller . --values=values-${env.ENVIRONMENT}.yaml \${command_param}

                            #kubectl apply -f alb-external-${ENVIRONMENT}.yaml

                        """
                    }
                }
            }
        }
    }
    post {
        cleanup {
            script {
                dir("${workspace}") {
                    deleteDir()
                }

                dir("${workspace}@tmp") {
                    deleteDir()
                }
            }
        }
    }
}
