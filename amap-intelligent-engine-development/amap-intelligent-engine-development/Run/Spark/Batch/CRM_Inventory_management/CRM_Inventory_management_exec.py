from pyspark.sql import SparkSession
import traceback
import sys

spark = SparkSession.builder \
            .config("hive.exec.dynamic.partition.mode", "nonstrict") \
            .enableHiveSupport() \
            .getOrCreate()

def read_api(rds_sql_user,rds_sql_pass,aws_rds_connection,rdssql_schema,bucket_name):
    table_name = 'api_inventorycheck'
    partition_column='id'
    num_partitions=20
    query = f"SELECT coalesce(MIN({partition_column}),1), coalesce(MAX({partition_column}),1) FROM {table_name} "
    min_max_df = spark.read \
        	.format("jdbc") \
        	.option('url', f'jdbc:mysql://{aws_rds_connection}:3306/{rdssql_schema}?&useSSL=true&trustServerCertificate=true')\
            .option("driver", "org.mariadb.jdbc.Driver")\
        	.option("user", rds_sql_user )\
        	.option("password", rds_sql_pass ) \
        	.option("query", query) \
        	.load()
    lower_bound, upper_bound = min_max_df.collect()[0]
    query = f"SELECT * FROM {table_name}"
    dbtable = f"({query}) AS subq"
    df = spark.read.format("jdbc")\
            .option('url', f'jdbc:mysql://{aws_rds_connection}:3306/{rdssql_schema}?&useSSL=true&trustServerCertificate=true')\
            .option("driver", "org.mariadb.jdbc.Driver")\
            .option("dbtable", dbtable)\
            .option("user", rds_sql_user)\
            .option("password", rds_sql_pass)\
            .option("partitionColumn", partition_column)\
            .option("lowerBound", lower_bound)\
            .option("upperBound", upper_bound)\
            .option("numPartitions", num_partitions)\
            .option("isolationLevel", 'NONE') \
            .load()
    df.write.mode("overwrite").parquet("s3://{}/data/outbound/tmp/api".format(bucket_name))
    


def ReadTable(rds_sql_user,rds_sql_pass,aws_rds_connection,rdssql_schema,table_name):
    Query = "SELECT * FROM "+table_name
    df = spark.read.format("jdbc")\
        .option('url','jdbc:mysql://'+ aws_rds_connection +':3306/'+rdssql_schema+'?&useSSL=true&trustServerCertificate=true')\
        .option("driver","org.mariadb.jdbc.Driver")\
        .option("batchsize",10000)\
        .option("query",Query)\
        .option("user",rds_sql_user)\
        .option("password",rds_sql_pass)\
        .load()
    return df

