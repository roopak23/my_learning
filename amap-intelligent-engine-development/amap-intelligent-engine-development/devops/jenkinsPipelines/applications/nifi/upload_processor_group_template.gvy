def FLOW_FILES = []
def FLOW_FILE_NAMES = []
def DEFAULT_TEMPLATES = []

pipeline {
    agent any
    parameters {
        booleanParam(name: 'UploadContext', defaultValue: false, description: 'Check when 1st time run to upload paramters context when not exists')
        booleanParam(name: 'UploadDefaultTemplates', defaultValue: true, description: 'Upload a default set of templates')
    }
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
        stage('Install Prereqs') {
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
                        DEFAULT_TEMPLATES=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.DEFAULT_TEMPLATES").value' nifi.yaml ''' , returnStdout: true).trim()
                        env.AWS_REGION=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.AWS_REGION").value' nifi.yaml ''' , returnStdout: true).trim()
                        env.EKS_CLUSTER_NAME=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.EKS_CLUSTER_NAME").value' nifi.yaml ''' , returnStdout: true).trim()
                        env.PROCESS_GROUP_ID=sh(script: ''' yq  e  '.params[] | select(.name=="PARAMS.PROCESS_GROUP_ID").value' nifi.yaml ''' , returnStdout: true).trim()
                    }
                }
            }
        }
        stage('Pick Processor Groups to upload') {
            // Step to pick files to upload
            // Output comes as a string, so we split them into Array and then extract names only in a loop to prepare inputs for next stages.
            steps {
                dir("${workspace}/Run/Nifi/Phase1/Flows") {
                    script {
                        def UploadDefaultTemplates = params.UploadDefaultTemplates
                        if (UploadDefaultTemplates == false)
                        {
                            def FILE_LIST = sh (
                                script: "ls -m | tr -d ' '",
                                returnStdout: true
                            ).trim()
                            USER_INPUT = input(
                                id: 'userInput', message: 'Pick environment', 
                                parameters: [
                                    extendedChoice(name: 'PROCESSOR GROUP TEMPLATES', type: 'PT_MULTI_SELECT', value: FILE_LIST, descriptionPropertyValue: FILE_LIST, description: 'Pick templates to upload. Hold CTRL button to pick multiple values!', multiSelectDelimiter: ',', quoteValue: false, saveJSONParameterToFile: false)
                                    ]
                            )
                            FLOW_FILES = USER_INPUT.split(',')
                        }
                        else {
                            USER_INPUT = DEFAULT_TEMPLATES
                            FLOW_FILES = USER_INPUT.split(',')
                        }
                        FLOW_FILES.each{ file ->
                        FLOW_FILE_NAMES.add(file.split('\\.')[0])
                        }
                    }
                }
            }
        }
        stage('Copy cli.properties file to NiFi pod') {
            // Because Nifi is redeployed often there is a high probablity that cli.properties file will be missing
            // So first we extract changing values of properties from current deployment
            // Then update cli.properties files by swapping values with sed and copy file to correct directory
            steps {
                dir("${workspace}/devops/scripts/nifi") {
                    script {
                        sh """
                        export PATH=/usr/local/bin:$PATH
                        aws eks --region ${AWS_REGION} update-kubeconfig --name ${EKS_CLUSTER_NAME}
                        kubectl config set-context --current --namespace=default
                        
                        chmod +x ./prepare_cli.sh
                        
                        ./prepare_cli.sh ${EKS_CLUSTER_NAME}   ${AWS_REGION} 

                        #KEYSTORE=\$(kubectl exec -i -n dm nifi-dm-0 -c server -- grep -oP 'keystorePasswd=\\K(.*)' /opt/nifi/nifi-current/conf/nifi.properties)
                        #TRUSTSTORE=\$(kubectl exec -i -n dm nifi-dm-0 -c server -- grep -oP 'truststorePasswd=\\K(.*)' /opt/nifi/nifi-current/conf/nifi.properties)
                        # sed "s:keystorePasswd=.*:keystorePasswd=\$KEYSTORE:g" ./cli.properties | sed "s:keyPasswd=.*:keyPasswd=\$KEYSTORE:g" | sed "s:truststorePasswd=.*:truststorePasswd=\$TRUSTSTORE:g" > ./temp.properties
                        # rm ./cli.properties
                        # mv ./temp.properties ./cli.properties
                        
                        # kubectl cp -n dm cli.properties nifi-dm-0:/opt/nifi/nifi-toolkit-current/bin -c server
                        """
                    }
                }
            }
        }

        stage('Upload parameter context') {
            when {
                    expression { params.UploadContext == true }
                }
            steps {
                dir("${workspace}/devops/scripts/nifi") {
                    script {
                        sh """
                        chmod +x ./import_parameter_context.sh
                        ./import_parameter_context.sh
                        """
                    }
                }
            }
        }
        stage('Copy processor group file to NiFi pod') {
            // In this step processor group name is being edited to create unique template name
            // Then edited file is being copied into correct folder in Nifi pod
            steps {
                dir("${workspace}/Run/Nifi/Phase1/Flows") {
                    script {
                        def NOW = new Date().format("ddMMyyy-HHmmss")
                        FLOW_FILES.eachWithIndex{ file, idx ->
                            FLOW_NAME = FLOW_FILE_NAMES[idx] + "_" + NOW
                            sh """
                            export PATH=/usr/local/bin:$PATH
                            aws eks --region ${AWS_REGION} update-kubeconfig --name ${EKS_CLUSTER_NAME}
                            kubectl config set-context --current --namespace=default

                            sed "0,/<name>.*<\\/name>/ s/<name>.*<\\/name>/<name>${FLOW_NAME}<\\/name>/" ./${file} > ./temp.xml
                            rm ./${file}
                            mv ./temp.xml ./${file}
                            
                            kubectl cp -n dm ${file} nifi-dm-0:/opt/nifi/nifi-current/flowfile_repository -c server
                            """
                        }
                    }
                }
            }
        }
        stage('Import processor group') {
            // To import processor group processor group ID is needed
            // It's extracted using Nifi CLI and jq
            // At last new template is being uploaded to Nifi
            steps {
                script {
                    FLOW_FILES.eachWithIndex{ file, idx ->
                        sh """
                        export PATH=/usr/local/bin:$PATH
                        aws eks --region ${AWS_REGION} update-kubeconfig --name ${EKS_CLUSTER_NAME}
                        kubectl config set-context --current --namespace=default

                        PG_ID=${PROCESS_GROUP_ID} 

                        # PG=\$(kubectl exec -i -n dm nifi-dm-0 -c server -- /opt/nifi/nifi-toolkit-current/bin/cli.sh nifi pg-list -p /opt/nifi/nifi-toolkit-current/bin/cli.properties -ot json | jq -c -r '.[] | [{name, id}] | select(.[].name | contains("${FLOW_FILE_NAMES[idx]}"))')
                        # if [ -z "\$PG" ]
                        # then
                        #     PG_ID=\$(kubectl exec -i -n dm nifi-dm-0 -c server -- /opt/nifi/nifi-toolkit-current/bin/cli.sh nifi pg-list -p /opt/nifi/nifi-toolkit-current/bin/cli.properties -ot json | jq -c -r '.[0] | {name, id} | .id')
                        # else
                        #     PG_ID=\$(kubectl exec -i -n dm nifi-dm-0 -c server -- /opt/nifi/nifi-toolkit-current/bin/cli.sh nifi pg-list -p /opt/nifi/nifi-toolkit-current/bin/cli.properties -ot json | jq -c -r '.[] | [{name, id}] | select(.[].name | contains("${FLOW_FILE_NAMES[idx]}")) | .[].id')
                        # fi
                        # if [ -z "\$PG" ]  
                        # then  
                        #     PG_ID="0412045f-1541-4a7d-9581-f3f7c8acacc4"
                        # fi

                        echo "\$PG_ID"
                        
                        kubectl exec -i -n dm nifi-dm-0 -c server -- /opt/nifi/nifi-toolkit-current/bin/cli.sh nifi upload-template -p /opt/nifi/nifi-toolkit-current/bin/cli.properties -pgid \$PG_ID -i /opt/nifi/nifi-current/flowfile_repository/${file}
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
