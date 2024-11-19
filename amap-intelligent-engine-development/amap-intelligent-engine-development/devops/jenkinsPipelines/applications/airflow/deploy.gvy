pipeline { 
    agent any
    environment{
        BRANCH_NAME="${env.GIT_BRANCH.split('/').size() == 1 ? env.GIT_BRANCH.split('/')[-1] : env.GIT_BRANCH.split('/')[1..-1].join('/')}"
        EKS_NAMESPACE="default"
    }
    parameters {
        string(name: 'IMAGE_TAG', defaultValue: 'CHANGE ME !!!', description: 'Airflow ECR repo tag to use')
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
                        env.AWS_REGION=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.AWS_REGION").value' airflow.yaml ''' , returnStdout: true).trim()
                        env.EKS_CLUSTER_NAME=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.EKS_CLUSTER_NAME").value' airflow.yaml ''' , returnStdout: true).trim()
                        env.S3_APP_BUCKET_NAME=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.S3_APP_BUCKET_NAME").value' airflow.yaml ''' , returnStdout: true).trim()
                        
                    }
                }
            }
        }
        stage("Copy bootstrap scripts to S3 bucket") {
            steps {
                // Copies the bootstrap scripts to the target S3 bucket. These scripts will be run when creating an EMR cluster
                dir("${workspace}/Run/Spark/Setup") {

                    sh """
                        echo $PATH
                        aws s3 sync . s3://${env.S3_APP_BUCKET_NAME}/app/Spark/Setup
                    """
                }
            }
        }
        stage('Configure Airflow') {
            steps {
                dir("${workspace}/charts/airflow") {
                    script {
                        // secret key can contain slashes that would need to be escaped so that sed can replace.
                        // def getEscapedValue = '''
                        //     echo $AWS_SECRET_ACCESS_KEY | sed 's/\\//\\\\\\//g'
                        // '''
                        // ESCAPED = sh(script: getEscapedValue, returnStdout: true).trim()
                        sh """
                            export PATH=/usr/local/bin:$PATH

                            #set cluster  config
                            ../../devops/scripts/set-eks-cluster.sh ${env.AWS_REGION} ${env.EKS_CLUSTER_NAME} ${env.EKS_NAMESPACE}
                                
                            #update environment variables
                            python3 --version
                            python3 ../../devops/scripts/update_params.py ../../appconfig/${env.ENVIRONMENT}/airflow.yaml values-dm3.yaml values-${env.ENVIRONMENT}.yaml
                            

                            # inject patameters
                            sed -i 's/PARAMS.IMAGE_TAG/${params.IMAGE_TAG}/g' values-${env.ENVIRONMENT}.yaml
                            
                            cat  values-${env.ENVIRONMENT}.yaml
                         
                        """

                    }
                }
            }
        }

        stage('Configure Credentials') {
            steps {
                dir("${workspace}/charts/airflow") {
                    script {
                        echo "Setting credentials in env"
                        credential_id="amap_airflow_git_url_${env.ENVIRONMENT}"
                        echo "Setting credentials in env test"
                        withCredentials([
                        usernamePassword(
                            credentialsId: "${credential_id}",
                            passwordVariable: 'AIRFLOW_GIT_URL_VALUE',
                            usernameVariable: 'AIRFLOW_GIT_URL')]) {

                        sh "sed -i 's|PARAMS.AIRFLOW_GIT_URL|${env.AIRFLOW_GIT_URL_VALUE}|g' values-${env.ENVIRONMENT}.yaml"
                        }


                        credential_id="amap_airflow_fernet_key_${env.ENVIRONMENT}"
                        withCredentials([
                        usernamePassword(
                            credentialsId: "${credential_id}",
                            passwordVariable: 'AIRFLOW_FERNET_KEY_VALUE',
                            usernameVariable: 'AIRFLOW_FERNET_KEY')]) {
                        sh "sed -i 's|PARAMS.AIRFLOW_FERNET_KEY|$AIRFLOW_FERNET_KEY_VALUE|g' values-${env.ENVIRONMENT}.yaml"
                        }
                        
                        credential_id="amap_airflow_webserver_secret_key_${env.ENVIRONMENT}"
                        withCredentials([
                        usernamePassword(
                            credentialsId: "${credential_id}",
                            passwordVariable: 'AIRFLOW_WEBSERVER_SECRET_KEY_VALUE',
                            usernameVariable: 'AIRFLOW_WEBSERVER_SECRET_KEY')]) {

                        sh "sed -i 's|PARAMS.AIRFLOW_WEBSERVER_SECRET_KEY|${AIRFLOW_WEBSERVER_SECRET_KEY_VALUE}|g' values-${env.ENVIRONMENT}.yaml"
                        }
                        
                        credential_id="amap_airflow_ssh_key_${env.ENVIRONMENT}"
                        withCredentials([
                        usernamePassword(
                        credentialsId: "${credential_id}",
                            passwordVariable: 'EMR_SSH_PRIVATE_KEY_VALUE',
                            usernameVariable: 'EMR_SSH_PRIVATE_KEY')]) {

                        sh "sed -i 's|PARAMS.EMR_SSH_PRIVATE_KEY|${EMR_SSH_PRIVATE_KEY_VALUE}|g' values-${env.ENVIRONMENT}.yaml"
                        }

                        credential_id="airflow_db_user_password_${env.ENVIRONMENT}"
                        withCredentials([
                        usernamePassword(
                        credentialsId: "${credential_id}",
                            passwordVariable: 'AIRFLOW_DB_PASS',
                            usernameVariable: 'AIRFLOW_DB_USER')]) {

                        sh "sed -i 's|PARAMS.AIRFLOW_DB_PASS|${AIRFLOW_DB_PASS}|g' values-${env.ENVIRONMENT}.yaml"
                        sh(script: "/bin/bash -c 'kubectl create secret generic mysql-database -n dm --from-literal=mysql-password='${AIRFLOW_DB_PASS}' --dry-run=client -o yaml | kubectl apply -f -'", returnStdout: true)
                        sh(script: "/bin/bash -c 'kubectl create secret generic airflow-redis -n dm --from-literal=password='${AIRFLOW_DB_PASS}' --dry-run=client -o yaml | kubectl apply -f -'",  returnStdout: true)
                        }

                        credential_id="mysql_password_for_etl_${env.ENVIRONMENT}"
                        withCredentials([
                        usernamePassword(
                        credentialsId: "${credential_id}",
                            passwordVariable: 'DB_ADMIN_PASS',
                            usernameVariable: 'DB_ADMIN_USER')]) {

                        sh "sed -i 's|PARAMS.DB_ADMIN_PASS|${DB_ADMIN_PASS}|g' values-${env.ENVIRONMENT}.yaml"
                        }

                        credential_id="airflow_admin_password_${env.ENVIRONMENT}"
                        withCredentials([
                        usernamePassword(
                        credentialsId: "${credential_id}",
                            passwordVariable: 'AIRFLOW_ADMIN_PASSWORD',
                            usernameVariable: 'AIRFLOW_ADMIN_USER')]) {

                        sh "sed -i 's|PARAMS.AIRFLOW_ADMIN_PASSWORD|${AIRFLOW_ADMIN_PASSWORD}|g' values-${env.ENVIRONMENT}.yaml"
                        }

                        credential_id="api_credentials_${env.ENVIRONMENT}"
                        withCredentials([
                        usernamePassword(
                        credentialsId: "${credential_id}",
                            passwordVariable: 'API_PASSWORD',
                            usernameVariable: 'API_USER')]) {

                        sh "sed -i 's|PARAMS.API_USER|${API_USER}|g' values-${env.ENVIRONMENT}.yaml"
                        sh "sed -i 's|PARAMS.API_PASSWORD|${API_PASSWORD}|g' values-${env.ENVIRONMENT}.yaml"
                        }
                    }
                }
            }
        } 
        stage('Install  Airflow') {
            steps {
                dir("${workspace}/charts/airflow") {
                    script {
                        // secret key can contain slashes that would need to be escaped so that sed can replace.
                        // def getEscapedValue = '''
                        //     echo $AWS_SECRET_ACCESS_KEY | sed 's/\\//\\\\\\//g'
                        // '''
                        // ESCAPED = sh(script: getEscapedValue, returnStdout: true).trim()
                        sh """
                            export PATH=/usr/local/bin:$PATH

                            #set cluster  config
                            ../../devops/scripts/set-eks-cluster.sh ${env.AWS_REGION} ${env.EKS_CLUSTER_NAME} ${env.EKS_NAMESPACE}

                            # add helm repos
                            # helm repo add airflow-stable https://airflow-helm.github.io/charts
                            # helm repo update

                            cat  values-${env.ENVIRONMENT}.yaml

                            if [ ${params.DoYouWantDryRun} == false ]; then
                                echo "Performing without --dry-run"
                                command_param=""
                            else
                                echo "Performing with --dry-run"
                                command_param="--dry-run"
                            fi

                            helm upgrade -i -n dm airflow-dm . --values=values-${env.ENVIRONMENT}.yaml \${command_param}
                        """
                        sh '''
                            while [ $(kubectl get pods airflow-dm-worker-0 -n dm -o "jsonpath={..status.containerStatuses[?(@.started)].started}") != true ]; do echo "waiting for pod" && sleep 1; done
                        '''
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