def main(aws_rds_connection,rds_sql_user,rds_sql_pass,rdssql_schema,bucket_name):

    df_adslot = ReadTable(rds_sql_user,rds_sql_pass,aws_rds_connection,rdssql_schema,'STG_SA_Ad_Slot')
    df_adslot.write.parquet("s3://{}/data/outbound/tmp/adslot".format(bucket_name),mode = 'overwrite')



    df_afsadslot = ReadTable(rds_sql_user,rds_sql_pass,aws_rds_connection,rdssql_schema,'STG_SA_AFSAdSlot')
    df_afsadslot.write.parquet("s3://{}/data/outbound/tmp/afsaadslot".format(bucket_name),mode = 'overwrite')

    df_catalog = ReadTable(rds_sql_user,rds_sql_pass,aws_rds_connection,rdssql_schema,'STG_SA_CatalogItem')
    df_catalog.write.parquet("s3://{}/data/outbound/tmp/catalog".format(bucket_name),mode = 'overwrite')

    df_adformatspec = ReadTable(rds_sql_user,rds_sql_pass,aws_rds_connection,rdssql_schema,'STG_SA_AdFormatSpec')
    df_adformatspec.write.parquet("s3://{}/data/outbound/tmp/adformatspec".format(bucket_name),mode = 'overwrite')
    
    read_api(rds_sql_user,rds_sql_pass,aws_rds_connection,rdssql_schema,bucket_name)
    
    print("Read API Table and wrote it")

    df_table_adslot = spark.read.parquet("s3://{}/data/outbound/tmp/adslot".format(bucket_name),inferschema = True)
    df_table_adslot.createOrReplaceTempView("adslot")

    df_table_api = spark.read.parquet("s3://{}/data/outbound/tmp/api".format(bucket_name),inferschema = True)
    df_table_api.createOrReplaceTempView("api")
    
    query_agg = '''
    
    SELECT
    	date,
        metric,
        adserver_adslot_id,
        adserver_adslot_name,
        audience_name,
        SUM(future_capacity) as future_capacity,
        SUM(booked) as booked,
        SUM(reserved) as reserved,
        city,
        event,
        state,
        overwriting,
        percentage_of_overwriting,
        SUM(overwritten_impressions) as overwritten_impressions,
        overwriting_reason,
        use_overwrite
        FROM api GROUP BY
        date,metric,adserver_adslot_id,adserver_adslot_name,
        audience_name,city,event,state,overwriting,percentage_of_overwriting
        ,overwriting_reason,use_overwrite
    
    '''
    df_table_api = spark.sql(query_agg)
    df_table_api.createOrReplaceTempView("api")

    df_table_afsaadslot = spark.read.parquet("s3://{}/data/outbound/tmp/afsaadslot".format(bucket_name),inferschema = True)
    df_table_afsaadslot.createOrReplaceTempView("afsaadslot")
    spark.sql("SELECT afsid,sa_adslot_id FROM (SELECT afsid,sa_adslot_id,ROW_NUMBER()  OVER(partition by sa_adslot_id ORDER BY sa_adslot_id) as rn FROM afsaadslot) WHERE rn = 1").createOrReplaceTempView("afsaadslot")

    df_table_catalog = spark.read.parquet("s3://{}/data/outbound/tmp/catalog".format(bucket_name),inferschema = True)
    df_table_catalog.createOrReplaceTempView("catalog")

    df_table_adformatspec = spark.read.parquet("s3://{}/data/outbound/tmp/adformatspec".format(bucket_name),inferschema = True)
    df_table_adformatspec.createOrReplaceTempView("adformatspec")


    df_final  = spark.sql("""select
        row_number() over(PARTITION BY metric order by metric) AS load_id,
        cast(a.date as date) AS date,
        a.metric AS metric,
        a.adserver_adslot_id AS adserver_adslot_id,
        a.adserver_adslot_name AS adserver_adslot_name,
        a.audience_name AS audience_name,
        e.Level1 as level1,
        e.Level2 as level2,
        e.Level3 as level3,
        e.Level4 as level4,
        e.Level5 as level5,
        d.catalog_item_id AS catalog_item_id,
        d.media_type AS media_type,
        d.catalog_level AS catalog_level,
        d.display_name AS L2,
        d.record_type AS record_type,
        d.parent_id AS L1Id,
        f.display_name AS L1,
        f.parent_id AS L0Id,
        m.display_name AS L0,
        a.future_capacity AS future_capacity,
        a.booked AS booked,
        a.reserved AS reserved,
	    CASE WHEN use_overwrite = 'Y' THEN a.reserved+a.booked-a.overwritten_impressions  ELSE a.reserved+a.booked-a.future_capacity END as overbooked,
	    a.city as city,
	    a.event as event,
	    a.state as state,
        a.overwriting AS overwriting,
        a.percentage_of_overwriting AS percentage_of_overwriting,
        a.overwritten_impressions AS overwritten_impressions,
        a.overwriting_reason AS overwriting_reason,
        a.use_overwrite AS use_overwrite
    from
        (((api a
    left join (adslot e
    left join (afsaadslot b
    left join (adformatspec c
    left join catalog d on
        ((c.catalog_item_id = d.catalog_item_id))) on
        ((b.afsid = c.afsid))) on
        ((e.sa_adslot_id = b.sa_adslot_id))) on
        ((a.adserver_adslot_id = e.adserver_adslot_id)))
    left join catalog f on
        ((f.catalog_item_id = d.parent_id)))
    left join catalog m on
        ((m.catalog_item_id = f.parent_id))) """)

    df_final.repartition(1).write.csv("s3://{}/data/outbound/tmp/inventory_api".format(bucket_name),header = True,sep = '|',mode = 'Overwrite')
    import boto3
    import os
    s3 = boto3.client('s3')
    folder_name = 'data/outbound/tmp/inventory_api'  #----Source folder of Inventory
    target_name = 'data/outbound/crm_analytics/DataMart_Inventory/DataMartInventory.csv' #----Target folder for Inventory
    res = s3.list_objects_v2(Bucket = bucket_name,Prefix = folder_name)
    files = []
    if 'Contents' in res:
        for obj in res['Contents']:
            files.append(obj['Key'])
        
    for i in files:
        if(".csv" in i):
            source = "s3://"+bucket_name+"/"+i
            dest = "s3://"+bucket_name+"/"+target_name
            command = f'aws s3 cp '+'"'+source+'"'+" "+'"'+dest+'"'
            print(command)
            os.system(command)

    df_final_schema  = spark.sql("""select
        row_number() over(PARTITION BY metric order by metric) AS load_id,
        cast(a.date as date) AS date,
        a.metric AS metric,
        a.adserver_adslot_id AS adserver_adslot_id,
        a.adserver_adslot_name AS adserver_adslot_name,
        a.audience_name AS audience_name,
        e.Level1 as level1,
        e.Level2 as level2,
        e.Level3 as level3,
        e.Level4 as level4,
        e.Level5 as level5,
        d.catalog_item_id AS catalog_item_id,
        d.media_type AS media_type,
        d.catalog_level AS catalog_level,
        d.display_name AS L2,
        d.record_type AS record_type,
        d.parent_id AS L1Id,
        f.display_name AS L1,
        f.parent_id AS L0Id,
        m.display_name AS L0,
        a.future_capacity AS future_capacity,
        a.booked AS booked,
        a.reserved AS reserved,
	    CASE WHEN use_overwrite = 'Y' THEN a.reserved+a.booked-a.overwritten_impressions ELSE a.reserved+a.booked-a.future_capacity END as overbooked,
	    a.city as city,
	    a.event as event,
	    a.state as state,
        a.overwriting AS overwriting,
        a.percentage_of_overwriting AS percentage_of_overwriting,
        a.overwritten_impressions AS overwritten_impressions,
        a.overwriting_reason AS overwriting_reason,
        a.use_overwrite AS use_overwrite
    from
        (((api a
    left join (adslot e
    left join (afsaadslot b
    left join (adformatspec c
    left join catalog d on
        ((c.catalog_item_id = d.catalog_item_id))) on
        ((b.afsid = c.afsid))) on
        ((e.sa_adslot_id = b.sa_adslot_id))) on
        ((a.adserver_adslot_id = e.adserver_adslot_id)))
    left join catalog f on
        ((f.catalog_item_id = d.parent_id)))
    left join catalog m on
        ((m.catalog_item_id = f.parent_id))) LIMIT 1""")

    df_final_schema.repartition(1).write.csv("s3://{}/data/outbound/tmp/inventory_api".format(bucket_name),header = True,sep = '|',mode = 'Overwrite')
    import boto3
    import os
    s3 = boto3.client('s3')
    folder_name = 'data/outbound/tmp/inventory_api'  #----Source folder of Inv Histroical
    target_name = 'data/outbound/crm_analytics/DataMart_Inventory/schema_sample.csv' #----Target folder for Inv Historical
    res = s3.list_objects_v2(Bucket = bucket_name,Prefix = folder_name)
    files = []
    if 'Contents' in res:
        for obj in res['Contents']:
            files.append(obj['Key'])
        
    for i in files:
        if(".csv" in i):
            source = "s3://"+bucket_name+"/"+i
            dest = "s3://"+bucket_name+"/"+target_name
            command = f'aws s3 cp '+'"'+source+'"'+" "+'"'+dest+'"'
            print(command)
            os.system(command)


__name__ = "__main__"
if __name__ == "__main__":
    aws_rds_connection = sys.argv[1]
    rds_sql_user = sys.argv[2]
    rds_sql_pass = sys.argv[3]
    rdssql_schema = 'data_activation'
    bucket_name  = sys.argv[4]#'foxtel-hawkes3-data'  ye-dev-  
    try:
        main(aws_rds_connection,rds_sql_user,rds_sql_pass,rdssql_schema,bucket_name)
    except Exception as e:
        print(e)
        traceback.print_tb(e.__traceback__)
