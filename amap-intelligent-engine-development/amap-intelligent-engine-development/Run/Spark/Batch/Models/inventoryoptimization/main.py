
import pickle
import datetime
import sqlite3
import pymysql
import traceback
from pymysql import NULL, Error
import sys
from pprint import pprint

sys.path.append('/tmp/Libraries')
from ie_hive_connection import IEHiveConnection

#####################
# General Classes
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
#     @ classmethod
#     def set(cls, host, port, username, configuration):
#         cls.host = host
#         cls.port = port
#         cls.username = username
#         cls.configuration = configuration


class Overall:
    __so_input_overall = []  # Raw data

    simulation_id = []
    simulation_name = []
    simulation_date = []
    created_by = []
    update_date = []
    update_by = []
    start_date = []
    end_date = []
    revenue_max = 0
    inventory_saturation = []
    partition_date = []
    status = []
    buyer_profiles = []

    @classmethod
    def load_Overall(cls):
        cls.clear_Overall()
        if not cls.__so_input_overall:
            cls.__so_input_overall = so_input_overall
        cls.simulation_id = cls.__so_input_overall[0]["simulation_id"]
        cls.simulation_name = cls.__so_input_overall[0]["simulation_name"]
        cls.simulation_date = cls.__so_input_overall[0]["simulation_date"]
        cls.created_by = cls.__so_input_overall[0]["created_by"]
        cls.update_date = cls.__so_input_overall[0]["update_date"]
        cls.update_by = cls.__so_input_overall[0]["update_by"]
        cls.start_date = cls.__so_input_overall[0]["start_date"]
        cls.end_date = cls.__so_input_overall[0]["end_date"]
        cls.revenue_max = cls.__so_input_overall[0]["revenue_max"]
        cls.inventory_saturation = cls.__so_input_overall[0]["inventory_saturation"]
        cls.partition_date = cls.__so_input_overall[0]["partition_date"]
        cls.status = cls.__so_input_overall[0]["status"]

    @classmethod
    def clear_Overall(cls):
        cls.simulation_id = []
        cls.simulation_name = []
        cls.simulation_date = []
        cls.created_by = []
        cls.update_date = []
        cls.update_by = []
        cls.start_date = []
        cls.end_date = []
        cls.revenue_max = []
        cls.inventory_saturation = []
        cls.partition_date = []
        cls.status = []
        cls.buyer_profiles = []

    def create_media_list(input_media):
        media_list = []
        for row in input_media:
            media_list.append(row["media_type"])
        media_list = list(dict.fromkeys(media_list))
        return media_list


class MediaPriority(Overall):
    __so_input_priority = []  # Raw Data

    media_type = []
    media_priority = []
    media_perc = []

    @classmethod
    def load_Priority(cls):
        cls.clear_Priority()
        if not cls.__so_input_priority:
            cls.__so_input_priority = so_input_priority
        cls.media_type = cls.__so_input_priority[0]["media_type"]
        cls.media_priority = cls.__so_input_priority[0]["media_priority"]
        cls.media_perc = cls.__so_input_priority[0]["media_priority"]

    @classmethod
    def clear_Priority(cls):
        cls.media_type = []
        cls.media_priority = []
        cls.media_perc = []


class BuyerProfile(MediaPriority):
    # Raw Data
    __buying_profile_total_kpi = []
    __buying_profile_media_kpi = []

    def __init__(self, advertiser_id):
        BuyerProfile.load_BuyerProfile()
        total = BuyerProfile.sort_by_advertiser_id_total(
            advertiser_id, BuyerProfile.__buying_profile_total_kpi)
        media_list = BuyerProfile.generate_media_list(
            advertiser_id, BuyerProfile.__buying_profile_media_kpi)

        print("Loading buyer profile with advertise_id = ", advertiser_id)
        self.advertiser_id = total[0]["buying_profile_total_kpi.advertiser_id"]
        self.advertiser_name = total[0]["buying_profile_total_kpi.advertiser_name"]
        self.brand_name = total[0]["buying_profile_total_kpi.brand_name"]
        self.audience = total[0]["buying_profile_total_kpi.audience"]
        self.cp_total_audience = total[0]["buying_profile_total_kpi.cp_total_audience"]
        self.avg_daily_budget = total[0]["buying_profile_total_kpi.avg_daily_budget"]
        self.avg_lines = total[0]["buying_profile_total_kpi.avg_lines"]
        print("Loading media for ",
              total[0]["buying_profile_total_kpi.advertiser_id"])
        self.media_package = BuyerProfile.generate_media(
            advertiser_id, media_list)

    @classmethod
    def load_BuyerProfile(cls):
        cls.__buying_profile_total_kpi = buying_profile_total_kpi
        cls.__buying_profile_media_kpi = buying_profile_media_kpi

    def generate_media(advertiser_id, medias):
        output = []
        for media in medias:
            output.append(Media(advertiser_id, media))
        return output

    def generate_media_list(advertiser_id, input):
        output = []
        for row in input[0]:
            output.append(row["buying_profile_media_kpi.media_type"])
        return list(set(output))

    def sort_by_advertiser_id_total(advertiser_id, input):
        output = []

        #print("Input", input[0])
        for media in input:
            for row in media:
                # print(row)

                if row["buying_profile_total_kpi.advertiser_id"] == advertiser_id:
                    output.append(row)
        #print("output", output)
        return output


