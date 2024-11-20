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
    mkdir -p /tmp/amap
    echo "$1" | base64 -d > /tmp/amap/ciphertext-blob
    decrypted=$(aws kms decrypt --ciphertext-blob fileb:///tmp/amap/ciphertext-blob  --output text --query Plaintext | base64 -d)
    rm -f /tmp/amap/ciphertext-blob
    echo "$decrypted"
}

#Set segtool variables
set_segmentation_variables() {
    echo "Setting segmentation tool variables"
    
    #Parameters:
    # 1 = AZs
    # 2 = EnvName
    # 3 = DistrBucket
    # 4 = RDS adress
    # 5 = RDS username
    # 6 = RDS password
    # 7 = ETLBranch
    # 8 = KMS key ARN
    # 9 = HiveBucket
    # 10 = AWS region
    # 11 = GDPRAdmin
    # 12 = GDPRLoger
    # 13 = GDPRReader
    # 14 = Segtools = true/false
 
    DISTR_BUCKET=$(echo $3)
    S3_BUCKET=$(echo $9)
    BRANCH_NAME=$(echo $7)
    RDS_USER=$(echo $5)
    RDS_HOST=$(echo $4)
    KMS_REGION=$(echo ${10}) 
    
    S3_REGION=$(echo ${10})
    SEGTOOL=$(echo ${14})
    
    # encrypt passwords
    GDPR_ADMIN_PASS_ENC=$(echo ${11})
    GDPR_LOGGER_PASS_ENC=$(echo ${12})
    GDPR_READER_PASS_ENC=$(echo ${13})
    RDS_PASSWORD_ENC=$(echo $6)
    
    # variables for EMR cluster connection
    HIVE_USER="hadoop"
    HIVE_IP=$HOSTNAME
    SPARK_IP=$HOSTNAME
    HDFS_IP=$HOSTNAME
    HIVE_URL=$(echo "jdbc:hive2://$HIVE_IP:10000/default")
    
    #segtool parameters
    SEGTOOL_IP=$(wget -qO - http://169.254.169.254/latest/meta-data/public-ipv4)
    if [[ -z $SEGTOOL_IP ]]; then SEGTOOL_IP=$(wget -qO - http://169.254.169.254/latest/meta-data/local-ipv4); fi
    SEGTOOL_PORT="7500"
    SEGTOOL_HTTPS_PORT="7543"
    HIVE_META_IP=$(echo $4)
    HIVE_META_PASS_ENC=$(echo $6)
    KMS_KEYID=$(echo $8)
    RDS_PORT="3306"
    RDS_PASS=$(decryptPassword "$6")
        
    # segtool dist file location
    SEGTOOL_SOURCE_DIR="/home/hadoop/segtool"

    # segtool destinations
    SEG_ENGINE_HOME="/opt/seg-engine"
    SEG_METADATA_HOME="/opt/seg-metadata-importer"
    SEG_STARTER_HOME="/opt/seg-tool-starter"
    SEGMENT_STARTER_HOME="/opt/segment-starter"
    UM_ETL_HOME="/opt/um-etl"
    BATCH_HOME="/home/hadoop/amap-batch-pipeline"
}

#Create segmentation tool directories
create_segmentation_directories() {
    echo "Creating segmentation tool directories"
    mkdir -p $SEGTOOL_SOURCE_DIR
    sudo mkdir -p $SEG_ENGINE_HOME/config
    sudo mkdir -p $SEG_ENGINE_HOME/lib
    sudo mkdir -p $SEG_METADATA_HOME
    sudo mkdir -p $SEG_STARTER_HOME/config
    sudo mkdir -p $SEG_STARTER_HOME/lib
    sudo mkdir -p $SEG_STARTER_HOME/logs
    sudo mkdir -p $UM_ETL_HOME/config
    sudo mkdir -p $UM_ETL_HOME/java
    sudo mkdir -p $UM_ETL_HOME/shell
    sudo mkdir -p $UM_ETL_HOME/sql
    sudo mkdir -p $SEGMENT_STARTER_HOME/logs
    sudo mkdir -p $BATCH_HOME/conf/properties
    sudo mkdir -p $BATCH_HOME/lib
}

#Copy segmentation tool files from distr location to target directories
copy_segmentation_files() {
    echo "Copying segmentation tool files"
    # Copy seg-engine files
    sudo cp $SEGTOOL_SOURCE_DIR/seg-engine.jar $SEG_ENGINE_HOME/
    sudo cp $SEGTOOL_SOURCE_DIR/config-samples/seg-tool.properties $SEG_ENGINE_HOME/config/
    sudo cp $SEGTOOL_SOURCE_DIR/spark/lib/* $SEG_ENGINE_HOME/lib/
    sudo cp $SEGTOOL_SOURCE_DIR/spark/bin/commons-lang3-3.5.jar $SEG_ENGINE_HOME/lib/
    sudo cp $SEGTOOL_SOURCE_DIR/spark/bin/scala-library-2.11.12.jar $SEG_ENGINE_HOME/lib/
    sudo cp $SEGTOOL_SOURCE_DIR/spark/bin/seg-tool-common.jar $SEG_ENGINE_HOME/lib/
    sudo cp $SEGTOOL_SOURCE_DIR/spark/bin/spark-core_2.11-2.4.0.jar $SEG_ENGINE_HOME/lib/

    # Copy seg-metadata-importer files
    sudo cp $SEGTOOL_SOURCE_DIR/config-samples/importer.properties $SEG_METADATA_HOME/application.properties
    sudo cp $SEGTOOL_SOURCE_DIR/amap-base-data-model.xml $SEG_METADATA_HOME/
    sudo cp $SEGTOOL_SOURCE_DIR/seg-tool-metadata-importer.jar $SEG_METADATA_HOME/

    # Copy seg-tool-starter files
    sudo cp $SEGTOOL_SOURCE_DIR/config-samples/application.properties $SEG_STARTER_HOME/config/
    sudo cp $SEGTOOL_SOURCE_DIR/config-samples/logback.xml $SEG_STARTER_HOME/config/
    sudo cp $SEGTOOL_SOURCE_DIR/payload.xsd $SEG_STARTER_HOME/config/
    sudo cp $SEGTOOL_SOURCE_DIR/config-samples/schemaexport.properties $SEG_STARTER_HOME/
    sudo cp $SEGTOOL_SOURCE_DIR/seg-tool-starter.jar $SEG_STARTER_HOME/
    sudo cp $SEGTOOL_SOURCE_DIR/config-samples/keystore.p12 $SEG_STARTER_HOME/

    # Copy um-etl files 
    sudo cp $SEGTOOL_SOURCE_DIR/um-etl/config/log4j.properties $UM_ETL_HOME/config/
    sudo cp $SEGTOOL_SOURCE_DIR/um-etl/config/um_configuration.ini $UM_ETL_HOME/config/
    sudo cp $SEGTOOL_SOURCE_DIR/um-etl/java/um-etl.jar $UM_ETL_HOME/java/
    #copy mariadb connector lib from segtool 
    sudo cp $SEGTOOL_SOURCE_DIR/spark/lib/mariadb-java-client-2.7.0.jar $UM_ETL_HOME/java/
    sudo cp $SEGTOOL_SOURCE_DIR/um-etl/shell/run_etl.sh $UM_ETL_HOME/shell/
    sudo cp $SEGTOOL_SOURCE_DIR/um-etl/sql/cfg_join.sql $UM_ETL_HOME/sql/
    sudo cp $SEGTOOL_SOURCE_DIR/um-etl/sql/kpi_db.sql $UM_ETL_HOME/sql/
    
    # Copy segment-starter files
    sudo cp -rf $SEGTOOL_SOURCE_DIR/segment-starter/* $SEGMENT_STARTER_HOME/

    # Copy segment pivoting files
    sudo cp $SEGTOOL_SOURCE_DIR/config-samples/pivoting.properties $BATCH_HOME/conf/properties/
    sudo cp $SEGTOOL_SOURCE_DIR/seg-pivoting-spark.jar $BATCH_HOME/lib/
    
    # Change permissions
    echo "Changing segmentation tool file permissions"
    sudo chown -R hadoop:hadoop $SEG_ENGINE_HOME
    sudo chown -R hadoop:hadoop $SEG_METADATA_HOME
    sudo chown -R hadoop:hadoop $SEG_STARTER_HOME
    sudo chown -R hadoop:hadoop $UM_ETL_HOME
    sudo chown -R hadoop:hadoop $SEGMENT_STARTER_HOME
}

#Configure segmentation tool files
configure_segmentation_tool() {
    echo "Configuring segmentation tool files"
    # seg-tool.properties 
    echo "Updating seg-tool.properties"
    sed -i "s|^spark\.segmentation-tool\.host\.port .*$|spark\.segmentation-tool\.host\.port $SEGTOOL_IP:$SEGTOOL_PORT|g" $SEG_ENGINE_HOME/config/seg-tool.properties
    sed -i "s|^spark\.username\.mysql .*$|spark\.username\.mysql $RDS_USER|g" $SEG_ENGINE_HOME/config/seg-tool.properties
    sed -i "s|^spark\.password\.mysql .*$|spark\.password\.mysql $RDS_PASSWORD_ENC|g" $SEG_ENGINE_HOME/config/seg-tool.properties
    sed -i "s|^spark\.url\.mysql .*$|spark\.url\.mysql jdbc:mysql://$RDS_HOST/segmentation?zeroDateTimeBehavior=convertToNull|g" $SEG_ENGINE_HOME/config/seg-tool.properties
    sed -i "s|^spark\.url\.hive .*$|spark\.url\.hive jdbc:hive2://$HIVE_IP:10000/default|g" $SEG_ENGINE_HOME/config/seg-tool.properties
    sed -i "s|^spark\.kms\.aws\.region .*$|spark\.kms\.aws\.region $S3_REGION|g" $SEG_ENGINE_HOME/config/seg-tool.properties
    sed -i "s|^spark\.kms\.aws\.keyId .*$|spark\.kms\.aws\.keyId $KMS_KEYID|g" $SEG_ENGINE_HOME/config/seg-tool.properties

    # application.properties (importer)
    echo "Updating application.properties (importer)"
    sed -i "s|^spring\.datasource\.url=.*$|spring\.datasource\.url=jdbc:mysql://$RDS_HOST:$RDS_PORT/segmentation|g" $SEG_METADATA_HOME/application.properties
    sed -i "s|^spring\.datasource\.username=.*$|spring\.datasource\.username=$RDS_USER|g" $SEG_METADATA_HOME/application.properties
    sed -i "s|^spring\.datasource\.password=.*$|spring\.datasource\.password=$RDS_PASSWORD_ENC|g" $SEG_METADATA_HOME/application.properties
    sed -i "s|^spring\.datasource\.clientRegion=.*$|spring\.datasource\.clientRegion=$S3_REGION|g" $SEG_METADATA_HOME/application.properties
    sed -i "s|^spring\.datasource\.keyId=.*$|spring\.datasource\.keyId=$KMS_KEYID|g" $SEG_METADATA_HOME/application.properties
    sed -i "s|^spring\.hive\.url=.*$|spring\.hive\.url=jdbc:hive2://$HIVE_IP:10000/default|g" $SEG_METADATA_HOME/application.properties
    sed -i "s|^spring\.hive\.clientRegion=.*$|spring\.hive\.clientRegion=$S3_REGION|g" $SEG_METADATA_HOME/application.properties
    sed -i "s|^spring\.hive\.keyId=.*$|spring\.hive\.keyId=$KMS_KEYID|g" $SEG_METADATA_HOME/application.properties
    sed -i "s|^server\.port\.http=.*$|server\.port\.http=$SEGTOOL_PORT|g" $SEG_METADATA_HOME/application.properties
    sed -i "s|^server\.port=.*$|server\.port=$SEGTOOL_HTTPS_PORT|g" $SEG_METADATA_HOME/application.properties
    sed -i "s|^cors\.origin=.*$|cors\.origin=https://$SEGTOOL_IP:$SEGTOOL_HTTPS_PORT|g" $SEG_METADATA_HOME/application.properties
    sed -i "s|^com\.acn\.amap\.xmlPath = .*$|com\.acn\.amap\.xmlPath = $SEG_METADATA_HOME/amap-base-data-model\.xml|g" $SEG_METADATA_HOME/application.properties
    sed -i "s|^com\.acn\.amap\.xsdPath = .*$|com\.acn\.amap\.xsdPath = $SEG_STARTER_HOME/config/payload\.xsd|g" $SEG_METADATA_HOME/application.properties

    # application.properties (starter)
    echo "Updating application.properties (starter)"
    sed -i "s|^spring\.datasource\.url=.*$|spring\.datasource\.url=jdbc:mysql://$RDS_HOST/segmentation?autoReconnect=true\&verifyServerCertificate=false\&useSSL=false\&requireSSL=false|g" $SEG_STARTER_HOME/config/application.properties
    sed -i "s|^spring\.datasource\.username=.*$|spring\.datasource\.username=$RDS_USER|g" $SEG_STARTER_HOME/config/application.properties
    sed -i "s|^spring\.datasource\.password=.*$|spring\.datasource\.password=$RDS_PASSWORD_ENC|g" $SEG_STARTER_HOME/config/application.properties
    sed -i "s|^spring\.datasource\.clientRegion=.*$|spring\.datasource\.clientRegion=$S3_REGION|g" $SEG_STARTER_HOME/config/application.properties
    sed -i "s|^spring\.datasource\.keyId=.*$|spring\.datasource\.keyId=$KMS_KEYID|g" $SEG_STARTER_HOME/config/application.properties
    sed -i "s|^server\.port\.http=.*$|server\.port\.http=$SEGTOOL_PORT|g" $SEG_STARTER_HOME/config/application.properties
    sed -i "s|^server\.port=.*$|server\.port=$SEGTOOL_HTTPS_PORT|g" $SEG_STARTER_HOME/config/application.properties
    sed -i "s|^cors\.origin=.*$|cors\.origin=https://$SEGTOOL_IP:$SEGTOOL_HTTPS_PORT|g" $SEG_STARTER_HOME/config/application.properties
    sed -i "s|^logging\.config=.*$|logging\.config=$SEG_STARTER_HOME/config/logback\.xml|g" $SEG_STARTER_HOME/config/application.properties
    sed -i "s|^logging\.path=.*$|path\.config=$SEG_STARTER_HOME/logs|g" $SEG_STARTER_HOME/config/application.properties
    
    # schemaexport.properties 
    echo "Updating schemaexport.properties"
    sed -i "s|^hibernate.connection.url=.*$|hibernate.connection.url=jdbc:mysql://$RDS_HOST:$RDS_PORT/segmentation?autoReconnect=true\&useSSL=false\&createDatabaseIfNotExist=true|g" $SEG_STARTER_HOME/schemaexport.properties
    sed -i "s|^hibernate.connection.username=.*$|hibernate.connection.username=$RDS_USER|g" $SEG_STARTER_HOME/schemaexport.properties
    sed -i "s|^hibernate.connection.password=.*$|hibernate.connection.password=$RDS_PASSWORD_ENC|g" $SEG_STARTER_HOME/schemaexport.properties
    sed -i "s|^hibernate.connection.kms.aws.region=.*$|hibernate.connection.kms.aws.region=$S3_REGION|g" $SEG_STARTER_HOME/schemaexport.properties
    sed -i "s|^hibernate.connection.kms.aws.keyId=.*$|hibernate.connection.kms.aws.keyId=$KMS_KEYID|g" $SEG_STARTER_HOME/schemaexport.properties

    # um_configuration.ini
    echo "Updating um_configuration.ini"
    sed -i "s|^um\.etl\.unix\.root\.path=.*$|um\.etl\.unix\.root\.path=$UM_ETL_HOME|g" $UM_ETL_HOME/config/um_configuration.ini
    sed -i "s|^um\.mysql\.ip=.*$|um\.mysql\.ip=$RDS_HOST|g" $UM_ETL_HOME/config/um_configuration.ini
    sed -i "s|^um\.mysql\.port=.*$|um\.mysql\.port=$RDS_PORT|g" $UM_ETL_HOME/config/um_configuration.ini
    sed -i "s|^um\.mysql\.username=.*$|um\.mysql\.username=$RDS_USER|g" $UM_ETL_HOME/config/um_configuration.ini
    sed -i "s|^um\.mysql\.password=.*$|um\.mysql\.password=$RDS_PASSWORD_ENC|g" $UM_ETL_HOME/config/um_configuration.ini
    sed -i "s|^um\.metastore\.ip=.*$|um\.metastore\.ip=$HIVE_META_IP|g" $UM_ETL_HOME/config/um_configuration.ini
    sed -i "s|^um\.metastore\.password=.*$|um\.metastore\.password=$HIVE_META_PASS_ENC|g" $UM_ETL_HOME/config/um_configuration.ini
    sed -i "s|^um\.metastore\.username=.*$|um\.metastore\.username=$RDS_USER|g" $UM_ETL_HOME/config/um_configuration.ini
    sed -i "s|^um\.metastore\.schema=.*$|um\.metastore\.schema=hive_metastore|g" $UM_ETL_HOME/config/um_configuration.ini
    sed -i "s|^um\.hdfs\.tables\.path=.*$|um\.hdfs\.tables\.path=s3://$S3_BUCKET/{{ params.HIVE_DATA_PATH }}/base/AMAP|g" $UM_ETL_HOME/config/um_configuration.ini
    sed -i "s|^um\.kms\.aws\.region=.*$|um\.kms\.aws\.region=$KMS_REGION|g" $UM_ETL_HOME/config/um_configuration.ini


    # segment-starter.properties
    echo "Updating segment-starter.properties"
    sed -i "s|^spring\.datasource\.url=.*$|spring\.datasource\.url=jdbc:mysql://$RDS_HOST/segmentation?autoReconnect=true\&verifyServerCertificate=false\&useSSL=false\&requireSSL=false|g" $SEGMENT_STARTER_HOME/config/segment-starter.properties
    sed -i "s|^spring\.datasource\.username=.*$|spring\.datasource\.username=$RDS_USER|g" $SEGMENT_STARTER_HOME/config/segment-starter.properties
    sed -i "s|^spring\.datasource\.password=.*$|spring\.datasource\.password=$RDS_PASSWORD_ENC|g" $SEGMENT_STARTER_HOME/config/segment-starter.properties
    sed -i "s|^spring\.datasource\.clientRegion=.*$|spring\.datasource\.clientRegion=$S3_REGION|g" $SEGMENT_STARTER_HOME/config/segment-starter.properties
    sed -i "s|^spring\.datasource\.keyId=.*$|spring\.datasource\.keyId=$KMS_KEYID|g" $SEGMENT_STARTER_HOME/config/segment-starter.properties
    sed -i "s|^spark\.jar\.path\.on\.name\.node=.*$|spark\.jar\.path\.on\.name\.node=$SEG_ENGINE_HOME/seg-engine\.jar|g" $SEGMENT_STARTER_HOME/config/segment-starter.properties
    sed -i "s|^spark\.jar\.properties\.file\.path=.*$|spark\.jar\.properties\.file\.path=$SEG_ENGINE_HOME/config/seg-tool\.properties|g" $SEGMENT_STARTER_HOME/config/segment-starter.properties
    sed -i "s|^spark\.jar\.lib\.folder\.on\.name\.node=.*$|spark\.jar\.lib\.folder\.on\.name\.node=$SEG_ENGINE_HOME/lib|g" $SEGMENT_STARTER_HOME/config/segment-starter.properties
    sed -i "s|^logging\.config=.*$|logging\.config=$SEGMENT_STARTER_HOME/config/logback\.xml|g" $SEGMENT_STARTER_HOME/config/segment-starter.properties
    sed -i "s|^logging\.path=.*$|logging\.path=$SEGMENT_STARTER_HOME/logs|g" $SEGMENT_STARTER_HOME/config/segment-starter.properties

    # pivoting.properties
    sed -i "s|^spark\.queue\.name .*$|spark\.queue\.name default|g" $BATCH_HOME/conf/properties/pivoting.properties
    sed -i "s|^spark\.extra\.jars .*$|spark\.extra\.jars $SEG_ENGINE_HOME/lib/mariadb-java-client-2.7.0.jar,/usr/lib/spark/jars/datanucleus-api-jdo-3.2.6.jar,/usr/lib/spark/jars/datanucleus-rdbms-3.2.9.jar,/usr/lib/spark/jars/datanucleus-core-3.2.10.jar|g" $BATCH_HOME/conf/properties/pivoting.properties
    sed -i "s|^spark\.properties\.file .*$|spark\.properties\.file $BATCH_HOME/conf/properties/pivoting.properties|g" $BATCH_HOME/conf/properties/pivoting.properties
    sed -i "s|^spark\.main\.app .*$|spark\.main\.app $BATCH_HOME/lib/seg-pivoting-spark.jar|g" $BATCH_HOME/conf/properties/pivoting.properties
    sed -i "s|^spark\.mysql\.db\.url .*$|spark\.mysql\.db\.url jdbc:mysql://$RDS_HOST:3306/segmentation|g" $BATCH_HOME/conf/properties/pivoting.properties
    sed -i "s|^spark\.mysql\.user .*$|spark\.mysql\.user $RDS_USER|g" $BATCH_HOME/conf/properties/pivoting.properties
    sed -i "s|^spark\.mysql\.pass .*$|spark\.mysql\.pass $RDS_PASSWORD_ENC|g" $BATCH_HOME/conf/properties/pivoting.properties
    sed -i "s|^spark\.hive\.url .*$|spark\.hive\.url jdbc:hive2://$HIVE_IP:10000/default|g" $BATCH_HOME/conf/properties/pivoting.properties
    sed -i "s|^spark\.kms\.aws\.region .*$|spark\.kms\.aws\.region $S3_REGION|g" $BATCH_HOME/conf/properties/pivoting.properties
    sed -i "s|^spark\.kms\.aws\.keyId .*$|spark\.kms\.aws\.keyId $KMS_KEYID|g" $BATCH_HOME/conf/properties/pivoting.properties
    
    # Update batch pipeline file if it exists (kpi.properties)
    if [ -f $BATCH_HOME/conf/properties/kpi.properties ]
    then
        echo "Updating kpi.properties"
        sed -i "s|^um\.etl\.dir\.jar=.*$|um\.etl\.dir\.jar=$UM_ETL_HOME/java/um-etl\.jar|g" $BATCH_HOME/conf/properties/kpi.properties
    fi
}

is_subdir() {
    DIR_TO_DELETE="$1"
    DIR_NAME=$(dirname $DIR_TO_DELETE | xargs)
    if [[ ${#DIR_NAME} > 1 ]]
    then
        return 0
    else
        return 1
    fi
}

delete_if_exists() {
    DIR_TO_DELETE=$(echo "$1" | xargs)
    if [ ! -z $DIR_TO_DELETE ] && [ ${#DIR_TO_DELETE} > 1 ] && [ -d "$DIR_TO_DELETE" ] && is_subdir "$DIR_TO_DELETE"
    then
        rm -rf "$DIR_TO_DELETE"
    fi
}

delete_downloaded_files() {
    delete_if_exists "$SEGTOOL_SOURCE_DIR"
}

#Setup segmentation tool
setup_segmentation_tool() {
    if [ "$SEGTOOL" == "true" ] 
    then
        echo "Setting up segmentation tool"
    
        #Create directories for segmentation tool
        create_segmentation_directories
        
        #Segtool distr download
        sudo aws s3 cp s3://$DISTR_BUCKET/BATCH/$BRANCH_NAME/segtool $SEGTOOL_SOURCE_DIR --recursive
        #copy mariadb connector lib from segtool 
        sudo aws s3 cp s3://$DISTR_BUCKET/BATCH/$BRANCH_NAME/segtool/spark/lib/mariadb-java-client-2.7.0.jar $SEG_STARTER_HOME/lib
        sudo aws s3 cp s3://$DISTR_BUCKET/BATCH/$BRANCH_NAME/segtool/spark/lib/mariadb-java-client-2.7.0.jar $BATCH_HOME/lib/
        
        #Copy segmentation tool files
        copy_segmentation_files
        
        #Configure segmentation tool files
        configure_segmentation_tool
        
        #delete downloaded files
        delete_downloaded_files
    fi
}

if grep isMaster /mnt/var/lib/info/instance.json | grep true;
then

    #Set segmentation tool variables
    set_segmentation_variables "$@"

    #setup segmentation tool
    setup_segmentation_tool

fi

exit 0
