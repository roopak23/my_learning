#!/bin/bash

EKS_CLUSTER=$1
AWS_REGION=$2

KEY_PASSWORD=""
TRUST_PASSWORD=""

[[ -z "$EKS_CLUSTER" ]] && { echo "Usage: ./prepare_cli.sh EKS_CLUSTER AWS_REGION" ; exit 1; }
[[ -z "$AWS_REGION" ]] && { echo "Usage: ./prepare_cli.sh EKS_CLUSTER AWS_REGION" ; exit 1; }

eksctl utils write-kubeconfig --cluster=${EKS_CLUSTER} --region=${AWS_REGION}
kubectl exec -i -n dm nifi-dm-0 -c server -- cat /opt/nifi/nifi-current/conf/nifi.properties | grep Passwd > temp.temp
KEY_PASSWORD=$(grep keystorePasswd temp.temp | cut -d= -f2)
TRUST_PASSWORD=$(grep truststorePasswd temp.temp | cut -d= -f2)

cat>cli.properties <<EOF
baseUrl=https://localhost:8443
keystore=/opt/nifi/nifi-current/conf/keystore.p12
keystoreType=PKCS12
keystorePasswd=REPLACE_KEY_PASSWORD
keyPasswd=REPLACE_KEY_PASSWORD
truststore=/opt/nifi/nifi-current/conf/truststore.p12
truststoreType=PKCS12
truststorePasswd=REPLACE_TRUST_PASSWORD
proxiedEntity=nifiuser
EOF

[[ -z "$KEY_PASSWORD" ]] && { echo "Password extraction failed" ; exit 1; }
[[ -z "$TRUST_PASSWORD" ]] && { echo "Password extraction failed" ; exit 1; }

echo $KEY_PASSWORD
echo $TRUST_PASSWORD

sed -i "s/REPLACE_KEY_PASSWORD/$KEY_PASSWORD/g" cli.properties
sed -i "s/REPLACE_TRUST_PASSWORD/$TRUST_PASSWORD/g" cli.properties

cat cli.properties

kubectl cp -n dm cli.properties nifi-dm-0:/opt/nifi/nifi-toolkit-current/bin -c server