class Media(MediaPriority):
    # Raw Data
    __so_input_media = []
    __buying_profile_media_kpi = []
    __so_input_product = []

    @classmethod
    def load_data(cls):
        cls.__so_input_media = so_input_media
        cls.__buying_profile_media_kpi = buying_profile_media_kpi
        cls.__so_input_product = so_input_product

    def __init__(self, advertiser_id, media_type):
        Media.load_data()
        media = Media.sort_by_media_and_ad_id(
            advertiser_id, media_type, Media.__so_input_media)
        media_kpi = Media.sort_by_media_KPI(advertiser_id,
                                            media_type, Media.__buying_profile_media_kpi)
        products = Media.generate_products(
            Media.sort_by_media_and_ad_id(advertiser_id, media_type, Media.__so_input_product))

        if not media_kpi:
            print("Media Kpi failed for", advertiser_id)

        self.media_type = media[0]["media_type"]
        self.desired_budget_media_type = media[0]["desired_budget_media_type"]
        self.desired_metric_media_type = media[0]["desired_metric_media_type"]
        self.unit_of_measure_media_type = media[0]["unit_of_measure_media_type"]
        self.cp_media_type = media[0]["cp_media_type"]
        self.monday = media[0]["monday"]
        self.tuesday = media[0]["tuesday"]
        self.wednesday = media[0]["wednesday"]
        self.thursday = media[0]["thursday"]
        self.friday = media[0]["friday"]
        self.saturday = media[0]["saturday"]
        self.sunday = media[0]["sunday"]
        self.brand_name = media[0]["brand_name"]
        #self.industry = media_kpi[0]["buying_profile_media_kpi.industry"]
        #self.unit_of_measure = media_kpi[0]["buying_profile_media_kpi.unit_of_measure"]
        self.desired_metric_daily_avg = media_kpi[0]["buying_profile_media_kpi.desired_metric_daily_avg"]
        self.cp_media_type_kpi = media_kpi[0]["buying_profile_media_kpi.cp_media_type"]
        self.desired_avg_budget_daily = media_kpi[0]["buying_profile_media_kpi.desired_avg_budget_daily"]
        self.avg_lines = media_kpi[0]["buying_profile_media_kpi.avg_lines"]
        self.selling_type = media_kpi[0]["buying_profile_media_kpi.selling_type"]
        print("Loading", media[0]["media_type"],
              " products for ", advertiser_id)
        self.products = products

    def is_media_priority(self):
        if MediaPriority.media_type == self.media_type:
            return True
        else:
            return False

    def sort_by_media_and_ad_id(advertiser_id, media_type, input):
        output = []
        for row in input:
            if compare_media_type(row["media_type"], media_type) and row["advertiser_id"] == advertiser_id:
                output.append(row)
        #print("media kpi", output)
        return output

    def sort_by_media_KPI(advertiser_id, media_type, input):
        output = []
        for ad_id in input:
            for row in ad_id:
                if (compare_media_type(row["buying_profile_media_kpi.media_type"], media_type) and
                        row["buying_profile_media_kpi.advertiser_id"] == advertiser_id):
                    output.append(row)
        return output

    def generate_products(products):
        output = []
        for product in products:
            output.append(Product(product))
        return output


