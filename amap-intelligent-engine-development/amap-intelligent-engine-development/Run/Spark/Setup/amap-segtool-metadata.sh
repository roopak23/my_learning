#Error function
error_exit() {
    local parent_lineno="$1"
    local message="$2"
    local code="${3:-1}"
    if [[ -n "$message" ]] ; then
        echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
    else
        echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
    fi
    exit "${code}"
}

trap 'error_exit ${LINENO}' ERR

function decryptPassword() { 
    mkdir -p /tmp/ava
    echo "$1" | base64 -d > /tmp/ava/ciphertext-blob
    decrypted=$(aws kms decrypt --ciphertext-blob fileb:///tmp/ava/ciphertext-blob  --output text --query Plaintext | base64 -d)
    rm -f /tmp/ava/ciphertext-blob
    echo "$decrypted"
}


#Set required script variables
set_segmentation_variables() {
    echo "Setting segmentation tool variables"
    #Parameters:
    # 1 = Install Segtool = true/false
    # 2 = RDS adress
    # 3 = RDS username
    # 4 = RDS password

    SEGTOOL=$(echo $1)
    RDS_HOST=$(echo $2)
    RDS_USER=$(echo $3)
    RDS_PASSWORD_ENC=$(echo $4)
    RDS_PASS=$(decryptPassword "$RDS_PASSWORD_ENC")
    
    
    # segtool destinations
    SEG_METADATA_HOME="/opt/seg-metadata-importer"
    SEG_STARTER_HOME="/opt/seg-tool-starter"
    UM_ETL_HOME="/opt/um-etl"
    BATCH_HOME="/home/hadoop/ava-batch-pipeline"
}

#Create and import segmentation tool metadata
setup_segmentation_metadata() {
    echo "Setting up segmentation metadata"

    # Import segmentation xml schema
    echo "Importing segmentation metadata"
    java -Dloader.path="$BATCH_HOME/lib/mariadb-java-client-2.7.0.jar" -jar $SEG_METADATA_HOME/seg-tool-metadata-importer.jar -x $SEG_METADATA_HOME/ava-base-data-model.xml --spring.config.location=$SEG_METADATA_HOME/application.properties
    RETURN_CODE=$?
    if [ $RETURN_CODE -ne 0 ]
    then
        echo "Failed to import segmentation metadata"
        exit 1
    fi

    # Run setup
    echo "Importing kpibuilder metadata"
    bash $UM_ETL_HOME/shell/run_etl.sh -m
    RETURN_CODE=$?
    if [ $RETURN_CODE -eq 0 ]
    then
        echo "Setting fields to visible"
        mysql -h$RDS_HOST -u$RDS_USER -p$RDS_PASS segmentation -e "UPDATE cfg_source_field SET visible='Y' WHERE visible='N'"
        RETURN_CODE=$?  
    else
        echo "Failed to import kpibuilder metadata"
        exit 1
    fi
    
    if [ $RETURN_CODE -ne 0 ]
    then
      echo "Failed to update cfg_source_field 'visible' column"
      exit 1      
    fi
    
    exit 0
}

#Setup segmentation tool
setup_segmentation_tool() {
    if [ "$SEGTOOL" == "true" ] 
    then
        #Create/import segmentation tool metadata
        setup_segmentation_metadata
    fi
}

if grep isMaster /mnt/var/lib/info/instance.json | grep true;
then
    #Set segmentation variables
    set_segmentation_variables "$@"

    #Import segtool metadata
    setup_segmentation_tool
fi

exit 0