pipeline {
    agent any

    environment{
        BRANCH_NAME="${env.GIT_BRANCH.split('/').size() == 1 ? env.GIT_BRANCH.split('/')[-1] : env.GIT_BRANCH.split('/')[1..-1].join('/')}"
        EKS_NAMESPACE="default"
    }

    parameters {
        string(name: 'AIRFLOW_VERSION', defaultValue: '2.6.2-python3.10', description: 'Airflow version for base image')
        string(name: 'AIRFLOW_TAG_EXTRAS', defaultValue: 'custom-v0.1', description: 'Airflow image tag extra string')
    }
    stages {
        stage("Checkout Repo") {
            steps { 
                    cleanWs()
                    checkout scm
          }
        }
        stage('Install Prereqs') {
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
        stage('Create Image') {
            steps {
                    script {
                        dir("${workspace}/dockers/airflow") {
                            // Remove the slash on the branch name so we can use the branch as part of the tag
                            def getEscapedValue = '''
                                echo $BRANCH_NAME | sed 's#/#-#g'
                            '''
                            ESCAPED = sh(script: getEscapedValue, returnStdout: true).trim()
                            sh """
                                sed -i 's#PARAMS.AIRFLOW_VERSION#${params.AIRFLOW_VERSION}#g' Dockerfile_standard
                                docker build -t ${env.ECR_REPO}/airflow:${params.AIRFLOW_VERSION}-${params.AIRFLOW_TAG_EXTRAS} -f Dockerfile_standard .
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
                            docker push ${env.ECR_REPO}/airflow:${params.AIRFLOW_VERSION}-${params.AIRFLOW_TAG_EXTRAS}
                        """
                        // Clean up docker images from Jenkins machine
                        sh '''
                            #docker system prune -af
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


