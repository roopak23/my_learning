import json
import pandas as pd
import numpy as np
import pymysql
import sys, os

import logging


# Get Stack Name
rds_host  = os.environ['ENDPOINT']
name = os.environ['USERNAME']
password = os.environ['PASSWORD']
bucket = os.environ['BUCKET']
sns_topic_arn = os.environ['SNS_TOPIC_ARN']
env = os.environ['ENVIRONMENT']


logger = logging.getLogger()
logger.setLevel(logging.INFO)

pd.set_option('display.max_rows', None)
pd.set_option('display.max_columns', None)


def tableize(df):
    if not isinstance(df, pd.DataFrame):
        return
    df_columns = df.columns.tolist() 
    max_len_in_lst = lambda lst: len(sorted(lst, reverse=True, key=len)[0])
    align_center = lambda st, sz: "{0}{1}{0}".format(" "*(1+(sz-len(st))//2), st)[:sz] if len(st) < sz else st
    align_right = lambda st, sz: "{0}{1} ".format(" "*(sz-len(st)-1), st) if len(st) < sz else st
    max_col_len = max_len_in_lst(df_columns)
    max_val_len_for_col = dict([(col, max_len_in_lst(df.iloc[:,idx].astype('str'))) for idx, col in enumerate(df_columns)])
    col_sizes = dict([(col, 2 + max(max_val_len_for_col.get(col, 0), max_col_len)) for col in df_columns])
    build_hline = lambda row: '+'.join(['-' * col_sizes[col] for col in row]).join(['+', '+'])
    build_data = lambda row, align: "|".join([align(str(val), col_sizes[df_columns[idx]]) for idx, val in enumerate(row)]).join(['|', '|'])
    hline = build_hline(df_columns)
    out = [hline, build_data(df_columns, align_center), hline]
    for _, row in df.iterrows():
        out.append(build_data(row.tolist(), align_right))
    out.append(hline)
    return "\n".join(out)


def data_extract(db_name, table_name):
    """
    This function fetches content from mysql RDS instance
    """
    try:
        conn = pymysql.connect(host = rds_host, user=name, passwd=password, db=db_name)
        logger.info(f"Connection to {db_name} was successfuly.")
        result = pd.read_sql("Select * from data_activation.{table_name}".format(table_name = table_name), conn)
        conn.close()
        row_count = result.shape[0]
        # Check row_count returned from query
        if(row_count == 0):
            print("query returned 0-rows")
            return result
        else:
            return result

    except Exception as e:
        logger.error(f"ERROR: {e}.")
        sys.exit()


def checker(df, condition):
    """
    Split DF by condition, return 2 dfs:
    first one with true values
    second one with false values
    """
    marker = np.where(condition, True, False)

    true = df[marker]
    false = df[~marker]

    return true, false


def main(partition_date: int):
    
    # get data from table
    metatable = data_extract("monitoring","ingestion_metadata")

    # filter by partition_date
    metatable = metatable.loc[metatable['partition_date'] == partition_date]

    # total_rows > rows_loaded
    true, false = checker(metatable, metatable["total_rows"] > metatable["rows_loaded"]) 
    
    # total_rows < rows_loaded
    loaded_greater_readed, success = checker(false, false["total_rows"] < false["rows_loaded"])
    success['msg'] = 'success'
    loaded_greater_readed['msg'] = 'Post DQ checks, rows loaded is more than rows read.'
    
    # total_rows = non_valid_rejected+mandatory_rejected+duplicates_rejected+dq_rejected+rows_loaded
    total_rows = true['non_valid_rejected'] + true['mandatory_rejected'] + true['duplicates_rejected'] + true['dq_rejected'] + true['rows_loaded']
    next_step, not_all = checker(true, true["total_rows"] == total_rows)
    next_step['msg'] = 'DQ failed for checks: '
    not_all['msg'] = 'Post DQ checks not all therows are loaded. '

    # mandatory_rejected > 0
    mandatory_rejected, next_step = checker(next_step, next_step["mandatory_rejected"]>0)
    mandatory_rejected['msg'] = mandatory_rejected['msg'] + 'mandatory; '
    next_step = pd.concat([next_step,mandatory_rejected])

    # non_valid_rejected >  0
    non_valid_rejected, next_step = checker(next_step,next_step["non_valid_rejected"]>0)
    non_valid_rejected['msg'] = non_valid_rejected['msg'] + 'non-valid; '
    next_step = pd.concat([next_step,non_valid_rejected])

    # duplicates_rejected > 0
    duplicates_rejected, next_step = checker(next_step,next_step["duplicates_rejected"]>0)
    duplicates_rejected['msg'] = duplicates_rejected['msg'] + 'duplicate; '
    next_step = pd.concat([next_step,duplicates_rejected])

    # dq_rejected > 0
    dq_rejected, next_step = checker(next_step,next_step["dq_rejected"]>0)
    dq_rejected['msg'] = dq_rejected['msg'] + 'dq rule; '
    next_step = pd.concat([next_step,dq_rejected])

    # prepare df to show
    next_step = pd.concat([next_step,not_all,loaded_greater_readed,success])
    next_step.sort_values(by = ['load_id'], inplace=True)
    next_step = next_step[['load_id','datasource','table_name','partition_date','msg']]
    
    # Show
    print(tableize(next_step))


def lambda_handler(event, context):

    print("--START--\n")
    try:
        main(int(event['partition_date']))
    except Exception as e:
        logger.error("Monitoring Log Failed : {}".format(e))
    finally:
        print("--END--\n")
    
    # # TODO implement
    # return {
    #     'statusCode': 200,
    #     'body': json.dumps('Hello from Lambda!')
    # }
