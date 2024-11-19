#Importing Libraries
import pickle
import datetime
import sqlite3
import pymysql
import traceback
from pymysql import NULL, Error
import sys
from pprint import pprint
import numpy as np
from math import ceil as ceil
import tensorflow as tf
import tensorflow_recommenders as tfrs
# Custom Import
sys.path.append('/tmp/Libraries')
from ie_hive_connection import IEHiveConnection

tf.compat.v1.logging.set_verbosity(tf.compat.v1.logging.ERROR)


#####################
# Tensorflow Classes
#####################

class UserModel(tf.keras.Model):
    
    def __init__(self, embedding_dimension):
        super().__init__()

        self.advertiser_embedding = tf.keras.Sequential([
            tf.keras.layers.experimental.preprocessing.StringLookup(
                vocabulary=unique_advertiser_ids, mask_token=None),
            tf.keras.layers.Embedding(len(unique_advertiser_ids) + 1, embedding_dimension),
        ])

        self.brand_embedding = tf.keras.Sequential([
            tf.keras.layers.experimental.preprocessing.StringLookup(
                vocabulary=unique_brand_ids, mask_token=None),
            tf.keras.layers.Embedding(len(unique_brand_ids) + 1, embedding_dimension),
        ])

        self.industry_embedding = tf.keras.Sequential([
            tf.keras.layers.experimental.preprocessing.StringLookup(
                vocabulary=unique_industry_ids, mask_token=None),
            tf.keras.layers.Embedding(len(unique_industry_ids) + 1, embedding_dimension),
        ])

        self.len_embeddings = tf.keras.layers.experimental.preprocessing.StringLookup(
                vocabulary=tokens_len, mask_token=None)

    def call(self, inputs):
        try:
            return tf.concat([
                self.advertiser_embedding(inputs["advertiser_id"]),
                self.brand_embedding(inputs["brand_id"]),
                tf.one_hot(self.len_embeddings(inputs["campaign_length"]), len(tokens_len)+1),
                self.industry_embedding(inputs["industry"]),
                ], axis=1)
        except:
            return tf.concat([
                self.advertiser_embedding(inputs["advertiser_id"]),
                self.brand_embedding(inputs["brand_id"]),
                [tf.one_hot(self.len_embeddings(inputs["campaign_length"]), len(tokens_len)+1)],
                self.industry_embedding(inputs["industry"]),
            ], axis=1)


class ProductRecommendationModel(tfrs.models.Model):

    def __init__(self, embedding_dimension=64):
        super().__init__()

        self.user_model = tf.keras.Sequential([
            UserModel(embedding_dimension),
            tf.keras.layers.Dropout(0.3),
            tf.keras.layers.Dense(embedding_dimension)
            ])

        self.product_model = tf.keras.Sequential([
            tf.keras.layers.experimental.preprocessing.StringLookup(
                vocabulary=unique_item_ids, mask_token=None),
            tf.keras.layers.Embedding(len(unique_item_ids) + 1, embedding_dimension)
        ])

        self.task = tfrs.tasks.Retrieval(
            metrics=tfrs.metrics.FactorizedTopK(
                candidates=item_id.batch(128).map(self.product_model),
            ),
        )

    def compute_loss(self, features, training=False):
        user_embeddings = self.user_model({
            "advertiser_id": features["advertiser_id"],
                "brand_id": features["brand_id"],
            "campaign_length": features["campaign_length"],
            "industry": features["industry"]
        })
        positive_product_embeddings = self.product_model(features["format_id"])

        return self.task(user_embeddings, positive_product_embeddings, compute_metrics=not training)


#####################
# DB Connection Functions
#####################

class partition_date():
    key = (datetime.date.today() - datetime.timedelta(days=1)).strftime('%Y%m%d')
    today = (datetime.date.today()).strftime('%Y%m%d')


class sqlitedict():
    def __init__(self, cursor):
        self._cursor = cursor

    def __iter__(self):
        return self

    # Need to fix - very unstable
    def __next__(self):
        row = self._cursor.__next__()
        return {description[0]: row[col] for col, description in enumerate(self._cursor.description)}


