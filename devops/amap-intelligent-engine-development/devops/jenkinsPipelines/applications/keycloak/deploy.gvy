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
                        env.AWS_REGION=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.AWS_REGION").value' keycloakx.yaml ''' , returnStdout: true).trim()
                        env.EKS_CLUSTER_NAME=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.EKS_CLUSTER_NAME").value' keycloakx.yaml ''' , returnStdout: true).trim()
                        
                    }
                }
            }
        }
        stage('Configure Keycloak') {
            steps {
                dir("${workspace}/charts/keycloakx") {
                    sh """
                        export PATH=/usr/local/bin:$PATH

                        #set cluster  config
                        ../../devops/scripts/set-eks-cluster.sh ${env.AWS_REGION} ${env.EKS_CLUSTER_NAME} ${env.EKS_NAMESPACE}
                            
                        #update environment variables
                        python3 --version
                        python3 ../../devops/scripts/update_params.py ../../appconfig/${env.ENVIRONMENT}/keycloakx.yaml values-dm3.yaml values-${env.ENVIRONMENT}.yaml
                        
                        cat values-${env.ENVIRONMENT}.yaml

                    """
                }
            }
        }
        stage('Configure Credentials') {
            steps {
                dir("${workspace}/charts/keycloakx") {
                    script {
                        credential_id="keycloak_db_password_${env.ENVIRONMENT}"
                        withCredentials([
                        usernamePassword(
                        credentialsId: "${credential_id}",
                            passwordVariable: 'KEYCLOAK_DB_PASSWORD',
                            usernameVariable: 'KEYCLOAK_DB_USER')]) {

                        //sh(script: "/bin/bash -c 'kubectl create secret generic keycloakx-dm-keycloak-db-password -n dm --from-literal=password='${KEYCLOAK_DB_PASSWORD}' --dry-run=client -o yaml | kubectl apply -f -'", returnStdout: true)
                        sh "sed -i 's/PARAMS.KEYCLOAK_DB_PASSWORD/$KEYCLOAK_DB_PASSWORD/g' values-${env.ENVIRONMENT}.yaml"
                        }


                        credential_id="keycloak_app_admin_user_password_${env.ENVIRONMENT}"
                        withCredentials([
                        usernamePassword(
                        credentialsId: "${credential_id}",
                            passwordVariable: 'KEYCLOAK_APP_ADMIN_PASSWORD',
                            usernameVariable: 'KEYCLOAK_APP_ADMIN_USER')]) {

                        //sh(script: "/bin/bash -c 'kubectl create secret generic keycloakx-dm-keycloak-admin-password -n dm --from-literal=password='${KEYCLOAK_APP_ADMIN_PASSWORD}' --dry-run=client -o yaml | kubectl apply -f -'", returnStdout: true)
                        sh "sed -i 's/PARAMS.KEYCLOAK_APP_ADMIN_PASSWORD/$KEYCLOAK_APP_ADMIN_PASSWORD/g' values-${env.ENVIRONMENT}.yaml"
                        }
                    }
                }
            }
        }         
        stage('Install Keycloak') {
            steps {
                dir("${workspace}/charts/keycloakx") {
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

                        helm upgrade --install keycloakx-dm . -n dm --values=values-${env.ENVIRONMENT}.yaml  --create-namespace \${command_param}

                        kubectl wait --namespace dm --for=condition=Ready pod \
                        --selector=app.kubernetes.io/instance=keycloakx-dm \
                        --timeout=600s
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
