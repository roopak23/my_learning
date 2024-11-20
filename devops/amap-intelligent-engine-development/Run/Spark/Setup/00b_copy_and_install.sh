#!/usr/bin/env sh
set -ex

###############################################################################
# Intro
#    * This script will configure the Spark cluster.
#    * The first step will configure ssh connection and install
#       security patches.
#    * After the script will install required python packages
#       for ETL execution and ML algorithms
#
# Parameters
#    * CLOUD_PROVIDER: identifier of the cloud provider: AWS, GCP, AZR
#    * STORAGE: name of the bucket/blob/etc.. (eg. dev-dm3-bucket)
#
# Output:
#    * None
#
# Example:
#    * ./00b_install_anc_copy.sh AWS dev-dm3-bucket
#
###############################################################################

# Import variables
CLOUD_PROVIDER=$1
STORAGE=$2

# Error function
error_exit() {
    local parent_lineno="$1"
    local message="$2"
    local code="${3:-1}"
    if [[ -n "$message" ]] ; then
        echo "[ERROR] On or near line ${parent_lineno}: ${message}; exiting with status ${code}"
    else
        echo "[ERROR] On or near line ${parent_lineno}; exiting with status ${code}"
    fi
    exit "${code}"
}

trap 'error_exit ${LINENO}' ERR

# Setup machine
setup_shared_files() {
    echo "[INFO] Starting system configuration..."

    # Update /etc/ssh/sshd_config with Ciphers settings
    sudo sed -i "s|^# Ciphers and keying|Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com|g" /etc/ssh/sshd_config
    echo "[INFO] Updated Ciphers settings..."

    # Run System Update
    sudo yum update -y

    # Install other packages
    sudo yum install -y python3-devel cyrus-sasl-devel  #python37-termcolor-1.1.0-1.noarch

    echo "[SUCCESS] System configuration completed"
}

setup_install_packages() {
    echo "[INFO] Starting python configuration..."

    # sometime uninstall is needed 
    #sudo python3 -m pip uninstall -y pandas pmdarima pyhive pymysql pytest thrift sasl thrift_sasl numpy

    # ======== GENERAL Packages ========
    # Packages have been pinned to cooperate with Python ver. 3.7
    # As Python will be upgraded versions of the below packages will also be upgraded
    sudo python3 -m pip install pandas==1.2.5 pmdarima==1.8.5 pyhive pymysql pytest thrift sasl thrift_sasl tensorflow-recommenders==0.7.3 xgboost==1.6.2 matplotlib==3.5.3 seaborn==0.12.2 pyarrow googleads
    #--use-feature=2020-resolver

    # ======== CLOUD SPECIFIC ========
    if [[ "$CLOUD_PROVIDER" == "AWS" ]]; then
        # Install AWS packages
        sudo python3 -m pip install awscli
        sudo python3 -m pip install botocore
        sudo python3 -m pip install boto3
    elif [[ "$CLOUD_PROVIDER" == "GCP" ]]; then
        # Install GCP packages
        # TODO
        continue
    elif [[ "$CLOUD_PROVIDER" == "AZR" ]]; then
        # Install AZURE packages
        # TODO
        continue
    else
        echo "[WARN] Cloud provider not recognized. Installation will continue but some functionalities might not be available"
    fi

    # Logging
    echo "[SUCCESS] Python configuration completed ..."

}

# ======== MAIN ========

# Execute Functions
echo "[INFO] Starting script..."

setup_shared_files
setup_install_packages

echo "[SUCCESS] Script completed"

# EOF