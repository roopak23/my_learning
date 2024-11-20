pipeline {
    agent any
    environment{
        BRANCH_NAME="${env.GIT_BRANCH.split('/').size() == 1 ? env.GIT_BRANCH.split('/')[-1] : env.GIT_BRANCH.split('/')[1..-1].join('/')}"
        EKS_NAMESPACE="default"
    }
    parameters {
        string(name: 'TAG', defaultValue: 'latest', description: 'Nifi image tag to use')
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
                    echo "Setting credentials in env"
                       
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
                        env.AWS_REGION=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.AWS_REGION").value' nifi.yaml ''' , returnStdout: true).trim()
                        env.EKS_CLUSTER_NAME=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.EKS_CLUSTER_NAME").value' nifi.yaml ''' , returnStdout: true).trim()
                        env.S3_APP_BUCKET_NAME=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.S3_APP_BUCKET_NAME").value' nifi.yaml ''' , returnStdout: true).trim()
                        env.CLUSTER_MODE=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.CLUSTER_MODE").value' nifi.yaml ''' , returnStdout: true).trim()
                    }
                }
            }
        }
        stage("Copy Nifi scripts to target S3") {
            steps {
                script {
                    // upload to target client bucket - this defaults to taking the files from the development branch
                    // TODO: add branch parameter so we can take google_json from somewhere other than development branch
                    dir("${workspace}/Run/Nifi/Phase1/Scripts") {
                        sh """
                            export PATH=/home/jenkins/.local/bin:$PATH
                            aws s3 sync . s3://${env.S3_APP_BUCKET_NAME}/app/NiFi/development
                        """
                    }
                    //dir("${workspace}/AMAP_Data_Monetisation/Run/Nifi/Phase1/data") {
                    //    sh """
                    //        aws s3 sync . s3://${params.S3_APP_BUCKET_NAME}/app/NiFi/data
                    //    """
                    //}
                }
            }
        }
        stage("Configure Nifi") {
           steps {
                script {
                    dir("${workspace}/charts/nifi") {
                        sh """
                            export PATH=/usr/local/bin:$PATH

                            if [ ${env.CLUSTER_MODE} == false ]; then
                                echo "Installing in single mode"
                                values_file="values-dm3.yaml"
                            else
                                echo "Installing in cluster mode"
                                values_file="values-cluster.yaml"
                            fi

                            #set cluster  config
                            ../../devops/scripts/set-eks-cluster.sh ${env.AWS_REGION} ${env.EKS_CLUSTER_NAME} ${env.EKS_NAMESPACE}
                            
                            #update environment variables
                            python3 --version
                            python3 ../../devops/scripts/update_params.py ../../appconfig/${env.ENVIRONMENT}/nifi.yaml \${values_file} values-${env.ENVIRONMENT}.yaml

                            #configure gocker image TAG
                            sed -i 's/PARAMS.TAG/${params.TAG}/g' values-${env.ENVIRONMENT}.yaml
                            cat values-${env.ENVIRONMENT}.yaml

                        """
                    }
                }
            }
        }
      stage('Configure Credentials') {
            steps {
                dir("${workspace}/charts/nifi") {
                    script {
                        echo "Setting credentials in env"

                        credential_id="nifi_keycloak_secret_${env.ENVIRONMENT}"
                        withCredentials([
                        usernamePassword(
                        credentialsId: "${credential_id}",
                            passwordVariable: 'KEYCLOAK_SECRET',
                            usernameVariable: 'KEYCLOAK_USER')]) {

                        sh "sed -i 's|PARAMS.KEYCLOAK_SECRET|${KEYCLOAK_SECRET}|g' values-${env.ENVIRONMENT}.yaml"
                        }
                    }
                }
            }
        } 
        stage("Deploy Nifi") {
            steps {
                script {
                    dir("${workspace}/charts/nifi") {
                        sh """
                            export PATH=/home/jenkins/.local/bin:$PATH

                            #helm repo add celtic https://cetic.github.io/helm-charts
                            #helm repo update
                            #helm upgrade --install nifi-dm celtic/nifi --version="0.6.1" -n dm --values=values-${env.ENVIRONMENT}.yaml --create-namespace --dry-run
                            


                            if [ ${params.DoYouWantDryRun} == false ]; then
                                echo "Performing without --dry-run"
                                command_param=""
                            else
                                echo "Performing with --dry-run"
                                command_param="--dry-run"
                            fi

                            if [ ${env.ENVIRONMENT} == "dev" ]; then
                                nifi_release="nifi-dm"
                            else
                                nifi_release="nifi-dm"
                            fi

                            helm upgrade \${nifi_release} .  -n dm --install  --values=values-${env.ENVIRONMENT}.yaml --create-namespace \${command_param}
                            
                            kubectl wait --namespace dm \
                            --for=condition=Ready pod \
                            --selector=app=nifi \
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