class Product(Media):
    # Raw data
    __buying_profile_product_kpi = []

    def __init__(self, product):
        Product.load_data()
        # product_kpi = Product.filter_kpi(
        #    product["advertiser_id"], product["media_type"], product["display_name"])
        #print("product output", product_kpi)
        self.advertiser_name = product["advertiser_name"]
        self.catalog_level = product["catalog_level"]
        self.record_type = product["record_type"]
        self.perc_value = product["perc_value"]
        print(product["perc_value"], "Input perc_value")
        self.media_type = product["media_type"]
        self.catalog_item_id = product["catalog_item_id"]
        self.length = product["length"]
        self.display_name = product["display_name"]
        self.brand_name = product["brand_name"]
        #self.partition_date = product["partition_date"]
        #self.industry = product_kpi[0]["buying_profile_product_kpi.industry"]
        #self.kpi_length = product_kpi[0]["buying_profile_product_kpi.length"]
        #self.kpi_perc_value = product_kpi[0]["buying_profile_product_kpi.perc_value"]
        print("Creating Product for",
              product["advertiser_name"], "in", product["media_type"])

    def filter_kpi(advertiser_id, media_type, display):
        print("filter_kpi", advertiser_id, media_type, display)
        output = []
        for product_set in Product.__buying_profile_product_kpi:
            for product in product_set:
                print("internal", product["buying_profile_product_kpi.media_type"], product["buying_profile_product_kpi.advertiser_id"],
                      product["buying_profile_product_kpi.display_name"], compare_media_type(product["buying_profile_product_kpi.media_type"], media_type))
                if (compare_media_type(product["buying_profile_product_kpi.media_type"], media_type) and
                        product["buying_profile_product_kpi.advertiser_id"] == advertiser_id and
                        product["buying_profile_product_kpi.display_name"] == display):
                    output.append(product)
        return output

    @classmethod
    def load_data(cls):
        cls.__buying_profile_product_kpi = buying_profile_product_kpi


class output_overall:
    __BuyerProfile = []
    simulation_id = []
    advertiser_id = []
    advertiser_name = []
    brand_name = []
    total_audience = []
    budget_total = []
    audience = []
    cp_total_audience = []
    total_quantity = []

    @classmethod
    def clear_output_overall(cls):
        cls.simulation_id = []
        cls.advertiser_id = []
        cls.advertiser_name = []
        cls.brand_name = []
        cls.total_audience = []
        cls.budget_total = []
        cls.audience = []
        cls.cp_total_audience = []
        cls.total_quantity = []
        cls.brand_id = NULL
        cls.objective = NULL

    @classmethod
    def init_load_output_overall(cls, buyerprofile):
        cls.clear_output_overall()
        cls.__BuyerProfile = buyerprofile
        cls.simulation_id = cls.__BuyerProfile.simulation_id
        cls.advertiser_id = cls.__BuyerProfile.advertiser_id
        cls.advertiser_name = cls.__BuyerProfile.advertiser_name
        cls.brand_name = cls.__BuyerProfile.brand_name
        cls.audience = cls.__BuyerProfile.audience

    @classmethod
    def post_load_output_overall(cls, campaign):
        cls.total_audience = output_overall.calculate_total_audience(
            campaign)
        cls.budget_total = output_overall.calculate_budget_total(campaign)
        cls.cp_total_audience = output_overall.calculate_cp_total_audience(
            campaign)
        cls.total_quantity = output_overall.calculate_total_quantity(
            campaign)

    @staticmethod
    def calculate_total_audience(campaign):
        total_audience = NULL

        """try:
            for media in campaign:
                total_audience += media.total_audience
                print("total_audience", media.total_audience)
        except Exception as e:
            print(f"calculate_total_audience{e}")
            traceback.print_tb(e.__traceback__)
        """
        return total_audience

    @staticmethod
    def calculate_cp_total_audience(medias):
        cp_total_audience = 0
        try:
            for media in medias:
                cp_total_audience += media.cp_media
                print("total_audience", media.cp_media)
        except Exception as e:
            print(f"calculate_cp_total_audience{e}")
            traceback.print_tb(e.__traceback__)
        return cp_total_audience

    @staticmethod
    def calculate_budget_total(medias):
        budget_total = 0
        try:
            for media in medias:
                budget_total += media.budget_media_type
        except Exception as e:
            print(f"calculate_budget_total{e}")
            traceback.print_tb(e.__traceback__)
        return budget_total

    @staticmethod
    def calculate_total_quantity(medias):
        total_quantity = 0
        try:
            total_quantity = 0
            for media in medias:
                total_quantity += media.quantity
        except Exception as e:
            print(f"calculate_total_quantity{e}")
            traceback.print_tb(e.__traceback__)
        return total_quantity

    @classmethod
    def write_to_database(cls, conn):
        query = cls.generate_query()
        print("Writing ", query)
        execute_write_query(conn, query)

    @ classmethod
    def generate_query(cls):
        query = f"""INSERT INTO so_output_overall(
                        simulation_id,
                        advertiser_id,
                        advertiser_name,
                        brand_name,
                        total_audience,
                        budget_total,
                        audience,
                        cp_total_audience,
                        total_quantity,
                        brand_id,
                        objective)
                    VALUES (
                        '{cls.simulation_id}',
                        '{cls.advertiser_id}',
                        '{cls.advertiser_name}',
                        '{cls.brand_name}',
                        {cls.total_audience},
                        {cls.budget_total},
                        '{cls.audience}',
                        {cls.cp_total_audience},
                        {cls.total_quantity},
                        {cls.brand_id}, 
                        {cls.objective})"""  # Add quotation marks to brand_id, objective and total_audience when value is not NULL
        return query