class mysql_db:
    host = ""
    database = ""
    port = 1
    user = ""
    password = ""

    @classmethod
    def set(cls, host, database, port, user, password):
        cls.host = host
        cls.database = database
        cls.port = port
        cls.user = user
        cls.password = password


# class hive_db:
#     host = ""
#     port = 1
#     username = ""
#     configuration = {"": ""}
#
#     @classmethod
#     def set(cls, host, port, username, configuration):
#         cls.host = host
#         cls.port = port
#         cls.username = username
#         cls.configuration = configuration

def CursorByName(cur):
    if isinstance(cur, sqlite3.Cursor):
        return sqlitedict(cur)
    else:
        return pymysqldict(cur)


def pymysqldict(cur):
    records = cur.fetchall()
    insertObject = []
    columnNames = [column[0] for column in cur.description]
    for record in records:
        insertObject.append(dict(zip(columnNames, record)))
    return insertObject


def create_mysql_connection():
    try:
        connection = pymysql.connect(
            host=mysql_db.host,
            database=mysql_db.database,
            port=mysql_db.port,
            user=mysql_db.user,
            password=mysql_db.password)
    except Error as e:
        print(f"The error '{e}' occurred")
        raise ConnectionError("mySQL Connection Failed.")
    return connection


def create_hive_connection(database: str = 'default'):
    try:
        # connection = hive.Connection(
        #     host=hive_db.host,
        #     port=hive_db.port,
        #     username=hive_db.username,
        #     configuration=hive_db.configuration)
        connection = IEHiveConnection(database=database)
    except Error as e:
        print(f"The error '{e}' occurred")
        raise ConnectionError("Hive Connection Failed.")
    return connection


def execute_read_query(connection, query):
    try:
        cur = connection.cursor()
        cur.execute(query)
        connection.commit()
        data = []
        for row in CursorByName(cur):
            data.append(row)
        cur.close()
    except Error as e:
        print(f"Query error: {query} {e}")
    return data


def execute_write_query(connection, query):
    try:
        cur = connection.cursor()
        cur.execute(query)
        connection.commit()
    except Exception as e:
        print("Query failed", query, e)
        traceback.print_tb(e.__traceback__)

#Data availability check
def run_integration_check():
    print("Testing Hive connection.")
    try:
        hive_connection = create_hive_connection()
        print("Hive connection passed.")
    except:
        raise ConnectionError("Hive Connection Failed.")

    print("Testing mySQL connection.")
    try:
        mysql_connection = create_mysql_connection()
        print("mySQL connect passed.")
        mysql_connection.close()
    except:
        raise ConnectionError("SQL Connection Failed.")

    try:
        buying_profile_media_kpi = {}
        trf_market_order_line_details = {}
        hive_database = {"buying_profile_media_kpi": buying_profile_media_kpi,
                         "trf_market_order_line_details": trf_market_order_line_details}
        for key, value in hive_database.items():
            print(f"Checking {key} database")
            value = execute_read_query(
                hive_connection, "SELECT * FROM " + key + " LIMIT 1")
            if not value:
                print(key + " - FAILED")
            else:
                print(key + " - PASSED")
    except Exception as e:
        print("Hive Database Connection failed.", e)
        traceback.print_tb(e.__traceback__)

    return 0


#####################
# Main Functions
#####################


#Erasing all the old suggestions records from ML_product_recommendation (mysql) database
def clear_table():
    query = "DELETE FROM ML_product_recommendation"
    mysql_connection = create_mysql_connection()
    execute_write_query(mysql_connection, query)
    print('Table cleared')


# Transform length of the campaign from numeric to categorical
def campaign_days_to_cat(x):
    if x <= 7:
        return 'week'
    elif x <= 30:
        return 'month'
    elif x <= 90:
        return 'season'
    else:
        return 'long'


