# Functional test for Inventory Optimisation
# Author: Jackson wong
# Email: jackson.c.wong@accenture.com
# Notes: Optional module pytest-cov for code coverage test (MIT license)
#        DOC: https://pytest-cov.readthedocs.io/en/latest/index.html
#        Cmd "pytest --cov --cov=inventoryoptimization --cov-branch --cov-report=term-missing"
# Date: 8 Spet 2021


import pytest
import sqlite3
import os
import datetime
import main


class partition_date():
    key = (datetime.date.today() - datetime.timedelta(days=1)).strftime('%Y%m%d')


@pytest.fixture(scope="module")
def conn():
    conn = sqlite3.connect("test_data.db")
    yield conn
    conn.close()
    os.remove("test_data.db")


#####################
# Generate databases
#####################

# so_input_*
@pytest.fixture(scope="module")
def create_so_input_overall_data(conn):
    cur = conn.cursor()
    cur.execute("""CREATE TABLE so_input_overall(
                        simulation_id integer,
                        simulation_name text,
                        simulation_date integer,
                        created_by text,
                        update_date integer,
                        update_by text,
                        start_date integer,
                        end_date integer,
                        revenue_max integer,
                        inventory_saturation integer,
                        status text,
                        partition_date integer
                        )""")
    cur.execute(f"""INSERT INTO so_input_overall
                        VALUES(123,
                                'test_sim_name_1',
                                20220101,
                                'test_creator_1',
                                20220102,
                                'test_updator_1',
                                20220201,
                                20220431,
                                1,
                                0,
                                'Active',
                                {partition_date.key})""")
    '''
    cur.execute(f"""INSERT INTO so_input_overall
                        VALUES(234,
                                'test_sim_name_2',
                                20220101,
                                'test_creator_2',
                                20220102,
                                'test_updator_2',
                                20220201,
                                20220431,
                                0,
                                1,
                                'Active',
                                {partition_date.key})""")
    cur.execute(f"""INSERT INTO so_input_overall
                        VALUES(345,
                                'test_sim_name_3',
                                20220101,
                                'test_creator_3',
                                20220102,
                                'test_updator_3',
                                20220201,
                                20220431,
                                0,
                                1,
                                'Pending',
                                {partition_date.key})""")
    '''
    conn.commit()
    cur = conn.cursor()
    cur.execute("SELECT * FROM so_input_overall")
    so_input_overall = []
    for row in main.CursorByName(cur):
        so_input_overall.append(row)
    yield so_input_overall
    cur.close()


@pytest.fixture(scope="module")
def create_so_input_priority_data(conn):
    cur = conn.cursor()
    cur.execute("""CREATE TABLE so_input_priority(
                            simulation_id text,
                            media_type text,
                            media_priority integer,
                            media_perc real,
                            partition_date integer)""")
    cur.execute(f"""INSERT INTO so_input_priority
                        VALUES(123,
                                'digital',
                                1,
                                20,
                                {partition_date.key})""")
    '''
    cur.execute(f"""INSERT INTO so_input_priority
                        VALUES(234,
                                'tv_linear',
                                1,
                                30,
                                {partition_date.key})""")
    '''
    conn.commit()
    cur = conn.cursor()
    cur.execute("SELECT * FROM so_input_priority")
    so_input_priority = []
    for row in main.CursorByName(cur):
        so_input_priority.append(row)
    yield so_input_priority
    cur.close()


