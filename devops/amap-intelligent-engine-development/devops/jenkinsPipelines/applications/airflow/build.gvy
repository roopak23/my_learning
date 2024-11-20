def now = new Date().format("ddMMyyy-HHmmss")

pipeline {
    agent any

   environment{
        BRANCH_NAME="${env.GIT_BRANCH.split('/').size() == 1 ? env.GIT_BRANCH.split('/')[-1] : env.GIT_BRANCH.split('/')[1..-1].join('/')}"
        EKS_NAMESPACE="default"
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
                        env.ECR_REPO=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.ECR_REPO").value' airflow.yaml ''' , returnStdout: true).trim()
                        
                    }
                }
            }
        }
        stage('Prepare cluster template') {
            steps {
                script {
                    // TODO: Add parameter for the whole KMS Arn to make sure it includes the AWS account number when applying to install-segtool-emr.sh                    dir("${workspace}/Run/Airflow/dags/scripts/cluster") {
                    dir("${workspace}/Run/Airflow/dags/scripts/cluster") {
                        sh """

                            export PATH=/usr/local/bin:$PATH
       
                            #update cluster variables
                            python3 --version
                            python3 ../../../../../devops/scripts/update_params.py ../../../../../appconfig/${env.ENVIRONMENT}/airflow.yaml aws_cluster_template.yaml aws_cluster_template.yaml

                            cat aws_cluster_template.yaml
                        """
                    }

                    dir("${workspace}/Run/Airflow/dags/scripts/cluster") {
                        
                        script {
                            echo "Setting credentials in env"
                            credential_id="hive_metastore_password_${env.ENVIRONMENT}"
                            withCredentials([usernamePassword(
                                credentialsId: "${credential_id}",
                                usernameVariable: 'HIVE_DB_USER',
                                passwordVariable: 'HIVE_DB_USER_PASSWORD')
                                ]) {
                                sh "sed -i 's/PARAMS.HIVE_DB_USER_PASSWORD/$HIVE_DB_USER_PASSWORD/g' aws_cluster_template.yaml"
                            } 
                        }                         
                    }

                    dir("${workspace}/Run/Spark/Batch/Ingestion") {
                        sh """
                            export PATH=/usr/local/bin:$PATH

                            #update ingestion variables
                            python3 --version
                            python3 ../../../../devops/scripts/update_params.py ../../../../appconfig/${env.ENVIRONMENT}/airflow.yaml ingestion.yaml ingestion.yaml

                            cat ingestion.yaml

                        """
                    }
                    dir("${workspace}/Run/Airflow/dags/scripts/batch") {
                        sh """
                            export PATH=/usr/local/bin:$PATH
                            
                            #update ingestion variables
                            python3 --version
                            python3 ../../../../../devops/scripts/update_params.py ../../../../../appconfig/${env.ENVIRONMENT}/airflow.yaml variables.yaml variables.yaml

                            cat variables.yaml

                        """
                    }

                    dir("${workspace}/dockers/airflow") {
                        sh """
                          export PATH=/usr/local/bin:$PATH
                            
                          #update ingestion variables
                          python3 --version
                          python3 ../../devops/scripts/update_params.py ../../appconfig/${env.ENVIRONMENT}/airflow.yaml Dockerfile Dockerfile

                        cat Dockerfile

                        """
                    }

                    dir("${workspace}/Run/Airflow/dags/scripts/model_manager") {
                        sh """
                          export PATH=/usr/local/bin:$PATH
                            
                          #update ml manager
                          python3 --version
                          python3 ../../../../../devops/scripts/update_params.py ../../../../../appconfig/${env.ENVIRONMENT}/airflow.yaml variables.yaml variables.yaml

                        cat variables.yaml
                        """
                    }
           
                }
            }
        }
        stage('Create Image') {
            steps {
                    script {
                        dir("${workspace}/dockers/airflow") {
                            sh """
                            aws ecr get-login-password --region ${env.AWS_REGION} > awspass
                            """
                        }
                    }
                    script {
                        dir("${workspace}/dockers/airflow") {
                            // Remove the slash on the branch name so we can use the branch as part of the tag
                            env.BRANCH="${env.BRANCH_NAME}"
                            def getEscapedValue = '''
                                echo $BRANCH | sed 's#/#-#g'
                            '''
                            ESCAPED = sh(script: getEscapedValue, returnStdout: true).trim()
                            env.AIRFLOW_TAG="${ESCAPED}-${now}"

                            sh """
                                sed -i 's/my_aws/aws_default/g' ${workspace}/Run/Airflow/dags/aws_create_cluster.py
                                sed -i 's/my_aws/aws_default/g' ${workspace}/Run/Airflow/dags/aws_terminate_cluster.py

                                cp -r ${workspace}/Run/Airflow/dags .
                                cp -r ${workspace}/Run/Spark .
                                cat awspass | docker login --username AWS --password-stdin ${env.ECR_REPO}
                                docker build -t ${env.ECR_REPO}/airflow:${env.AIRFLOW_TAG} -f Dockerfile .
                            """
                        }
                    }
                    script {
                        sh """
                        aws ecr get-login-password --region ${env.AWS_REGION} > awspass
                        """
                    }
            }
        }
        stage('Push Image') {
            steps {
                script {
                    sh """
                        cat awspass | docker login --username AWS --password-stdin ${env.ECR_REPO}
                        docker push ${env.ECR_REPO}/airflow:${env.AIRFLOW_TAG}
                    """
                    // Clean up docker images from Jenkins machine
                    sh '''
                        # docker system prune -af
                    '''
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


