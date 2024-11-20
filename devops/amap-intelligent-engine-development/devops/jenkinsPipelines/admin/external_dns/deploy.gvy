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
                    
                    dir("${workspace}/appconfig/${env.ENVIRONMENT}") {
                        env.AWS_REGION=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.AWS_REGION").value' external-dns.yaml ''' , returnStdout: true).trim()
                        env.EKS_CLUSTER_NAME=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.EKS_CLUSTER_NAME").value' external-dns.yaml ''' , returnStdout: true).trim()
                        
                    }
                }
            }
        }
        stage("Configure external-dns") {
            steps {
                dir("${workspace}/charts/external-dns") {
                    script {
                        sh """

                            export PATH=/usr/local/bin:$PATH
                            
                            #set cluster config
                            ../../devops/scripts/set-eks-cluster.sh ${env.AWS_REGION}  ${env.EKS_CLUSTER_NAME} ${env.EKS_NAMESPACE}
                            
                            #update environment variables
                            python3 --version
                            python3 ../../devops/scripts/update_params.py ../../appconfig/${env.ENVIRONMENT}/external-dns.yaml values-dm3.yaml values-${env.ENVIRONMENT}.yaml 
                            
                            cat values-${env.ENVIRONMENT}.yaml 

                        """
                    }
                }
            }
        }
        stage("Install external-dns") {
            steps {
                dir("${workspace}/charts/external-dns") {
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

                            helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
                            helm repo update
                            helm upgrade --install external-dns external-dns/external-dns --version=1.13.0 --values=values-${env.ENVIRONMENT}.yaml \${command_param}
                            kubectl wait \
                            --for=condition=Ready pod \
                            --selector=app.kubernetes.io/name=external-dns \
                            --timeout=180s
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