#Determining the campaign duration based on MOLD end_date and start_date
def extract_campaign_duration(dictionary):
    days = (datetime.datetime.strptime(str(dictionary['end_date']),
                                       '%Y-%m-%d') - datetime.datetime.strptime(
        str(dictionary['start_date']), '%Y-%m-%d')).days + 1
        
    return campaign_days_to_cat(days)


 # Extract only the relevant attributes and transform to dict of lists
def preprocess_history_table(history_table):
    processed_history_table = []
    your_keys = ['advertiser_id', 'brand_id', 'format', 'industry']
    for row in history_table:
        filtered_dict = {your_key: row[your_key] for your_key in your_keys}
        filtered_dict['campaign_length'] = extract_campaign_duration(row)
        filtered_dict['format'] = row['format'] + '|' + str(row['gads_bidding_strategy'])
        filtered_dict.pop('start_date', None)
        filtered_dict.pop('end_date', None)
        processed_history_table.append(filtered_dict)
        
    return processed_history_table


# Load and process trf_market_order_line_details table
def load_history(hive_connection):
    query = "SELECT market_order_id, advertiser_id, brand_id, min(start_date) as start_date, max(end_date) as end_date, industry, format, gads_bidding_strategy FROM trf_market_order_line_details "
    query += "WHERE advertiser_id IS NOT NULL AND brand_id IS NOT NULL AND format IS NOT NULL AND industry IS NOT NULL AND start_date IS NOT NULL AND end_date IS NOT NULL "
    query += "GROUP BY market_order_id, advertiser_id, brand_id, industry, format, gads_bidding_strategy"
    history_table = execute_read_query(hive_connection, query)
    processed_history_table = preprocess_history_table(history_table)
    if processed_history_table:
        processed_history_table = {key: [i[key] for i in processed_history_table] for key in processed_history_table[0]}

    return processed_history_table


#Forming the user(train) and candidate (item_id) tensor
def transform_to_tensors(history_table):
    train = tf.data.Dataset.from_tensor_slices(history_table)
    train = train.map(lambda x: {
        "advertiser_id": x["advertiser_id"],
        "brand_id": x["brand_id"],
        "format_id": x["format"],
        "campaign_length": x["campaign_length"],
        "industry": x["industry"]
    })
    item_id = tf.data.Dataset.from_tensor_slices(list(set(history_table['format'])))

    return train, item_id


# Extract lookup variables for the TF model
def get_lookup_variables(input):
    item_ids = input.batch(1_000_000).map(lambda x: x["format_id"])
    unique_item_ids = np.unique(np.concatenate(list(item_ids)))
    advertiser_ids = input.batch(1_000_000).map(lambda x: x["advertiser_id"])
    unique_advertiser_ids = np.unique(np.concatenate(list(advertiser_ids)))
    brand_ids = input.batch(1_000_000).map(lambda x: x["brand_id"])
    unique_brand_ids = np.unique(np.concatenate(list(brand_ids)))
    len_id = input.batch(1_000_000).map(lambda x: x["campaign_length"])
    tokens_len = np.unique(np.concatenate(list(len_id)))
    industry_ids = input.batch(1_000_000).map(lambda x: x["industry"])
    unique_industry_ids = np.unique(np.concatenate(list(industry_ids)))

    return unique_item_ids, unique_advertiser_ids, unique_brand_ids, tokens_len, unique_industry_ids


