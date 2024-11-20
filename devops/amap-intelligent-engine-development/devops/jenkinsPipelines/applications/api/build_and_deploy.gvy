pipeline {
    agent any

    stages {
        stage('Build Api') {
            steps {
                script{
                def buildResults = build job: 'buildApi', 
                                               parameters: [],
                                               wait: true
                env.API_ORDER_MANAGEMENT_TAG = buildResults.getBuildVariables()["ORDER_MANAGEMENT_TAG"]
                env.API_INVENTORY_MANAGEMENT_TAG = buildResults.getBuildVariables()["INVENTORY_MANAGEMENT_TAG"]
                }
            }
        }
        stage('Deploy Api') {
            steps {
                //Wait for the docker image to be properly pushed.
                sleep(time:10,unit:"SECONDS")
                build job: 'deployApi', parameters: [
                    string(name: 'ORDER_MANAGEMENT_TAG', value: env.API_ORDER_MANAGEMENT_TAG),
                    string(name: 'INVENTORY_MANAGEMENT_TAG', value: env.API_INVENTORY_MANAGEMENT_TAG)
                ]
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