class output_media(output_overall):
    def __init__(self, media, products):
        self.media_type = media.media_type
        self.budget_media_type = media.desired_budget_media_type
        self.metric_media_type = media.desired_metric_media_type
        self.unit_of_measure_media_type = media.unit_of_measure_media_type
        self.cp_media = media.cp_media_type
        self.total_audience = output_media.calculate_audience(
            products)
        self.quantity = output_media.calculate_quantity(products)

    def write_to_database(self, conn):
        query = self.generate_query()
        print("Writing", query)
        execute_write_query(conn, query)

    def generate_query(self):
        query = f"""INSERT INTO so_output_media(
                        simulation_id,
                        advertiser_id,
                        advertiser_name,
                        brand_name,
                        media_type,
                        budget_media_type,
                        metric_media_type,
                        unit_of_measure_media_type,
                        cp_media,
                        total_audience)
                    VALUES (
                        '{output_overall.simulation_id}',
                        '{output_overall.advertiser_id}',
                        '{output_overall.advertiser_name}',
                        '{output_overall.brand_name}',
                        '{self.media_type}',
                        '{self.budget_media_type}',
                        {self.metric_media_type},
                        '{self.unit_of_measure_media_type}',
                        {self.cp_media},
                        {self.total_audience})"""  # Add quotation mark to total_audience when value is not NULL
        return query

    @ staticmethod
    def calculate_quantity(products):
        quantity = 0
        for product in products:
            quantity += product.quantity
        return quantity
    '''
    @ staticmethod
    def calculate_budget(products):
        # write budget calculations based on product
        budget = 1
        return budget
    '''
    @ staticmethod
    def calculate_audience(products):
        audience = NULL
        return audience


class output_overall_media(output_media):
    length_total = 0

    def __init__(self, product, media):
        self.breadcrumb = product.breadcrumb
        self.media_type = product.media_type
        self.length = product.length
        self.perc_length = 1  # TODO: Need to find source of perc_length
        self.quantity = product.quantity
        self.format_id = product.catalog_item_id
        self.partition_date = partition_date.key
        self.price_item_id = 0
        self.unit_of_measure_media_type = 0
        self.unit_net_price = 0
        self.list_price = 0
        self.total_net_price = 0
        self.discount = 0
        self.brand_id = NULL
        self.market_product_type_id = output_overall_media.generate_market_product_type_id(
            product.catalog_item_id)

    def generate_query(self):
        query = f"""INSERT INTO so_output_overall_media(
                        simulation_id,
                        advertiser_id,
                        advertiser_name,
                        brand_name,
                        breadcrumb,
                        media_type,
                        length,
                        perc_length,
                        quantity,
                        format_id,
                        partition_date,
                        price_item_id,
                        unit_of_measure_media_type,
                        unit_net_price,
                        list_price,
                        total_net_price,
                        discount,
                        brand_id,
                        market_product_type_id)
                    VALUES (
                        '{output_overall.simulation_id}',
                        '{output_overall.advertiser_id}',
                        '{output_overall.advertiser_name}',
                        '{output_overall.brand_name}',
                        '{self.breadcrumb}',
                        '{self.media_type}',
                        {self.length},
                        {self.perc_length},
                        {self.quantity},
                        '{self.format_id}',
                        {self.partition_date},
                        {self.price_item_id},
                        {self.unit_of_measure_media_type},
                        {self.unit_net_price}, 
                        {self.list_price}, 
                        {self.total_net_price}, 
                        {self.discount},
                        {self.brand_id},
                        {self.market_product_type_id})"""
        return query

    def calculate_summary(products):
        total = 0
        for product in products:
            total += product.length
        output_overall_media.length_total = total

    @staticmethod
    def generate_market_product_type_id(catalog_item_id):
        catalog_query = f"SELECT market_product_type_id FROM api_reserved_history WHERE format_id = '{catalog_item_id}' LIMIT 1"
        connection = create_mysql_connection()
        data = execute_read_query(connection, catalog_query)
        return data[0]["market_product_type_id"]