#Training the model
def train_model(history_table):
    global item_id
    global unique_item_ids
    global unique_advertiser_ids
    global unique_brand_ids
    global tokens_len
    global unique_industry_ids

    train, item_id = transform_to_tensors(history_table)
    unique_item_ids, unique_advertiser_ids, unique_brand_ids, tokens_len, unique_industry_ids = get_lookup_variables(train)

    model = ProductRecommendationModel()
    model.compile(optimizer=tf.keras.optimizers.Adagrad(learning_rate=0.25))
    
    #train test split
    n=len(train)
    x=ceil(0.75*n)
    tf.random.set_seed(42)
    shuffled = train.shuffle(n, seed=42, reshuffle_each_iteration=False)
    train = shuffled.take(x)
    test = shuffled.skip(x).take(n-x)


    cached_train = train.batch(2048).cache()
    cached_test = test.batch(1024).cache()

    callback = tf.keras.callbacks.EarlyStopping(monitor='val_factorized_top_k/top_10_categorical_accuracy', mode='max', patience=3)

    model.fit(
        cached_train,
        epochs=100,
        verbose=0,
        callbacks = [callback]
    )
    print("model fitted succesfully")
    
    #model evaluation
    model.evaluate(cached_test, return_dict=True)

    index = tfrs.layers.factorized_top_k.BruteForce(model.user_model)
    index.index_from_dataset(
        tf.data.Dataset.zip((item_id.batch(100), item_id.batch(100).map(model.product_model)))
    )

    # need to call brute force index with an example record before saving it
    _,_ = index({'advertiser_id': np.array(['esempio']),
             'brand_id': np.array(['esempio']),
             'campaign_length': np.array(['esempio']),
             'industry': np.array(['esempio'])},
             k=len(item_id))

    return index


#Model training and saving to prescribed path
def training_step(path):

    hive_connection = create_hive_connection()
    print("Establishing Hive connection")

    history_table = load_history(hive_connection)
    print("Purchase History imported successfully.")

    print("Training model...")
    recommender = train_model(history_table)
    print("Model Trained.")

    tf.saved_model.save(recommender,path)
    print("Model Saved")

    return recommender


#Based on step input saving or loading the recommender
def create_recommender(step):
    path = '/tmp/purchasebehaviour/saved_model'

    if step == 'training':
        recommender = training_step(path)
    else:
        recommender = tf.saved_model.load(path)
        print("Model Loaded")

    return recommender


# Load and process recent advertisers profiles from buying_profile_media_kpi (hive) table
def load_buyer_profile(hive_connection):
    query = "SELECT advertiser_id, brand_id, COALESCE(NULLIF(industry,''),'unknown') AS industry FROM buying_profile_media_kpi "
    filter = "SELECT max(partition_date) from buying_profile_media_kpi"
    query += f"WHERE partition_date = ({filter}) "
    query += "GROUP BY advertiser_id, brand_id, industry"
    buyer_profile = execute_read_query(hive_connection, query)

    return buyer_profile


# extract running campaigns details for all the campaigns whose end_date is in future
def load_running_campaigns(hive_connection):
    query = "SELECT advertiser_id, brand_id, format FROM trf_market_order_line_details "
    query += f"WHERE end_date > {partition_date.key} GROUP BY advertiser_id, brand_id, format"
    running_campaigns = execute_read_query(hive_connection, query)

    return running_campaigns


## filter out the product with negative score 
def return_positive_scores(advs,scores, products, running_products):
    
    adv_recommendations = []
    for score, product in zip(scores[0], products[0]):
        if score.numpy() > 0:
            if product.numpy().decode('UTF-8') in running_products:
                continue
            normalized_score = (score - min(scores[0])) / (max(scores[0] - min(scores[0])))
            adv_recommendations.append(
                {'advertiser_id': advs['advertiser_id'], 'brand_id': advs['brand_id'], 'score': round(float(normalized_score.numpy()),5), 'score_raw': round(float(score.numpy()),5),
                 'format_id': product.numpy().decode('UTF-8')})
        else:
            return adv_recommendations

    return adv_recommendations

# create campaign along with recommendations for each advertiser
def create_campaign(recommender, buyer_profile, running_campaigns):
    recommendations = []
#    number_of_recommendations = item_id
    for advs in buyer_profile:
        print(f"Create recommendations for adv {advs['advertiser_id']} and brand {advs['brand_id']}")
        scores, products = recommender({'advertiser_id': np.array([advs['advertiser_id']]),
                                        'brand_id': np.array([advs['brand_id']]),
                                        'campaign_length': np.array(['month']),
                                        'industry': np.array([advs['industry']])})
                                        # , k=number_of_recommendations) ## not needed if model imported

        running_products = [d['format'] for d in running_campaigns if d['advertiser_id'] ==  advs['advertiser_id'] and d['brand_id'] == advs['brand_id']]
        recommendations.extend(return_positive_scores(advs, scores, products, running_products))

    return recommendations


