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
                        env.ECR_REPO=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.ECR_REPO").value' nifi.yaml ''' , returnStdout: true).trim()
                        
                    }
                }
            }
        }
        stage('Create Image') {
            steps {
                script {
                    dir("${workspace}/dockers/nifi") {
                        // Remove the slash on the branch name so we can use the branch as part of the tag
                        env.BRANCH="${env.BRANCH_NAME}"
                        def getEscapedValue = '''
                            echo $BRANCH | sed 's#/#-#g'
                        '''
                        ESCAPED = sh(script: getEscapedValue, returnStdout: true).trim()

                        env.NIFI_TAG="${ESCAPED}-${now}"

                        sh """
                            docker build -t  ${env.ECR_REPO}/nifi:${env.NIFI_TAG} .
                        """
                    }
                }
            }
        }
        stage('Get ECR credentials') {
            steps {
                script {
                    sh """
                        aws ecr get-login-password --region ${env.AWS_REGION} > awspass
                    """
                }
            }
        }

        stage('Push image') {
            steps {
                script {
                    sh """
                        cat awspass | docker login --username AWS --password-stdin ${env.ECR_REPO}/nifi

                        docker push ${env.ECR_REPO}/nifi:${env.NIFI_TAG}
                    """
                    // Clean up docker images from Jenkins machine
                    sh '''
                        docker system prune -af
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