class output_product(output_media):
    def __init__(self, product, media):
        self.catalog_level = product.catalog_level
        self.record_type = product.record_type
        print(product.perc_value, 'Perc_value output')
        self.perc_value = product.perc_value
        self.media_type = product.media_type
        print(self.media_type)
        self.catalog_item_id = output_product.generate_product_field(product.recommend_product[0]["catalog_item_id"],
                                                                     product.catalog_level,
                                                                     "catalog_item_id")
        self.length = product.length
        self.display_name = product.display_name
        self.status = "active"
        self.quantity = output_product.generate_quantity(product, media)
        self.breadcrumb = product.recommend_product[0]["breadcrumb"]
        self.catalog_display_name = product.recommend_product[0]["display_name"]

    def generate_query(self):
        query = f"""INSERT INTO so_output_product(
                        simulation_id,
                        advertiser_id,
                        advertiser_name,
                        brand_name,
                        catalog_level,
                        record_type,
                        perc_value,
                        media_type,
                        catalog_item_id,
                        length,
                        display_name,
                        status)
                    VALUES (
                        '{output_overall.simulation_id}',
                        '{output_overall.advertiser_id}',
                        '{output_overall.advertiser_name}',
                        '{output_overall.brand_name}',
                        {self.catalog_level},
                        '{self.record_type}',
                        '{self.perc_value}',
                        '{self.media_type}',
                        '{self.catalog_item_id}',
                        '{self.length}',
                        '{self.display_name}',
                        '{self.status}')"""
        return query

    @staticmethod
    def generate_quantity(product, media):
        budget = (media.cp_media_type/100) * media.desired_budget_media_type
        print("budget", budget)
        quantity = (
            budget / product.recommend_product[0]["price_per_unit"])
        return int(round(quantity))

    @staticmethod
    def generate_product_field(catalog_item_id, catalog_level, desired_field):
        catalog_query = f"SELECT catalog_level, parent_id, {desired_field} FROM STG_SA_CatalogItem WHERE STG_SA_CatalogItem.catalog_item_id = '{catalog_item_id}' LIMIT 1"
        print(catalog_query)
        connection = create_mysql_connection()
        data = execute_read_query(connection, catalog_query)
        print(data)

        if data[0]["catalog_level"] == 0:
            print(data[0][f"{desired_field}"])
            return data[0][f"{desired_field}"]
        elif data[0]["catalog_level"] == catalog_level:
            print(data[0][f"{desired_field}"])
            return data[0][f"{desired_field}"]
        else:
            return output_product.generate_product_field(
                data[0]["parent_id"], catalog_level, f"{desired_field}")

    @staticmethod
    def generate_market_product_type_id(catalog_item_id):
        catalog_query = f"SELECT market_product_type_id FROM api_reserved_history WHERE format_id = '{catalog_item_id}' LIMIT 1"
        connection = create_mysql_connection()
        data = execute_read_query(connection, catalog_query)
        return data[0]["market_product_type_id"]


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


def compare_media_type(input1, input2):
    input1 = str(input1).casefold().replace(" ", "_")
    input2 = str(input2).casefold().replace(" ", "_")
    return (input1 == input2)


#####################
# Connection Functions
#####################


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
# Need touch up


def execute_write_query(connection, query):
    try:
        cur = connection.cursor()
        cur.execute(query)
        connection.commit()
    except Exception as e:
        print("Query failed", query, e)
        traceback.print_tb(e.__traceback__)


#####################
# import data
#####################


def create_buying_profile_total_kpi(conn, advertiser_ids):
    c = conn.cursor()
    print("Advertiser id to be imported ", advertiser_ids)
    data = []
    for val in advertiser_ids:
        # AND partition_date = {common_functions.partition_date.key}
        query = f"SELECT * FROM buying_profile_total_kpi WHERE advertiser_id = '{val}' "
        c.execute(query)
        data.append(CursorByName(c))
    #print("Total kpi", data)
    return data


def create_buying_profile_media_kpi(conn, advertiser_id):
    c = conn.cursor()
    data = []
    for val in advertiser_id:
        query = f"SELECT * FROM buying_profile_media_kpi WHERE advertiser_id = '{val}'"
        c.execute(query)
        data.append(CursorByName(c))
    #print("media kpi", data)
    return data


def create_buying_profile_product_kpi(conn, advertiser_id):
    c = conn.cursor()
    data = []
    for val in advertiser_id:
        query = f"SELECT * FROM buying_profile_product_kpi WHERE advertiser_id = '{val}'"
        c.execute(query)
        data.append(CursorByName(c))
    #print("product kpi", data)
    return data