# load buyer profile,running campaign details and to create recommendations for each profile
def make_recommendations(recommender):
    hive_connection = create_hive_connection()
    print("Establishing Hive connection to extract Buyer Profile")

    buyer_profile = load_buyer_profile(hive_connection)
    print("Buyer Profile imported sucessfully.")

    hive_connection = create_hive_connection()
    print("Establishing Hive connection to extract Running Campaigns")

    running_campaigns = load_running_campaigns(hive_connection)
    print("Running Campaigns imported sucessfully.")

    recommendations = create_campaign(recommender, buyer_profile, running_campaigns)
    print("Recommendations created.")

    return recommendations


# Loading all the product suggestions or recommendations for each advertiser to ML_product_recommendation table (mysql)
class Output_Recommendation():
    def __init__(self, recommendation, id):
        self.simulation_id = (datetime.date.today() - datetime.timedelta(days=1)).strftime('%Y%m%d')+'|'+str(id)
        self.advertiser_id = recommendation['advertiser_id']
        self.brand_id = recommendation['brand_id']
        self.start_date = (datetime.date.today()).strftime('%Y%m%d')
        self.end_date = (datetime.date.today() + datetime.timedelta(days=29)).strftime('%Y%m%d')
        self.format_id = recommendation['format_id'].split('|')[0]
        self.score = recommendation['score']
        self.score_raw = recommendation['score_raw']
        self.gads_bidding_strategy = recommendation['format_id'].split('|')[1]


    def write_to_database(self, conn):
        query = self.generate_query()
        print("Writing ", query)
        execute_write_query(conn, query)


    def generate_query(self):
        query = f"""INSERT INTO ML_product_recommendation(
                        simulation_id,
                        advertiser_id,
                        brand_id,
                        start_date,
                        end_date,
                        format_id,
                        score,
                        score_raw,
                        gads_bidding_strategy)
                    VALUES (
                        '{self.simulation_id}',
                        '{self.advertiser_id}',
                        '{self.brand_id}',
                        {self.start_date},
                        {self.end_date},
                        '{self.format_id}',
                        {self.score},
                        {self.score_raw},
                        """
        if self.gads_bidding_strategy == 'None':
            query += 'NULL)'
        else:
            query += f"'{self.gads_bidding_strategy}')"

        return query


# write the recommendations with their scores to ML_product_recommendation table (mysql)
def upload_recommendation(conn, recommendations):
    for id, recommendation in enumerate(recommendations):
        print(f"Uploading campaing products for {recommendation['advertiser_id']}, {recommendation['brand_id']}")
        product_campaign = Output_Recommendation(recommendation, id)
        print("Writing to ML_product_recommendation")
        product_campaign.write_to_database(conn)


def write_recommendation(recommendation):
    mysql_connection = create_mysql_connection()
    print("Establishing Mysql connection")

    upload_recommendation(mysql_connection, recommendation)
    print("Recommendations uploaded.")
    mysql_connection.close()


def main(step):
    recommender = create_recommender(step)
    if step == 'training':
        return 0
    else:
        recommendation = make_recommendations(recommender)
        clear_table()
        write_recommendation(recommendation)

        return 0

# __name__ == '__main__'
if __name__ == '__main__':

    mysql_db.set(
        sys.argv[4][:-1],
        sys.argv[2][:-1],
        int(sys.argv[7][:-1]),
        sys.argv[5][:-1],
        sys.argv[6][:-1])
    # hive_db.set(
    #     "localhost",
    #     10000,
    #     "hadoop",
    #     {'hive.txn.manager': 'org.apache.hadoop.hive.ql.lockmgr.DbTxnManager'})

    step = sys.argv[8][:-1]

    try:
        run_integration_check()
        main(step)

    except Exception as e:
        print(e)
        traceback.print_tb(e.__traceback__)