@pytest.fixture(scope="module")
def create_so_input_media_data(conn):
    cur = conn.cursor()
    cur.execute("""CREATE TABLE so_input_media(
                            simulation_id text,
                            advertiser_id text,
                            advertiser_name	text,
                            media_type text,
                            desired_budget_media_type	integer,
                            desired_metric_media_type	integer,
                            unit_of_measure_media_type	text,
                            cp_media_type integer,
                            monday integer,
                            tuesday integer,
                            wednesday integer,
                            thursday integer,
                            friday integer,
                            saturday integer,
                            sunday integer,
                            brand_name string,
                            partition_date integer)""")
    cur.execute(f"""INSERT INTO so_input_media
                            VALUES(123,
                                'test_ad_id_1',
                                'test_ad_name_1',
                                'digital',
                                400000,
                                1000000,
                                'CPC',
                                1,
                                1,
                                1,
                                1,
                                1,
                                1,
                                0,
                                0,
                                'test_brand_ad_1',
                                {partition_date.key}
                                )""")
    cur.execute(f"""INSERT INTO so_input_media
                        VALUES(123,
                                'test_ad_id_1',
                                'test_ad_name_1',
                                'Radio',
                                600000,
                                1000000,
                                'CPC',
                                2,
                                0,
                                0,
                                0,
                                0,
                                0,
                                1,
                                1,
                                'test_brand_ad_1',
                                {partition_date.key})""")
    '''
    cur.execute(f"""INSERT INTO so_input_media
                        VALUES(234,
                                'test_ad_id_2',
                                'test_ad_name_2',
                                'digital',
                                100000,
                                1000000,
                                'CPC',
                                1,
                                1,
                                1,
                                1,
                                1,
                                1,
                                0,
                                0,
                                'test_brand_ad_2',
                                {partition_date.key})""")
    cur.execute(f"""INSERT INTO so_input_media
                        VALUES(234,
                                'test_ad_id_2',
                                'test_ad_name_2',
                                'tv_linear',
                                200000,
                                1000000,
                                'CPC',
                                2,
                                1,
                                1,
                                1,
                                1,
                                1,
                                0,
                                0,
                                'test_brand_ad_2',
                                {partition_date.key})""")
    cur.execute(f"""INSERT INTO so_input_media
                        VALUES(234,
                                'test_ad_id_2',
                                'test_ad_name_2',
                                'print',
                                700000,
                                1000000,
                                'CPC',
                                3,
                                1,
                                1,
                                1,
                                1,
                                1,
                                0,
                                0,
                                'test_brand_ad_2',
                                {partition_date.key})""")
    '''
    conn.commit()
    cur = conn.cursor()
    cur.execute("SELECT * FROM so_input_media")
    so_input_media = []
    for row in main.CursorByName(cur):
        so_input_media.append(row)
    yield so_input_media
    cur.close()


@pytest.fixture(scope="module")
def create_so_input_product_data(conn):
    cur = conn.cursor()
    cur.execute("""CREATE TABLE so_input_product(
                            simulation_id text,
                            advertiser_id text,
                            advertiser_name text,
                            catalog_level integer,
                            record_type text,
                            perc_value real,
                            media_type text,
                            catalog_item_id text,
                            length integer,
                            display_name text,
                            brand_name text,
                            partition_date integer)""")
    cur.execute(f"""INSERT INTO so_input_product
                        VALUES(123,
                                'test_ad_id_1',
                                'test_ad_name_1',
                                1,
                                'recod_type-1',
                                100000,
                                'digital',
                                'catalog_item_id_1',
                                30,
                                'display_name_1',
                                'brand_name_1',
                                {partition_date.key})""")
    conn.commit()
    cur = conn.cursor()
    cur.execute("SELECT * FROM so_input_product")
    so_input_product = []
    for row in main.CursorByName(cur):
        so_input_product.append(row)
    yield so_input_product
    cur.close()


# buying_profile

@pytest.fixture(scope="module")
def create_buying_profile_total_kpi_data(conn):
    cur = conn.cursor()
    cur.execute("""CREATE TABLE buying_profile_total_kpi(
                            advertiser_id text,
                            advertiser_name	text,
                            brand_name text,
                            audience text,
                            cp_total_audience real,
                            avg_daily_budget real,
                            avg_lines real,
                            partition_date integer)""")
    cur.execute(f"""INSERT INTO buying_profile_total_kpi
                        VALUES('test_ad_id_1',
                                'test_ad_name_1',
                                'test_brand_name_1',
                                'audience_1',
                                100,
                                10000,
                                5,
                                {partition_date.key}
                                )""")
    '''
    cur.execute(f"""INSERT INTO buying_profile_total_kpi
                        VALUES('test_ad_id_2',
                                'test_ad_name_2',
                                'test_brand_name_2',
                                'audience_2',
                                100,
                                20000,
                                5,
                                {partition_date.key}
                                )""")
    '''
    conn.commit()
    cur = conn.cursor()
    cur.execute("SELECT * FROM buying_profile_total_kpi")
    buying_profile_total_kpi = []
    for row in main.CursorByName(cur):
        buying_profile_total_kpi.append(row)
    yield buying_profile_total_kpi
    cur.close()


