#!/bin/bash

AWS_REGION=$1
EKS_CLUSTER_NAME=$2
EKS_NAMESPACE=$3

aws eks --region $AWS_REGION update-kubeconfig --name $EKS_CLUSTER_NAME
kubectl config set-context --current --namespace=$EKS_NAMESPACE
