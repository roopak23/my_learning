# Deploying Jenkins server

### Docker version
```
sudo amazon-linux-extras install docker -y
sudo usermod -a -G docker ec2-user
newgrp docker
sudo service docker start

docker run -d -v jenkins_home:/var/jenkins_home -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts-jdk11
```

### Standalone version
```
sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo yum upgrade -y

sudo amazon-linux-extras install epel -y
sudo amazon-linux-extras install java-openjdk11 -y

sudo yum install jenkins -y
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins
```

Install git 
```
sudo yum install git -y
```

Install jq 
```
sudo yum install jq -y
```

Install yq
```
curl -L https://github.com/mikefarah/yq/releases/download/v4.13.0/yq_linux_amd64.tar.gz | tar zxv
sudo mv yq_linux_amd64 /usr/bin/yq
```

Install docker
```
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo usermod -a -G docker jenkins
newgrp docker
sudo chkconfig docker on
sudo reboot
```

Install Kubectl
```
curl -LO https://dl.k8s.io/release/v1.21.0/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

Install Helm
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh -v v3.8.2
```

For API Layer build
Install default-jdk
Install maven

```
mkdir -p /usr/share/man/man1
sudo amazon-linux-extras install java-openjdk11
sudo yum install maven -y
```

### Add EKS access to Jenkins server
Adding EKS access to the Jenkins server would allow the user to bypass any Secret ID or Access Key requirements for AWs. 

Prerequisites:
- Deployed Jenkins server
- SSH access to Jenkins server
- Deployed Kubernetes cluster

1. Get the role arn from the Jenkins instance
  - ssh into the jenkins instance
  - `aws sts get-caller-identity`
  - copy the ARN of the role from the output
2. Copy the aws-auth configmap from the target cluster
  - `kubectl get configmap -n kube-system aws-auth -o yaml`
  - this outputs the configmap in yaml format
  - copy and save into a file
3. modify the aws-auth file to include the ARN role from the jenkins instance
  - Add the following:
  ```
    - "groups":
      - "system:masters"
      - "eks-console-dashboard-full-access-group"
      "rolearn": "arn:aws:iam::593561040426:role/amap-ec2-role-dev-01" - replace with the role from Jenkins
      "username": "amap-ec2-role-dev-01" - replace with the username
  ```
4. deploy the eks-console-full-access.yaml and the aws-auth.yaml
  - `kubectl apply -f eks-console-full-access.yaml`
  - `kubectl apply -f aws-auth.yaml`

#TEST2