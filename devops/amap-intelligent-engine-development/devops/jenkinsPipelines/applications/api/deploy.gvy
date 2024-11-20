pipeline {
    agent any
    environment{
        BRANCH_NAME="${env.GIT_BRANCH.split('/').size() == 1 ? env.GIT_BRANCH.split('/')[-1] : env.GIT_BRANCH.split('/')[1..-1].join('/')}"
        EKS_NAMESPACE="default"
    }
    parameters {
        string(name: 'ORDER_MANAGEMENT_TAG', defaultValue: 'CHANGE ME!!!', description: 'Tag to use for order-management')
        string(name: 'INVENTORY_MANAGEMENT_TAG', defaultValue: 'CHANGE ME!!!', description: 'Tag to use for inventory-management')
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
                        env.ORDER_MANAGEMENT_REPO=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.ORDER_MANAGEMENT_REPO").value' api.yaml ''' , returnStdout: true).trim()
                        env.INVENTORY_MANAGEMENT_REPO=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.INVENTORY_MANAGEMENT_REPO").value' api.yaml ''' , returnStdout: true).trim()
                        env.AWS_REGION=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.AWS_REGION").value' api.yaml ''' , returnStdout: true).trim()
                        env.EKS_CLUSTER_NAME=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.EKS_CLUSTER_NAME").value' api.yaml ''' , returnStdout: true).trim()
                        
                    }
                }
            }
        } 
        stage('Configure Api Layer') {
            steps {
                dir("${workspace}/charts/api") {
                    sh """
                        export PATH=/usr/local/bin:$PATH

                        #set cluster  config
                        ../../devops/scripts/set-eks-cluster.sh ${env.AWS_REGION} ${env.EKS_CLUSTER_NAME} ${env.EKS_NAMESPACE}
                            
                        #update environment variables
                        python3 --version
                        python3 ../../devops/scripts/update_params.py ../../appconfig/${env.ENVIRONMENT}/api.yaml values-dm3.yaml values-${env.ENVIRONMENT}.yaml
                        
                        #add current tag to chart
                        sed -i 's/PARAMS.ORDER_MANAGEMENT_TAG/${params.ORDER_MANAGEMENT_TAG}/g' values-${env.ENVIRONMENT}.yaml
                        sed -i 's/PARAMS.INVENTORY_MANAGEMENT_TAG/${params.INVENTORY_MANAGEMENT_TAG}/g' values-${env.ENVIRONMENT}.yaml

                        cat values-${env.ENVIRONMENT}.yaml
                    """
                }
            }
        }
        stage('Configure Credentials') {
            steps {
                dir("${workspace}/charts/api") {
                    script {
                        echo "Setting credentials in env"
                        credential_id="api_user_password_${env.ENVIRONMENT}"
                        withCredentials([usernamePassword(
                              credentialsId: "${credential_id}",
                              usernameVariable: 'API_DB_USER',
                              passwordVariable: 'API_DB_PASS')
                            ]) {
                            sh "sed -i 's/PARAMS.API_DB_PASS/$API_DB_PASS/g' values-${env.ENVIRONMENT}.yaml"
                        } 
                    }
                }
            }
        } 
        stage('Install API Layer') {
            steps {
                dir("${workspace}/charts/api") {
                    script {
                        sh """
                            export PATH=/usr/local/bin:$PATH

                            if [ ${params.DoYouWantDryRun} == false ]; then
                                echo "Performing without --dry-run"
                                command_param=""
                            else
                                echo "Performing with --dry-run"
                                command_param="--dry-run"
                            fi

                            helm upgrade -i -n dm dm3-api . --values=values-${env.ENVIRONMENT}.yaml \${command_param}
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