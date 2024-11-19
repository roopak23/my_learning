pipeline {
    agent any

    stages {
        stage('Build Nifi') {
            steps {
                script{
                def buildResults = build job: 'buildNifi', 
                                               parameters: [],
                                               wait: true
                env.NIFI_TAG = buildResults.getBuildVariables()["NIFI_TAG"]
                }
            }
        }
        stage('Deploy Nifi') {
            steps {
                //Wait for the docker image to be properly pushed.
                sleep(time:10,unit:"SECONDS")
                build job: 'deployNifi', parameters: [
                    string(name: 'TAG', value: env.NIFI_TAG)
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
