# Script to prepare api_inventorycheckupdate

from pyspark.sql import SparkSession
import pymysql
import sys
import pyspark.sql.functions as F
from datetime import datetime


def now() -> str:
    return datetime.now().strftime("%Y/%m/%d, %H:%M:%S")


def mark_process_started():
        connection = pymysql.connect(
        host=aws_rds_connection,
        user=rds_sql_user,
        password=rds_sql_pass,
        database=rdssql_schema
    )
        
        cursor = connection.cursor()
        try:
            cursor.execute("UPDATE batch_status SET date=NOW(), status = 'RUNNING'")
            connection.commit()
            print(" [IE][INFO][{now()}] SET PROCESS STARTED")
        except Exception as e:
            print(f"[IE][INFO][{now()}] Error SET PROCESS STARTEDe: {e}")
            raise e
        finally:
            cursor.close()
            connection.close()
##########################################################################            

def main():
    
    mark_process_started()
 
    
    df_api_partition =  spark_session.sql("select coalesce(max(partition_date),-19543314) partition_date from api_inventorycheck");
    api_partition = df_api_partition.first()['partition_date']
    
    


    print(f"[IE][INFO][{now()}] api_partition: {api_partition}") 
    
    df_trf_partition =  spark_session.sql("select coalesce(max(partition_date),-19543314) partition_date from trf_inventory");
    trf_partition = df_trf_partition.first()['partition_date']

    print(f"[IE][INFO][{now()}] trf_partition: {trf_partition}") 
    
    print("[IE][INFO][{now()}] joining")
    
    
    spark_joined=spark_session.sql(f"\
        SELECT \
        CAST(NULL as int) `id`, \
        coalesce(K.`date`,T.`date`) `date` , \
        coalesce(K.adserver_id,T.adserver_id) adserver_id ,  \
        coalesce(K.adserver_adslot_id,T.adserver_adslot_id) adserver_adslot_id,  \
        coalesce(K.adserver_adslot_name,T.adserver_adslot_name) adserver_adslot_name,  \
        T.audience_name,  \
        upper(coalesce(K.metric,T.metric)) metric,  \
        coalesce(K.state,T.state) state,  \
        coalesce(K.city,T.city) city,  \
        coalesce(K.event,T.event) event,  \
        coalesce(K.pod_position,T.pod_position) pod_position,  \
        coalesce(K.video_position,T.video_position) video_position,  \
        round(coalesce(K.future_capacity,T.future_capacity)) future_capacity,  \
        round(coalesce(K.booked,coalesce(T.booked,0))) booked,  \
        coalesce(T.reserved,0) reserved, \
        CASE WHEN K.adserver_adslot_id is not null THEN 'N' \
            ELSE T.missing_forecast \
        END missing_forecast, \
        'N' missing_segment, \
        T.overwriting, \
        T.percentage_of_overwriting, \
        T.overwritten_impressions, \
        T.overwriting_reason, \
        CASE WHEN DATE(T.overwritten_expiry_date) <= CURRENT_DATE() THEN 'N' ELSE T.use_overwrite END use_overwrite, \
        T.Updated_By, \
        T.overwritten_expiry_date, \
        coalesce(T.version,0) version \
    FROM (SELECT * FROM trf_inventory WHERE partition_date = {trf_partition} ) K  \
  FULL OUTER JOIN  (SELECT * FROM api_inventorycheck \
                     WHERE partition_date = {api_partition} \
                       AND date >  (CURRENT_TIMESTAMP() - interval  '1' day)  \
                    ) T \
         ON K.adserver_adslot_id = T.adserver_adslot_id   \
        AND K.adserver_id = T.adserver_id  \
        AND K.`date` = T.`date`  \
        AND upper(K.metric) = upper(T.metric)  \
        AND upper(coalesce(K.state,'')) = upper(coalesce(T.state,''))  \
        AND upper(coalesce(K.city,'')) = upper(coalesce(T.city,''))  \
        AND upper(coalesce(K.event,'')) = upper(coalesce(T.event,''))  \
        AND coalesce(K.pod_position,'') = coalesce(T.pod_position,'')  \
        AND upper(coalesce(K.video_position,'')) = upper(coalesce(T.video_position,'')) \
         ").repartition(20)
        
        
        
    lowerBound, upperBound = spark_joined.select(F.min("date"), F.max("date")).first()
 
    
  
    print(f"[IE][INFO][{now()}] lowerBound :{lowerBound}") 
    print(f"[IE][INFO][{now()}] upperBound :{upperBound}") 


    print("[IE][INFO][{now()}] Writing to Database")
    
    spark_joined.write.format("jdbc")\
        .option("url", f'jdbc:mysql://{aws_rds_connection}:3306/{rdssql_schema}?&useSSL=true&trustServerCertificate=true')\
        .option("driver", "org.mariadb.jdbc.Driver")\
        .option("dbtable", 'api_inventorycheck_upd') \
        .option("user", rds_sql_user)\
        .option("password", rds_sql_pass)\
        .option("batchsize", 10000)\
        .option("numPartitions", 20) \
        .option("partitionColumn", 'date')\
        .option("lowerBound", lowerBound)\
        .option("upperBound", upperBound)\
        .option("sessionInitStatement", "SET SESSION unique_checks=0;") \
        .option("truncate", "true") \
        .option("isolationLevel", 'NONE') \
        .option("rewriteBatchedStatements", "true") \
        .mode('overwrite') \
        .save()

            
    print("[IE][INFO][{now()}] Writing to Database Completed")



#__name__ = "__main__"
if __name__ == "__main__":
    
    partition_date = int(sys.argv[1])  # in YYYYMMDD format
    aws_rds_connection = sys.argv[2]
    rds_sql_user = sys.argv[3]
    rds_sql_pass = sys.argv[4]
    rdssql_schema = 'data_activation'
    
    
    
    spark_session = SparkSession.builder \
        .config("hive.exec.dynamic.partition.mode", "nonstrict") \
        .enableHiveSupport() \
        .getOrCreate()
    spark_session.sql(f"use default")
    main()
