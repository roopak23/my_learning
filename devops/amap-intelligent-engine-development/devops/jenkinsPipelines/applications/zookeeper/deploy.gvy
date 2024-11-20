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
                    
                    dir("${workspace}/appconfig/${ENVIRONMENT}") {
                        env.AWS_REGION=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.AWS_REGION").value' zookeeper.yaml ''' , returnStdout: true).trim()
                        env.EKS_CLUSTER_NAME=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.EKS_CLUSTER_NAME").value' zookeeper.yaml ''' , returnStdout: true).trim()
                        
                    }
                }
            }
        } 
        stage("Configure Zookeeper") {
            steps {
                script {
                    dir("${workspace}/charts/zookeeper") {
                        sh """
                            export PATH=/usr/local/bin:$PATH

                            #set cluster  onfig
                            ../../devops/scripts/set-eks-cluster.sh ${env.AWS_REGION} ${env.EKS_CLUSTER_NAME} ${env.EKS_NAMESPACE}
                            
                            #update environment variables
                            python3 --version
                            python3 ../../devops/scripts/update_params.py ../../appconfig/${env.ENVIRONMENT}/zookeeper.yaml values-dm3.yaml values-${env.ENVIRONMENT}.yaml

                            cat values-${env.ENVIRONMENT}.yaml

                        """
                    }
                }
            }
        }
        stage("Deploy Zookeeper") {
            steps {
                script {
                    dir("${workspace}/charts/zookeeper") {
                        sh """
                            export PATH=/usr/local/bin:$PATH

                            #helm repo add bitnami https://charts.bitnami.com/bitnami
                            #helm repo update
                            #helm upgrade --install zookeeper-dm bitnami/zookeeper --version="7.6.0" -n dm --values=zookeeper.yaml

                            if [ ${params.DoYouWantDryRun} == false ]; then
                                echo "Performing without --dry-run"
                                command_param=""
                            else
                                echo "Performing with --dry-run"
                                command_param="--dry-run"
                            fi
                            
                            helm upgrade --install zookeeper-dm -n dm  . --values=values-${env.ENVIRONMENT}.yaml --create-namespace \${command_param}

                            echo "Waiting for pod to be ready..."
                            kubectl wait --namespace dm \
                            --for=condition=Ready pod \
                            --selector=app.kubernetes.io/component=zookeeper \
                            --timeout=300s
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