def generate_advertiser_id(so_input_media):
    sql_variable = []
    for row in so_input_media:
        value = row["advertiser_id"]
        sql_variable.append(value)

    return list(set(sql_variable))


# TODO: convert to class
def import_data(simulation_id, mysql_connection, hive_connection):
    global so_input_overall
    global so_input_priority
    global so_input_media
    global so_input_product
    global buying_profile_total_kpi
    global buying_profile_media_kpi
    global buying_profile_product_kpi
    global advertiser_ids

    so_input_overall_query = f"SELECT * FROM so_input_overall WHERE simulation_id = '{simulation_id}'"
    so_input_priority_query = f"SELECT * FROM so_input_priority WHERE simulation_id = '{simulation_id}'"
    so_input_media_query = f"SELECT * FROM so_input_media WHERE simulation_id = '{simulation_id}'"
    so_input_product_query = f"SELECT * FROM so_input_product WHERE simulation_id = '{simulation_id}' "

    so_input_overall = execute_read_query(
        mysql_connection, so_input_overall_query)
    so_input_priority = execute_read_query(
        mysql_connection, so_input_priority_query)
    so_input_media = execute_read_query(
        mysql_connection, so_input_media_query)
    so_input_product = execute_read_query(
        mysql_connection, so_input_product_query)

    advertiser_ids = generate_advertiser_id(so_input_media)

    buying_profile_total_kpi = create_buying_profile_total_kpi(
        hive_connection, advertiser_ids)
    #print("Import total kpi", buying_profile_total_kpi)
    buying_profile_media_kpi = create_buying_profile_media_kpi(
        hive_connection, advertiser_ids)
    #print("Import media kpi", buying_profile_media_kpi)
    buying_profile_product_kpi = create_buying_profile_product_kpi(
        hive_connection, advertiser_ids)
    #print("Import product kpi", buying_profile_product_kpi)

    return so_input_overall, so_input_priority, so_input_media, so_input_product, buying_profile_total_kpi, buying_profile_media_kpi, buying_profile_product_kpi

#####################
# Buyer profile
#####################


def load_overall_with_BuyerProfile():
    for advertiser_id in advertiser_ids:
        Overall.buyer_profiles.append(BuyerProfile(advertiser_id))


def create_buyerprofile():
    Overall.load_Overall()
    MediaPriority.load_Priority()

    load_overall_with_BuyerProfile()
    print("Buyer profile created")
    return BuyerProfile


#####################
# Order optimizer
#####################


def order_optimizer():
    print("Running model")
    BuyerProfile_recommend = []
    for buyerprofile in Overall.buyer_profiles:
        print("Loading products for ", buyerprofile.advertiser_id)
        BuyerProfile_recommend = generate_recommend(buyerprofile)
        print("Products loaded")
    print("Model done.")
    return BuyerProfile_recommend


def generate_recommend(BuyerProfile):
    if BuyerProfile.advertiser_id == "test_ad_id_1":
        for media in BuyerProfile.media_package:
            if media.media_type == 'digital':
                for product in media.products:
                    product.recommend_product = "catalog_1"
    if BuyerProfile.advertiser_id == "0011j00000Ej6MSAAZ":
        for media in BuyerProfile.media_package:
            if media.media_type == 'digital':
                for product in media.products:
                    setattr(product, "recommend_product",
                            "a0I1l000001yz61EAA")
            elif media.media_type == 'print':
                for product in media.products:
                    setattr(product, "recommend_product",
                            "a0405000000oAOFAA2")
            elif media.media_type == 'tv_linear':
                for product in media.products:
                    setattr(product, "recommend_product",
                            "a0405000000nWlOAAU")
    if BuyerProfile.advertiser_id == "0011l00000bMbmwAAC":
        for media in BuyerProfile.media_package:
            if media.media_type == 'digital':
                for product in media.products:
                    setattr(product, "recommend_product",
                            "a0I1l000002m7wXEAQ")
            elif media.media_type == 'print':
                for product in media.products:
                    setattr(product, "recommend_product",
                            "a0405000000sN3bDNE")
            elif media.media_type == 'tv_linear':
                for product in media.products:
                    setattr(product, "recommend_product",
                            "a0405000000ndGuAAI")
    if BuyerProfile.advertiser_id == "0011l00000YaqnMAAR":
        for media in BuyerProfile.media_package:
            if media.media_type == 'digital':
                for product in media.products:
                    setattr(product, "recommend_product",
                            "a0I1j0000006nZTEAY")
            elif media.media_type == 'print':
                for product in media.products:
                    setattr(product, "recommend_product",
                            "a0405000000oA3oAAE")
            elif media.media_type == 'tv_linear':
                for product in media.products:
                    setattr(product, "recommend_product",
                            "a0405000000ndN7AAI")
    if BuyerProfile.advertiser_id == "0011q00000eTiFyAAK":
        for media in BuyerProfile.media_package:
            if media.media_type == 'digital':
                for product in media.products:
                    setattr(product, "recommend_product",
                            "a0I1j0000006oAPEAY")
            elif media.media_type == 'print':
                for product in media.products:
                    setattr(product, "recommend_product",
                            "a0405000000oN3bCAE")
            elif media.media_type == 'tv_linear':
                for product in media.products:
                    setattr(product, "recommend_product",
                            "a0405000000ndQ6AAI")
    if BuyerProfile.advertiser_id == "0011l00000YcnMzAAJ":
        for media in BuyerProfile.media_package:
            if media.media_type == 'digital':
                for product in media.products:
                    setattr(product, "recommend_product",
                            "a0I1j0000007LUXEA2")
            elif media.media_type == 'print':
                for product in media.products:
                    setattr(product, "recommend_product",
                            "a0405000000sN3bDAE")
            elif media.media_type == 'tv_linear':
                for product in media.products:
                    setattr(product, "recommend_product",
                            "a0405000000nd00AAA")
    print(product.recommend_product)
    return BuyerProfile