@pytest.fixture(scope="module")
def create_buying_profile_media_kpi_data(conn):
    cur = conn.cursor()
    cur.execute("""CREATE TABLE buying_profile_media_kpi(
                            advertiser_id text,
                            advertiser_name	text,
                            brand_name text,
                            industry text,
                            media_type text,
                            unit_of_measure text,
                            desired_metric_daily_avg real,
                            cp_media_type real,
                            desired_avg_budget_daily real,
                            avg_lines real,
                            selling_type text,
                            partition_date integer)""")
    cur.execute(f"""INSERT INTO buying_profile_media_kpi
                        VALUES('test_ad_id_1',
                                'test_ad_name_1',
                                'test_brand_name_1',
                                'inductry_1',
                                'digital',
                                'impression',
                                '100',
                                '100',
                                '100',
                                '5',
                                'selling_1',
                                {partition_date.key})""")
    cur.execute(f"""INSERT INTO buying_profile_media_kpi
                        VALUES('test_ad_id_1',
                                'test_ad_name_1',
                                'test_brand_name_1',
                                'inductry_1',
                                'Radio',
                                'impression',
                                '100',
                                '100',
                                '100',
                                '5',
                                'selling_1',
                                {partition_date.key})""")
    '''
    cur.execute(f"""INSERT INTO buying_profile_media_kpi
                        VALUES('test_ad_id_1',
                                'test_ad_name_1',
                                'test_brand_name_1',
                                'inductry_1',
                                'tv_linear',
                                'impression',
                                '100',
                                '100',
                                '100',
                                '5',
                                'selling_1',
                                {partition_date.key})""")
    cur.execute(f"""INSERT INTO buying_profile_media_kpi
                        VALUES('test_ad_id_1',
                                'test_ad_name_1',
                                'test_brand_name_1',
                                'inductry_1',
                                'print',
                                'impression',
                                '100',
                                '100',
                                '100',
                                '5',
                                'selling_1',
                                {partition_date.key})""")
    '''
    conn.commit()
    cur = conn.cursor()
    cur.execute("SELECT * FROM buying_profile_media_kpi")
    buying_profile_media_kpi = []
    for row in main.CursorByName(cur):
        buying_profile_media_kpi.append(row)
    yield buying_profile_media_kpi
    cur.close()


@pytest.fixture(scope="module")
def create_buying_profile_product_kpi_data(conn):
    cur = conn.cursor()
    cur.execute("""CREATE TABLE buying_profile_product_kpi(
                                advertiser_id text,
                                advertiser_name	text,
                                brand_name text,
                                catalog_level integer,
                                industry text,
                                record_type	text,
                                media_type text,
                                length integer,
                                display_name text,
                                perc_value real,
                                partition_date integer)""")
    cur.execute(f"""INSERT INTO buying_profile_product_kpi
                        VALUES('test_ad_id_1',
                                'test_ad_name_1',
                                'test_brand_name_1',
                                1,
                                'inductry_1',
                                'record_1',
                                'digital',
                                30,
                                'display_name_1',
                                10,
                                {partition_date.key})""")
    conn.commit()
    cur = conn.cursor()
    cur.execute("SELECT * FROM buying_profile_product_kpi")
    buying_profile_product_kpi = []
    for row in main.CursorByName(cur):
        buying_profile_product_kpi.append(row)
    yield buying_profile_product_kpi
    cur.close()


# data


@pytest.fixture(scope="module")
def create_so_inventory_data(conn):
    cur = conn.cursor()
    cur.execute("""CREATE TABLE so_inventory(
                            date text,
                            adserver_adslot_name text,
                            adserver_adslot_id text,
                            unit_type text,
                            media_type text,
                            catalog_value text,
                            record_type text,
                            catalog_item_name text,
                            adserver_target_remote_id text,
                            adserver_target_name text,
                            adserver_target_type text,
                            adserver_target_category text,
                            adserver_target_code text,
                            future_capacity integer,
                            booked integer,
                            reserved integer)""")
    cur.execute(f"""INSERT INTO so_inventory
                        VALUES('1-01-2022',
                                'adserver_adslot_name_1',
                                'adserver_adslot_id_1',
                                'cpm',
                                'digital',
                                '100',
                                'site',
                                'catalog_1',
                                'adserver_target_remote_id_1',
                                'adserver_target_name_1',
                                'AUDIENCE',
                                'adserver_target_category_1',
                                'adserver_target_code_1',
                                '100',
                                '20',
                                '20')""")
    conn.commit()
    cur = conn.cursor()
    cur.execute("SELECT * FROM so_inventory")
    so_inventory = []
    for row in main.CursorByName(cur):
        so_inventory.append(row)
    yield so_inventory
    cur.close()


