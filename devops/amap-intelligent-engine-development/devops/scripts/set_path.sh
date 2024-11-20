#!/bin/bash

JEN_HOME=/tmp/jenkins_home
CLI_HOME=$JEN_HOME/aws-cli


export PATH="$CLI_HOME:$PATH"
export PATH="$CLI_HOME/bin:$PATH"

KUB_HOME=$JEN_HOME/kubectl
export PATH="$KUB_HOME:$PATH"


HELM_INSTALL_DIR=$JEN_HOME/helm
export PATH="$HELM_INSTALL_DIR:$PATH"


YQ_HOME=$JEN_HOME/yq
export PATH="$YQ_HOME:$PATH"