#####################
# create product list
#####################

def generate_inventory_query(catalogue_id):
    return f"SELECT * FROM so_inventory WHERE catalog_item_id = '{catalogue_id}'"


def generate_product_query(catalogue_id):
    return f"""SELECT STG_SA_CatalogItem.catalog_item_id,
                       STG_SA_CatalogItem.parent_id,
                       STG_SA_CatalogItem.display_name,
                       STG_SA_CatalogItem.media_type,
                       STG_SA_CatalogItem.catalog_level,
                       STG_SA_CatalogItem.record_type,
                       STG_SA_Price_Item.price_item_id,
                       STG_SA_Price_Item.currency,
                       STG_SA_Price_Item.commercial_audience,
                       STG_SA_Price_Item.price_list,
                       STG_SA_Price_Item.price_per_unit,
                       STG_SA_Price_Item.spot_length,
                       STG_SA_Price_Item.unit_of_measure,
                       STG_SA_AdFormatSpec.breadcrumb
                       FROM STG_SA_Price_Item
                       INNER JOIN STG_SA_CatalogItem
                       ON STG_SA_Price_Item.catalog_item_id = STG_SA_CatalogItem.catalog_item_id
                       INNER JOIN STG_SA_AdFormatSpec
                       ON STG_SA_Price_Item.catalog_item_id = STG_SA_AdFormatSpec.catalog_item_id
                       WHERE STG_SA_Price_Item.catalog_item_id = '{catalogue_id}' 
                       LIMIT 1"""


def pull_product_data(catalogue_id, mysql_connection, hive_connection):
    query = generate_product_query(catalogue_id)
    data = execute_read_query(mysql_connection, query)
    return data


def update_product(product, mysql_connection, hive_connection):
    catalogue_id = product.recommend_product
    print("Pulling data for", catalogue_id)
    product.recommend_product = pull_product_data(
        catalogue_id, mysql_connection, hive_connection)


def add_data(BuyerProfile, mysql_connection, hive_connection):
    for media in BuyerProfile.media_package:
        for product in media.products:
            update_product(product, mysql_connection, hive_connection)
    return BuyerProfile


def create_product_list(mysql_connection, hive_connection):
    BuyerProfile_recommend_dets = []
    for buyerprofile in Overall.buyer_profiles:
        BuyerProfile_recommend_dets = add_data(
            buyerprofile, mysql_connection, hive_connection)
    return BuyerProfile_recommend_dets


#####################
# Create campaign
#####################


def generate_product_campaign(conn, product, media):
    print("Creating campaign products for", product)

    product_campaign = output_product(product, media)
    print("Writing to so_output_product")
    product_campaign.write_to_database(conn)

    return product_campaign


def generate_media_campaign(conn, media):
    product_list = []

    for product in media.products:
        product_campaign = generate_product_campaign(conn, product, media)
        product_list.append(product_campaign)
    print("product_list", product_list)
    # output_overall_media.calculate_summary(product_list)

    for product in product_list:
        if (product.record_type == 'Format' or
            product.record_type == 'Format' or
                product.record_type == 'FORMAT'):
            print("Creating overall_media campaign for", product)
            out_media = output_overall_media(product, media)
            print("Writing to so_output_overall_media")
            out_media.write_to_database(conn)
        else:
            continue

    media_campaign = output_media(media, product_list)
    media_campaign.write_to_database(conn)

    return media_campaign


