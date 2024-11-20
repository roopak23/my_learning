# Functional test for Inventory Forecast
# Author: Jackson wong
# Email: jackson.c.wong@accenture.com
# Notes: Optional module pytest-cov for code coverage test (MIT license)
#        DOC: https://pytest-cov.readthedocs.io/en/latest/index.html
#        Cmd "pytest --cov --cov=inventoryoptimization --cov-branch --cov-report=term-missing"


import pytest
import sqlite3
import os
import datetime
import csv
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

# ml_invforecastinginput
@pytest.fixture(scope="module")
def create_ml_invforecastinginput(conn):
    cur = conn.cursor()
    cur.execute("""CREATE TABLE ml_invforecastinginput (date,
                                                        adserver_adslot_id,
                                                        adserver_id,
                                                        adserver_target_remote_id,
                                                        adserver_target_name,
                                                        historical_capacity,
                                                        metric,
                                                        partition_date)""")

    with open('ml_invforecastinginput_dummy.csv', 'r') as fin:
        # csv.DictReader uses first line in file for column headings by default
        dr = csv.DictReader(fin)  # comma is default delimiter
        to_db = [(i['date'],
                  i['adserver_adslot_id'],
                  i['adserver_id'],
                  i['adserver_target_remote_id'],
                  i['adserver_target_name'],
                  i['historical_capacity'],
                  i['metric'],
                  i['partition_date']) for i in dr]

        cur.executemany("""INSERT INTO ml_invforecastinginput (date,
                                                        adserver_adslot_id,
                                                        adserver_id,
                                                        adserver_target_remote_id,
                                                        adserver_target_name,
                                                        historical_capacity,
                                                        metric,
                                                        partition_date) 
                                                        VALUES (?, ?, ?, ?, ?, ?, ?, ?)""", to_db)
        conn.commit()
        yield
        conn.close()


@pytest.fixture(scope="module")
def inputs():
    data_table = {
        "inv_input_table": "ml_invforecastinginput",
        "inv_segment_table": "trf_invfuturesegment",
        "output_table": "ml_invforecastingoutputsegment",
        "ML_tuning_output_table": "ml_invforecastingmodelkpi"}

    value_for_model = {
        "days": 30,
        "metrics": 'IMPRESSION',
        "historical_ratio": 1,
        "information_criterion": "bic",
        "max_p": 7,
        "max_q": 7,
        "max_d": 3,
        "max_P": 3,
        "max_Q": 3,
        "max_D": 2,
        "start_p": 7,
        "start_q": 1,
        "stationary": False,
        "error_action": "ignore",
        "suppress_warnings": True,
        "train": 0.7
    }

    return data_table, value_for_model


@pytest.fixture(scope="module")
def dataframe(conn):

    #####################
    #  Test
    #####################


def test_generate_sim_id(conn, create_ml_invforecastinginput):
    cur = conn.cursor()
    value = cur.execute('SELECT * from ml_invforecastinginput').fetchone()
    print(value)
    assert value == 123


def test_RunModel(inputs):
    main.RunModel()
