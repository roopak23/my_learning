pipeline {
    agent any

    stages {
        stage('Build Airflow') {
            steps {
                script{
                def buildResults = build job: 'buildAirflow', 
                                               parameters: [],
                                               wait: true
                env.AIRFLOW_TAG = buildResults.getBuildVariables()["AIRFLOW_TAG"]
                }
            }
        }
        stage('Deploy Airflow') {
            steps {
                //Wait for the docker image to be properly pushed.
                sleep(time:10,unit:"SECONDS")
                build job: 'deployAirflow', parameters: [
                    string(name: 'IMAGE_TAG', value: env.AIRFLOW_TAG)
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