def generate_campaign(conn, BuyerProfile):
    media_list = []
    for media in BuyerProfile.media_package:
        media_campaign = generate_media_campaign(conn, media)
        media_list.append(media_campaign)

    return media_list


def create_campaign(conn):
    for buyerprofile in Overall.buyer_profiles:
        output_overall.init_load_output_overall(
            buyerprofile)  # load stable datafields
        campaign = generate_campaign(conn, buyerprofile)
        output_overall.post_load_output_overall(campaign)
        print("Writing to so_output_overall")
        output_overall.write_to_database(conn)


def run_intergrtation_check():

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
    except:
        raise ConnectionError("SQL Connection Failed.")

    try:
        buying_profile_total_kpi = {}
        buying_profile_media_kpi = {}
        buying_profile_product_kpi = {}
        hive_database = {"buying_profile_total_kpi": buying_profile_total_kpi,
                         "buying_profile_media_kpi": buying_profile_media_kpi,
                         "buying_profile_product_kpi": buying_profile_product_kpi}

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

    try:
        so_input_overall = {}
        so_input_priority = {}
        so_input_media = {}
        so_input_product = {}
        STG_SA_Price_Item = {}
        STG_SA_CatalogItem = {}
        STG_SA_AdFormatSpec = {}
        mySQL_database = {"so_input_overall": so_input_overall,
                          "so_input_priority": so_input_priority,
                          "so_input_media": so_input_media,
                          "so_input_product": so_input_product,
                          "STG_SA_Price_Item": STG_SA_Price_Item,
                          "STG_SA_CatalogItem": STG_SA_CatalogItem,
                          "STG_SA_AdFormatSpec": STG_SA_AdFormatSpec}

        for key, value in mySQL_database.items():
            print(f"Checking {key} database")
            value = execute_read_query(
                mysql_connection, f"SELECT * FROM {key} LIMIT 1")
            if not value:
                print(key + " - FAILED")
            else:
                print(key + " - PASSED")

    except Exception as e:
        print("mySQL Database Connection failed.", e)
        traceback.print_tb(e.__traceback__)

    return 0


def generate_sim_id(conn):
    # Replace partition_date.key with 20211101 for testing partition_date.key
    value = partition_date.key
    query = f"SELECT simulation_id FROM so_input_overall WHERE partition_date = {value} AND lower(status) = 'active'"
    simulation_ids = execute_read_query(conn, query)
    print(simulation_ids, value)
    return simulation_ids


def run_simulation(simulation_id):

    if simulation_id == None:
        raise ValueError("No Simulation_id found.")

    try:
        mysql_connection = create_mysql_connection()
        hive_connection = create_hive_connection()
        print("Establishing Hive and MySQl connections")
    except Exception as e:
        print("Connection failed.", e)
        traceback.print_tb(e.__traceback__)

    try:
        output = import_data(simulation_id, mysql_connection, hive_connection)
        print("Data Import sucessful.")
    except Exception as e:
        print(f"Data Import Failed.{e}")
        traceback.print_tb(e.__traceback__)

    try:
        buyer_output = create_buyerprofile()
        print("Buyer creation successful", buyer_output)
    except Exception as e:
        print(f"Buyer creation Failed.{e}")
        traceback.print_tb(e.__traceback__)

    try:
        buyer_rec = order_optimizer()
        print("Engine Successful", buyer_rec)
    except Exception as e:
        print("Engine Execution Failed.", e)
        traceback.print_tb(e.__traceback__)

    try:
        buyer_recomm_dets = create_product_list(
            mysql_connection, hive_connection)
        print("Product details successful", buyer_recomm_dets,)
        create_campaign(mysql_connection)
        print("Campaign successful", mysql_connection)
    except Exception as e:
        print("Campaign Creation Failed.", e)
        traceback.print_tb(e.__traceback__)

    return 0


def main():
    conn = create_mysql_connection()
    simulation_ids = generate_sim_id(conn)
    print(simulation_ids)
    if not simulation_ids:
        print('No simulations id found.')

    for row in simulation_ids:
        print(f"Running Simulation for ", row["simulation_id"])
        run_simulation(row["simulation_id"])
    return 0


if __name__ == "__main__":

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

    try:
        run_intergrtation_check()
        main()

    except Exception as e:
        print(e)
        traceback.print_tb(e.__traceback__)