@pytest.fixture(scope="module")
def create_STG_sa_price_item(conn):
    cur = conn.cursor()
    cur.execute("""CREATE TABLE STG_sa_price_item(
                            price_item_id text,
                            catalog_item_name text,
                            currency text,
                            commercial_audience text,
                            price_list text,
                            price_per_unit real,
                            spot_length real,
                            unit_of_measure text,
                            datasource text,
                            partition_date integer)""")
    cur.execute(f"""INSERT INTO STG_sa_price_item
                        VALUES(
                            "price_item_id",
                            "catalog_1",
                            "AUD",
                            "commercial_audience",
                            100,
                            5,
                            30,
                            "CPM",
                            "datasource_1",
                            {partition_date.key})""")
    conn.commit()
    cur = conn.cursor()
    cur.execute("SELECT * FROM STG_sa_price_item")
    STG_sa_price_item = []
    for row in main.CursorByName(cur):
        STG_sa_price_item.append(row)
    yield STG_sa_price_item
    cur.close()


@pytest.fixture(scope="module")
def create_STG_sa_catalogitem(conn):
    cur = conn.cursor()
    cur.execute("""CREATE TABLE STG_sa_catalogitem(
                            catalog_item_id text,
                            name text,
                            parent_id text,
                            display_name text,
                            media_type text,
                            catalog_level integer,
                            record_type text,
                            commercial_audience text,
                            age integer,
                            gender text,
                            interest text,
                            datasource text,
                            partition_date text)""")
    cur.execute(f"""INSERT INTO STG_sa_catalogitem
                        VALUES('catalog_item_id',
                                'catalog_1',
                                'parent_id',
                                'display_name',
                                'digital',
                                1,
                                'site',
                                'commercial_audience',
                                10,
                                'male',
                                'sport',
                                'datasource_1',
                            {partition_date.key})""")
    conn.commit()
    cur = conn.cursor()
    cur.execute("SELECT * FROM STG_sa_catalogitem")
    STG_sa_catalogitem = []
    for row in main.CursorByName(cur):
        STG_sa_catalogitem.append(row)
    yield STG_sa_catalogitem
    cur.close()

# so_output


@pytest.fixture(scope="module")
def create_so_output(conn):
    cur = conn.cursor()
    cur.execute("""CREATE TABLE so_output_overall(
                        simulation_id text,
                        advertiser_id text,
                        advertiser_name text,
                        brand_name text,
                        total_audience text,
                        budget_total real,
                        audience text,
                        cp_total_audience real,
                        total_quantity real)""")
    cur.execute("""CREATE TABLE so_output_overall_media(
                        simulation_id text,
                        advertiser_id text,
                        advertiser_name text,
                        brand_name text,
                        breadcrumb text,
                        media_type text,
                        length integer,
                        perc_length real,
                        quantity integer,
                        format_id text,
                        partition_date integer)""")
    cur.execute("""CREATE TABLE so_output_media(
                        simulation_id text,
                        advertiser_id text,
                        advertiser_name text,
                        brand_name text,
                        media_type text,
                        budget_media_type real,
                        metric_media_type text,
                        unit_of_measure_media_type text,
                        cp_media real,
                        total_audience text)""")
    cur.execute("""CREATE TABLE so_output_product(
                        simulation_id text,
                        advertiser_id text,
                        advertiser_name text,
                        brand_name text,
                        catalog_level integer,
                        record_type text,
                        perc_value real,
                        media_type text,
                        catalog_item_id text,
                        length integer,
                        display_name text,
                        status text)""")
    conn.commit()


#####################
# Custom components
#####################


@pytest.fixture(scope="module")
def create_data(conn, create_so_input_overall_data,
                create_so_input_priority_data,
                create_so_input_media_data,
                create_so_input_product_data,
                create_buying_profile_total_kpi_data,
                create_buying_profile_media_kpi_data,
                create_buying_profile_product_kpi_data):
    output = main.import_data(123, conn, conn)
    yield output


@pytest.fixture(scope="module")
def create_buyer(conn, create_data):
    so_input_overall = create_data[0]
    so_input_priority = create_data[1]
    so_input_media = create_data[2]
    so_input_product = create_data[3]
    buying_profile_total_kpi = create_data[4]
    buying_profile_media_kpi = create_data[5]
    buying_profile_product_kpi = create_data[6]

    buyer_output = main.create_buyer_profile()
    yield buyer_output


@pytest.fixture(scope="module")
def create_buyer_recc(conn, create_buyer):
    BuyerProfile_init = create_buyer
    BuyerProfile_rec = main.order_optimizer()
    return BuyerProfile_rec


