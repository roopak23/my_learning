#!/bin/bash

# Install AWS CLI

echo ~
echo $PATH
ls ~
INSTALL_HOME=~
INSTALL_HOME_BIN=$INSTALL_HOME/.local/bin
mkdir -p $INSTALL_HOME_BIN
uname -a

curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o  awscliv2.zip
unzip -q awscliv2.zip

./aws/install -b  $INSTALL_HOME_BIN  -i $INSTALL_HOME/.local/aws-cli
# Install KubeCTL
curl -LO https://dl.k8s.io/release/v1.21.0/bin/linux/amd64/kubectl

install kubectl $INSTALL_HOME_BIN/kubectl

# Install Helm

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
export HELM_INSTALL_DIR=$INSTALL_HOME_BIN
export USE_SUDO="false"
./get_helm.sh

#install yq

curl -L https://github.com/mikefarah/yq/releases/download/v4.13.0/yq_linux_amd64.tar.gz | tar zxv


mv yq_linux_amd64 $INSTALL_HOME_BIN/yq

#install pyyaml
python3 -m pip install --user pyyaml
python3 --version








