#!/usr/local/bin/python3.8

# Import appropriate modules from the client library.
from googleads import ad_manager
from googleads import errors
from datetime import datetime, timedelta
import pytz

# Change date HERE!!
now = datetime.now(tz=pytz.timezone('GMT'))
past = now - timedelta(days=180)

# Support function
def get_date(date_object, field):
    try:
        date = "{}-{}-{}".format(date_object[field]['date']['year'],
                date_object[field]['date']['month'], 
                date_object[field]['date']['day']
            )
    except:
        date = None
    finally:
        return date

def get_list(list_object, field):
    out_list = [i[field] for i in list_object]

    return out_list

def json_2_string(json_object, field):
    try:
        if 'notes' not in field:
            string = "{}".format(json_object[field]).replace("\n","").replace(" ", "")
        else:
            string = "{}".format(json_object[field]).replace("\n","").replace("\r","").replace(";","").strip()
    except:
        string = None
    finally:
        return string



def main_segments(client):
    # Initialize appropriate service.
    audience_segment_service = client.GetService('AudienceSegmentService', version='v202111')
    localfile_path = '/opt/nifi/nifi-current/development/google_json/segments_output.csv'
  
    # Create a statement to select orders.
    statement = (ad_manager.StatementBuilder(version='v202111')
                    .Where('status = :status')
                    .WithBindVariable('status', 'active')
                     
                )
  
    # Retrieve a small amount of line items at a time, paging
    # through until all line items have been retrieved.
    with open(localfile_path, 'w', encoding="utf-8") as fp:
        header = "adserver_id;adserver_target_remote_id;adserver_target_name;adserver_target_type;status;dataprovider;segment_type'\n"
        fp.write(header)
        while True:
            response = audience_segment_service.getAudienceSegmentsByStatement(statement.ToStatement())
            if 'results' in response and len(response['results']):
                for audience_segment in response['results']:
                     # Define the info to save in file
                    line = ';'.join(map(str,[
                                    "GAM",
                                    audience_segment['id'],
                                    audience_segment['name'],
                                    "AUDIENCE",
                                    audience_segment['status'],
                                    audience_segment['dataProvider']['name'],
                                    audience_segment['type']
                                    
                        ])) + '\n'

                    fp.write(line)
                statement.offset += statement.limit
                print("Cycling..")

            else:
                break

    print(response)
    print('\nNumber of results found: %s' % response['totalResultSetSize'])

if __name__ == '__main__':
    # Initialize client object.
    print("Connecting...")
    ad_manager_client = ad_manager.AdManagerClient.LoadFromStorage("/opt/nifi/nifi-current/development/google_json/googleads.yaml")

    # Download the data
    main_segments(ad_manager_client)


# EOF