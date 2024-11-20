#!/bin/bash

su - ec2-user

# Deploying Jenkins server

### Standalone version
sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade -y
#install java
sudo dnf update
#intall java 17
sudo yum install java-17-amazon-corretto.x86_64 -y

#install maven
sudo yum install maven -y

sudo yum install jenkins -y
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins
## copy  CLI 
sudo  wget http://localhost:8080/jnlpJars/jenkins-cli.jar


#login
password=`sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$password  who-am-i

#install plugins

plugins="workflow-aggregator
timestamper
credentials-binding
ant
cloudbees-folder
antisamy-markup-formatter
build-timeout
ws-cleanup
gradle
github-branch-source
pipeline-github-lib
pipeline-stage-view
git
matrix-auth
pam-auth
ldap
email-ext
mailer
ssh-slaves
aws-credentials
blueocean
docker-plugin
multiselect-parameter
"

for item in $plugins; do
    java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$password  install-plugin  $item
done


java -jar jenkins-cli.jar -s http://localhost:8080/ -auth username:password safe-restart

# Install git 
sudo yum install git -y


# Install jq 
sudo yum install jq -y

# install yq
sudo wget -q https://github.com/mikefarah/yq/releases/download/v4.13.0/yq_linux_amd64.tar.gz -O- | tar zxv
sudo mv yq_linux_amd64 /usr/local/bin/yq

# Install terraform
sudo wget -q https://releases.hashicorp.com/terraform/1.5.6/terraform_1.5.6_linux_amd64.zip
sudo unzip terraform_1.5.6_linux_amd64.zip
sudo chmod +x terraform
sudo mv terraform /usr/local/bin

#install kubectl
sudo wget -q https://dl.k8s.io/release/v1.27.0/bin/linux/amd64/kubectl
sudo install kubectl /usr/local/bin/kubectl

#install helm 
wget -q https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 -O get_helm.sh
chmod 700 get_helm.sh
export HELM_INSTALL_DIR=/usr/local/bin
export USE_SUDO="true"
./get_helm.sh

#Install docker

sudo dnf update
sudo dnf install docker
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker
sudo usermod -a -G docker ec2-user
sudo usermod -a -G docker jenkins
newgrp docker
sudo chkconfig docker on
sudo reboot

# sudo amazon-linux-extras install docker -y
# sudo service docker start
# sudo usermod -a -G docker ec2-user
# sudo usermod -a -G docker jenkins
# newgrp docker
# sudo chkconfig docker on
# sudo reboot


