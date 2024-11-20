pipeline {
    agent any
    environment {
        BRANCH_NAME="${env.GIT_BRANCH.split('/').size() == 1 ? env.GIT_BRANCH.split('/')[-1] : env.GIT_BRANCH.split('/')[1..-1].join('/')}"
    }
    // parameters {
    //     string(name: 'ENV', defaultValue: 'dev', description: 'AWS credentials to use for the build') 
    //     }
    stages {
        stage("Checkout Repo") {
          steps {
            cleanWs()
            checkout scm
          }
        }
        stage("Install prereqs") {
            steps {
                script {
                    echo "Detecting branch"
           
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
                }
            }
        }
        stage("Terraform  Init") {
            steps {
                script {
                    dir("${workspace}/devops/terraform") {
                        sh """
                            terraform  init -upgrade  -backend-config=config/${env.ENVIRONMENT}/backend.tfvars 
                            chmod -R +x .terraform
                        """
                    }
                }
            }
        }
        stage("Terraform  Validate") {
            steps {
                script {
                    dir("${workspace}/devops/terraform") {
                        sh """
                            terraform  validate
                        """
                    }
                }
            }
        }
        stage("Terraform  Plan") {
            steps {
                script {
                    dir("${workspace}/devops/terraform") {
                        sh """
                            terraform plan -var-file="./globals_${env.ENVIRONMENT}.tfvars"
                        """
                    }
                }
            }
        }
        stage('Confirm Apply') {
          steps {
            script {
              def userInput = input(
                  id: 'userInput', message: 'This is Apply Step!', parameters: [
                  [$class: 'BooleanParameterDefinition', defaultValue: false, description: '', name: 'Please confirm you sure to proceed']
              ])

              if(!userInput) {
                  error "Build wasn't confirmed"
              }
            }
          }

        }
        stage("Terraform  Apply") {
            steps {
                script {
                    dir("${workspace}/devops/terraform") {
                        sh """
                            terraform apply -auto-approve -var-file="./globals_${env.ENVIRONMENT}.tfvars"
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