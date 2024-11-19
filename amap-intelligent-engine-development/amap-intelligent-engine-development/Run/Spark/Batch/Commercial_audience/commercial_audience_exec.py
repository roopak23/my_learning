# -*- coding: utf-8 -*-
"""
Created on Thu Nov  2 11:17:06 2023

@author: dipan.arya
"""

import traceback
from sys import argv
import sys

def main(url: str, source_bucket: str, client_id: str, client_secret: str, client_name: str, version: str) -> None:
    import os
    # Function to check if a package is installed
    def check_and_install_package(package_name):
        try:
            import importlib
            importlib.import_module(package_name)
            print(f"{package_name} is already installed.")
        except ImportError:
            print(f"{package_name} is not installed. Installing...")
            os.system(f"pip3 install {package_name}")
    check_and_install_package("requests")
    check_and_install_package("csv")
    check_and_install_package("json")
    import requests
    import csv
    import json
    import pandas as pd
    import re
    # Define your source and target S3 bucket names
    crm_analytics_bucket = source_bucket + "/data/outbound/crm_analytics/IE_Commercial_Audience"
    source_bucket = source_bucket + "/data/inbound/import/IE_commercial_audience"
    control_file_bucket = source_bucket+"/control_file"
    control_file_key = "audience_controller.csv"
    target_jsonfile_bucket = source_bucket+"/jsonfile"
    #IL Configuration Details
    url = url
    client_id = client_id
    client_secret = client_secret
    version= version
    client_name= client_name
    json_file_path = 'output.json'  # Replace with the actual path to your JSON file
    headers = {"Content_Type": "application/json", "client_id": client_id, "client_secret": client_secret,
            "version": version, "client_name": client_name}
    json_structure = {"Commercial_Audience": []}
    # List files in the source S3 bucket
    source_bucket_files = os.popen(f"aws s3 ls s3://{source_bucket}/").read().split()
    # source_bucket_files.remove('extr_amap_audience_sizing_20240418.csv')
    # Read the list of processed file names from the control file in the target bucket
    control_file_path = f"{control_file_key}"
    if not os.path.exists(control_file_path):
        os.system(f"touch {control_file_path}")
    processed_files = set()
    with open(control_file_path, "r") as control_file:
        for line in control_file:
            processed_files.add(line.strip())
    # Process files
    errorstatus="N"
    for _csv_file_name_ in [sorted([line.split()[-1] for line in source_bucket_files if '.csv' in line])[-1]]:
        if '.csv' in _csv_file_name_:
            print(f"filename ::: {_csv_file_name_}")
            if _csv_file_name_ in processed_files:
                print(f"Input file is already processed: {_csv_file_name_}")
            else:
                audiencefile_download_command = f"aws s3 cp s3://{source_bucket}/{_csv_file_name_} {_csv_file_name_}"
                crm_analytics_remove_file_command = f"aws s3 rm s3://{crm_analytics_bucket} --recursive --exclude '*' --include 'extr_amap_audience_sizing_*.csv'"
                crm_analytics_copy_file_command = f"aws s3 cp s3://{source_bucket}/{_csv_file_name_} s3://{crm_analytics_bucket}/{_csv_file_name_}"
                os.system(audiencefile_download_command)
                os.system(crm_analytics_remove_file_command)
                os.system(crm_analytics_copy_file_command)
                print(f"Processing file: {_csv_file_name_}")
                entire_df = pd.read_csv(_csv_file_name_, dtype=str)  # Read all columns as strings
                entire_df.loc[entire_df['market_targeting_type'] == 'Age', 'market_targeting_type'] = 'KeyValue'
                entire_df.loc[entire_df['market_targeting_type'] == 'Gender', 'market_targeting_type'] = 'KeyValue' 
                entire_df.loc[entire_df['technical_targeting_type'] == 'Age', 'technical_targeting_type'] = 'KeyValue'
                entire_df.loc[entire_df['technical_targeting_type'] == 'Gender', 'technical_targeting_type'] = 'KeyValue'
                entire_df['market_targeting_type'] = entire_df['market_targeting_type'].str.replace("Audience Segment", "AudienceSegment")
                entire_df['technical_targeting_type'] = entire_df['technical_targeting_type'].str.replace("Audience Segment", "AudienceSegment")                
                iteration_no = 0
                _json_folder_name_ = _csv_file_name_.replace('.csv', '')
                os.system(f'mkdir {_json_folder_name_}')
                num_of_audience = entire_df['commercial_audience_name'].nunique()
                for commercial_audience_name in entire_df['commercial_audience_name'].unique():
                    cleaned_name = re.sub(r'[^\w]', '_', commercial_audience_name)
                    cleaned_name = re.sub(r'_+', '_', cleaned_name)
                    cleaned_name = cleaned_name.strip('_')
                    print(f"iteration No. ::: {iteration_no}")
                    print(f"pushing comeerical data for audience ::: {commercial_audience_name}")
                    df = entire_df[entire_df['commercial_audience_name'] == commercial_audience_name]
                    commercial_audience_internal = {
						"Name": commercial_audience_name,
						"External_Id": commercial_audience_name,
						"Market_Targeting": []
					}
					# Iterate through the rows of the filtered DataFrame
                    for index, row in df.iterrows():
                        market_targeting = {
							"Name": row["market_targeting_name"],
							"Type": row["market_targeting_type"],
							"Market_Targeting_Remote_Id": row["market_targeting_name"],  # Assuming this is same as market_targeting_name
							"Market_Targeting_Technical_Remote_Id": row["technical_remote_id"],  # Assuming this is same as technical_remote_id
							"Technical_Targeting": [
								{
									"Technical_Remote_Id": row["technical_remote_id"],
									"Technical_Remote_Name": row["technical_remote_name"],
									"Type": row["technical_targeting_type"],
									"Size": row["audience_size"],  # Assuming this is audience_size
									"Ad_Server_Id": "GAM"
								}
							]
						}# Append the market_targeting to the Market_Targeting list
                        commercial_audience_internal["Market_Targeting"].append(market_targeting)                
                    # Create a JSON file for each audience
                    json_structure = {"Commercial_Audience": [commercial_audience_internal]}
                    json_string = json.dumps(json_structure, indent=4)
                    json__csv_file_name_ = _csv_file_name_.replace('.csv', f'_{cleaned_name}_{iteration_no}.json')
                    iteration_no=iteration_no + 1
                    with open(json__csv_file_name_, 'w') as json_file:
                        json_file.write(json_string)
                    print(f"JSON file for {commercial_audience_name} has been created.")   
                    # Push the JSON data
                    with open(json__csv_file_name_, "r") as json_file:
                        data = json.load(json_file)
                    try:
                        response = requests.post(url, headers=headers, json=data)
                        if response.status_code == 200:
                            print("Audience data pushed successfully.")
                            print(response.text)
                            os.system(f'mv {json__csv_file_name_} {_json_folder_name_}/')
                            if num_of_audience == iteration_no and errorstatus == 'N':
                                with open(control_file_key, "a") as control_file:
                                    control_file.write(_csv_file_name_ + "\n")
                                print("Control File is updated with processed file details.")
                                control_file_upload_command = f"aws s3 cp {control_file_key} s3://{control_file_bucket}/{control_file_key}"
                                os.system(control_file_upload_command)
                                # os.rmdir(_json_folder_name_)
                                json_file_upload_command = f"aws s3 sync {_json_folder_name_} s3://{target_jsonfile_bucket}/{_json_folder_name_}"
                                os.system(json_file_upload_command)
                            #os.remove(json__csv_file_name_)  # Remove the JSON file
                        else:
                            errorstatus = 'Y'
                            error_message = "Error: Audience pushed data request failed with status code: " + str(response.status_code)
                            print(error_message)
                            print(f"fail to push json data for audience name ::: {commercial_audience_name} in file {_csv_file_name_}.")
                            print(response.text)
                            raise ValueError(error_message)
                    except Exception as e:
                        print("An error occurred:", str(e))
            os.remove(_csv_file_name_)  # Remove the CSV file
    os.remove(control_file_key)  # Remove the control file

__name__ = "__main__"
if __name__ == "__main__":
    url = sys.argv[1]
    source_bucket = sys.argv[2]
    client_id = sys.argv[3]
    client_secret = sys.argv[4]
    client_name = sys.argv[5]
    version = sys.argv[6]
    try:
        main(url, source_bucket, client_id, client_secret, client_name, version)
    except Exception as e:
        print(e)
        traceback.print_tb(e.__traceback__)