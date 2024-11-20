
import sys
from pyspark.sql import SparkSession
import pyspark.sql.functions as F
import pandas as pd

#import networkx as nx


# Custom Import
sys.path.append('/tmp/Libraries')
from ie_hive_connection import IEHiveConnection


#Function to create hive connection
def create_hive_connection(database: str = 'default'):
    try:
        # connection = hive.Connection(
        #         #     host=hive_db.host,
        #         #     port=hive_db.port,
        #         #     username=hive_db.username,
        #         #     configuration=hive_db.configuration)
        connection = IEHiveConnection(database=database)
        print("Establishing Hive connection")
    except ConnectionError as e:
        print(f"The error '{e}' occurred")
        raise ConnectionError("Hive Connection Failed.")
    return connection



def get_adslot_hierarchy(partition_date):

    hive_connection = create_hive_connection()

    query = "SELECT id, adserver_id, adserver_adslot_child_id ,adserver_adslot_parent_id, adslot_child_id, adslot_parent_id FROM {} WHERE (partition_date={})".format('stg_sa_adslot_hierarchy', partition_date)

    try: 
      df = pd.read_sql(query,hive_connection)
      
    finally:
         hive_connection.close()
  
    return df


def crate_missing_parent(df : pd.DataFrame):
  
    # sanitize parent in case None value is received in the slot
    df.loc[(df['adserver_adslot_parent_id']) == 'None', ['adserver_adslot_parent_id']] = ''
   
    #check if we have parents that are not childs(top level)
    top_level_parents = df[ ~(df["adserver_adslot_parent_id"] == '') & df["adserver_adslot_parent_id"].notnull() & ~df["adserver_adslot_parent_id"].isin(df["adserver_adslot_child_id"])]
    top_level_parents = top_level_parents.drop_duplicates(subset=['adserver_adslot_parent_id'])
    
    # assing parent as new childs add then to dataframe, as top level adlsots parent_id has to be empty
    top_level_parents['adserver_adslot_child_id'] = top_level_parents['adserver_adslot_parent_id']
    top_level_parents['adserver_adslot_parent_id'] = ''
    top_level_parents['adslot_child_id'] = top_level_parents['adslot_parent_id']
    top_level_parents['adslot_parent_id'] = ''
    top_level_parents['id'] =  '-1 - '  +  top_level_parents['adserver_adslot_child_id']
    
    df=pd.concat([df,top_level_parents],ignore_index=True)

    df.loc[(df['adserver_adslot_child_id']) == 'None', ['adserver_adslot_parent_id']] = ''

    return df


def calculate_levels_nx(df : pd.DataFrame):
    # # Create a  graph from the DataFrame
    Graph = nx.from_pandas_edgelist(df, 'adserver_adslot_parent_id', 'adserver_adslot_child_id', create_using=nx.DiGraph)
    # get top level s
    roots=df.loc[df['adserver_adslot_parent_id']=='']
    for index, root in roots.iterrows():
          levels = nx.shortest_path_length(G, source=root['adserver_adslot_child_id'])
          df['Level'] = df['adserver_adslot_child_id'].apply(lambda x: levels.get(x, 0)) + 1

    return df
    
def calculate_levels(df : pd.DataFrame):
    # Set level 1 for records where parent is empty(root)
    df.loc[(df['adserver_adslot_parent_id']) == '', 'level'] = 1
   
    parents_list = df[df['level'] == 1]
    
    level = 1
    
    while (len(parents_list)):
        # Get root parents
        print(f'[DM3] Get nodes for level {level}')
        parents_list = df[df['level'] == level]
        level = level +1 
        print (f"[DM3] Update level {level} childs")
        df.loc[df['adserver_adslot_parent_id'].isin(parents_list['adserver_adslot_child_id']), 'level'] = level
        print (f"[DM3] Level {level} childs update completed")
    
    return df

def load_to_hive(source_table,target_table,mode):

    
    print(f"[IE][INFO] Open Hive connection")
    hive_connection = create_hive_connection()

    try:

        cursor = hive_connection.cursor()
        print(f"[IE][INFO] Executing INSERT {mode} TABLE {target_table} SELECT * FROM {source_table} ")
        cursor.execute(f"INSERT {mode} TABLE {target_table} SELECT * FROM {source_table}  ")
        print(f"[IE][INFO] Insertion ended")
    except Exception as ex:
        print(f"[IE][ERROR] Saving table {target_table} error: {ex}")
        raise ex
    finally:
        print(f"[IE][INFO] losing Hive connection")
        hive_connection.close()
        print(f"[IE][INFO] Connection closed")


def main(partition_date : int, database ='default', load_hive = True):
    """This script will calculate a adslot level in adslot hierarhcy

    Args:
        partition_date (int): date to process data
        database (str, optional): Hive database schema to store data. Defaults to 'default'.
        load_hive (bool, optional): Load data to hive if True. Defaults to True.
    """    
    spark_session = SparkSession.builder.appName("AdlostHierarchyLevels") \
        .config("hive.exec.dynamic.partition.mode", "nonstrict") \
        .enableHiveSupport() \
        .getOrCreate()
        
    spark_session.sql(f"USE {database}")
    
      

    df_adslot_hierarchy=get_adslot_hierarchy(partition_date)
    
    df_calculated_levels = pd.DataFrame()
    
    if not df_adslot_hierarchy.empty:
        
        adservers =  df_adslot_hierarchy['adserver_id'].unique()
        for adserver_id in adservers:
            
            print (f"[DM3] Calculate levels for adserver {adserver_id} ")
            
            df_adserver_adslot_hierarchy = df_adslot_hierarchy.loc[df_adslot_hierarchy['adserver_id']==adserver_id]

            df_adserver_adslot_hierarchy=crate_missing_parent(df_adserver_adslot_hierarchy)
        
            df_adserver_adslot_hierarchy=calculate_levels(df_adserver_adslot_hierarchy)
            
            df_calculated_levels=pd.concat([df_adserver_adslot_hierarchy,df_calculated_levels])    
     
        
        if load_hive:
            
             spark_df = spark_session.createDataFrame(df_calculated_levels.astype("str"))
             spark_df = spark_df.withColumn('partition_date', F.lit(int(partition_date)))
             spark_session.sql('DROP TABLE IF EXISTS  df_calculated_levels_tmp PURGE ')
             spark_df.write.saveAsTable('df_calculated_levels_tmp')
            
             load_to_hive('df_calculated_levels_tmp','TRF_Adslot_Hierarchy','OVERWRITE')
             spark_session.sql('DROP TABLE IF EXISTS  df_calculated_levels_tmp PURGE ')
            
    else: 
        print (f"[DM3] Empty Dataframe")

    


#__name__ = "__main__"
if __name__ == "__main__":

    partition_date = int(sys.argv[1])  # in YYYYMMDD format 
    main(partition_date)