#####################
# Main.py Test
#####################


def test_invalid_simulation_id():
    with pytest.raises(ValueError, match=r"No Simulation_id found."):
        simulation_id = None
        main.run_simulation(simulation_id)


def test_generate_sim_id(conn, create_so_input_overall_data):
    simulation_ids = main.generate_sim_id(conn)
    assert simulation_ids[0]["simulation_id"] == 123


#####################
# Import_data.py Test
#####################


def test_import_data(conn, create_so_input_overall_data,
                     create_so_input_priority_data,
                     create_so_input_media_data,
                     create_so_input_product_data,
                     create_buying_profile_total_kpi_data,
                     create_buying_profile_media_kpi_data,
                     create_buying_profile_product_kpi_data):
    output = main.import_data(123, conn, conn)
    so_input_overall = output[0]
    so_input_priority = output[1]
    so_input_media = output[2]
    so_input_product = output[3]
    buying_profile_total_kpi = output[4]
    buying_profile_media_kpi = output[5]
    buying_profile_product_kpi = output[6]

    assert so_input_overall[0]["simulation_id"] == 123
    assert so_input_priority[0]["media_type"] == 'digital'
    assert so_input_media[0]["advertiser_id"] == "test_ad_id_1"
    assert so_input_product[0]["record_type"] == 'recod_type-1'
    assert buying_profile_total_kpi[0]["avg_daily_budget"] == 10000
    assert buying_profile_media_kpi[0]["unit_of_measure"] == 'impression'
    assert buying_profile_product_kpi[0]["brand_name"] == 'test_brand_name_1'

#####################
# create_buyer_profile.py Test
#####################


def test_create_buyer_profile(conn, create_data):
    so_input_overall = create_data[0]
    so_input_priority = create_data[1]
    so_input_media = create_data[2]
    so_input_product = create_data[3]
    buying_profile_total_kpi = create_data[4]
    buying_profile_media_kpi = create_data[5]
    buying_profile_product_kpi = create_data[6]

    buyer_output = main.create_buyer_profile()
    assert buyer_output.media_package[0].products[0].kpi_length == 30


#####################
# create_campaign test
#####################


def test_order_optimiser(conn, create_buyer):
    BuyerProfile_init = create_buyer
    BuyerProfile_rec = main.order_optimizer()
    assert BuyerProfile_rec.media_package[0].products[0].recommend_product == "catalog_1"


#####################
# create product test
#####################


def test_create_order_dets(conn, create_buyer_recc, create_so_inventory_data, create_STG_sa_price_item, create_STG_sa_catalogitem):
    BuyerProfile_recommend = create_buyer_recc
    buyer_recomm_dets = main.create_product_list(conn, conn)

    assert buyer_recomm_dets.media_package[0].products[
        0].recommend_product["adserver_adslot_id"] == "adserver_adslot_id_1"


#####################
# create campaign
#####################


""" def test_campaign_create(conn, create_so_output):
    main.create_campaign(conn)
    so_output_product = main.execute_read_query(
        conn, "SELECT * FROM so_output_product")
    so_output_media = main.execute_read_query(
        conn, "SELECT * FROM so_output_media")
    so_output_overall_media = main.execute_read_query(
        conn, "SELECT * FROM so_output_overall_media")

    assert so_output_product[0]['display_name'] == 'display_name'
    assert so_output_media[0]["unit_of_measure_media_type"] == 'CPC'
    assert so_output_overall_media[0]["quantity"] == 100
 """


def test_simulation(conn, create_so_input_overall_data,
                    create_so_input_priority_data,
                    create_so_input_media_data,
                    create_so_input_product_data,
                    create_buying_profile_total_kpi_data,
                    create_buying_profile_media_kpi_data,
                    create_buying_profile_product_kpi_data,
                    create_so_inventory_data,
                    create_STG_sa_price_item,
                    create_STG_sa_catalogitem,
                    create_so_output):
    main.run_simulation(123, conn, conn)
    so_output_product = main.execute_read_query(
        conn, "SELECT * FROM so_output_product")
    so_output_media = main.execute_read_query(
        conn, "SELECT * FROM so_output_media")
    so_output_overall_media = main.execute_read_query(
        conn, "SELECT * FROM so_output_overall_media")

    assert so_output_product[0]['display_name'] == 'display_name'
    assert so_output_media[0]["unit_of_measure_media_type"] == 'CPC'
    assert so_output_overall_media[0]["quantity"] == 100
