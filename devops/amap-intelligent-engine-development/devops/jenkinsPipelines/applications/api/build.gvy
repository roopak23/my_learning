def now = new Date().format("ddMMyyy-HHmmss")

pipeline {
    agent any
    environment{
        BRANCH_NAME="${env.GIT_BRANCH.split('/').size() == 1 ? env.GIT_BRANCH.split('/')[-1] : env.GIT_BRANCH.split('/')[1..-1].join('/')}"
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
                        
                    }
                }
            }
        } 
        stage('Install Maven') {
            steps {
                script {
                    echo "Install Maven"
                sh  """
                    mvn -version
                    """
                }
            }
        }
		stage('Install Java 17') {
            steps {
                script {
                    sh  """
                        java -version
                    """
                }
            }
        }
        // javaApi/DM3-Microservices/inventory-management
        stage('Building application') {
            steps {
                script {
                    dir("${workspace}/javaApi/DM3-Microservices") {
                        sh """
                            #echo \$PATH
                            #JAVA_HOME="/opt/jdk-11.0.2"
                            #PATH="\$JAVA_HOME/bin:\$PATH"
                            #export PATH
                            #export JAVA_HOME
							#JAVA_HOME="/home/jenkins/jdk-17"
                            #export JAVA_HOME
                            #PATH="\$JAVA_HOME/bin:\$PATH"
                            #export PATH
                            #java -version
                            echo \$JAVA_HOME
                            echo \$PATH
                            sed -i 's/\\\\/\\//g' pom.xml
                            mvn clean install
                            mvn -Ddeploy-with=helm clean install
                            cp ${workspace}/javaApi/DM3-Microservices/inventory-management/target/inventory-management-0.0.1-SNAPSHOT.jar ${workspace}/javaApi/DM3-Microservices/target/deliverables/micro-services/inventory-management

                            cp ${workspace}/javaApi/DM3-Microservices/order-management/target/order-management-0.0.1-SNAPSHOT.jar ${workspace}/javaApi/DM3-Microservices/target/deliverables/micro-services/order-management
                        """
                    }
                }
            }
        }
        stage('Building image') {
            steps {
                    script {
                        def getEscapedValue = '''
                            echo $BRANCH_NAME | sed 's#/#-#g'
                        '''
                        ESCAPED = sh(script: getEscapedValue, returnStdout: true).trim()
                         
                        env.INVENTORY_MANAGEMENT_TAG="${ESCAPED}-${now}"
                        //TAGS will be  be the same
                        env.ORDER_MANAGEMENT_TAG=env.INVENTORY_MANAGEMENT_TAG

                        
                        dir("${workspace}/javaApi/DM3-Microservices/target/deliverables/micro-services/inventory-management") {
                            sh """
                                docker build -t ${env.INVENTORY_MANAGEMENT_REPO}:${env.INVENTORY_MANAGEMENT_TAG} .
                            """
                        }
                        dir("${workspace}/javaApi/DM3-Microservices/target/deliverables/micro-services/order-management") {
                            sh """
                                docker build -t ${env.ORDER_MANAGEMENT_REPO}:${env.ORDER_MANAGEMENT_TAG} .
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
                            cat awspass | docker login --username AWS --password-stdin ${env.INVENTORY_MANAGEMENT_REPO}
                            docker push ${env.INVENTORY_MANAGEMENT_REPO}:${env.INVENTORY_MANAGEMENT_TAG}

                            cat awspass | docker login --username AWS --password-stdin ${env.ORDER_MANAGEMENT_REPO}
                
                            docker push ${env.ORDER_MANAGEMENT_REPO}:${env.ORDER_MANAGEMENT_TAG}

                            #docker system prune -af
                        """
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