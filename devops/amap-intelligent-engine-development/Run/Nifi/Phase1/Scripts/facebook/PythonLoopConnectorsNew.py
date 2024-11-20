#!/usr/local/bin/python3.8
import requests
import pandas as pd
import time
import json
import os

print('>>>>>>>>>>>>>>')
print(os.getcwd())
print('>>>>>>>>>>>>>>')
#os.chdir(r'C:\Users\ahbab.ahmed\OneDrive - Accenture\Desktop\PP')
os.chdir(r'/opt/nifi/nifi-current/development/facebook/')

file = open('facebook.json')
data = json.load(file)

file = open('facebook.json')
data = json.load(file)

Adserver_ids = [d['FB_Adserver_Id'] for d in data]
Account_ids = [d['FB_Account_Id'] for d in data]
Acces_tokens = [d['FB_Access_Token'] for d in data]


##### Campaign Line Detail ###
df_master = pd.DataFrame()
df_ids = pd.DataFrame()
for account_id, access_token, adserver_id in zip(Account_ids, Acces_tokens, Adserver_ids):
    FB_Access_Token= access_token
    FB_Account_Id= account_id
    FB_Adserver_Id= adserver_id

    print("======= getting data for CAMPAIGN_LINE_DETAIL account_id " + account_id + " adserver_id " + adserver_id + " ======= ")
    
#    url = "https://graph.facebook.com/v12.0/act_{}/adsets?access_token={}&fields=account_id,campaign_id,adset_id,targeting,id,name,bid_amount,lifetime_budget,status,bid_strategy,ads,end_time&date_preset=maximum".format(FB_Account_Id, FB_Access_Token)
    url = "https://graph.facebook.com/v12.0/act_{}/adsets?access_token={}&fields=account_id,campaign_id,adset_id,date_stop,targeting{{effective_publisher_platforms,effective_facebook_positions,effective_device_platforms,effective_audience_network_positions,effective_instagram_positions}},id,name,bid_amount,lifetime_budget,status,bid_strategy,ads,end_time&date_preset=maximum".format(FB_Account_Id, FB_Access_Token)

    
    response = requests.get(url)
    data = response.json()
    list_data = data.get("data")

    account_ids = []
    campaign_ids = []
    adset_ids = []
    targeting_ids = []
    adnames = []
    statuses = []
    ad_ids = []
    end_times = []
    adserver_ids = []
#    age_max, age_min = [], []
    audience_ids, audience_names= [], []
    publisher_platforms, device_platforms, facebook_positions, audience_network_positions, instagram_positions  = [], [], [], [], []



    for data in list_data:
        account_ids.append(data['account_id'])
        campaign_ids.append(data['campaign_id'])
        adset_ids.append(data['id'])
        adnames.append(data['name'])
        statuses.append(data['status'])

        try:
            ad_ids.append([data['ads']['data'][i]['id'] for i in range(len(data['ads']['data']))])
        except:
            ad_ids.append([])
        end_times.append(data['end_time'])
#        age_max.append(data['targeting']['age_max'])
#        age_min.append(data['targeting']['age_min'])

        audience_id = 'Not Available'
        audience_name = 'Not Available'
        position = 'Not Available'
        try:
            audience_id = data['targeting']['custom_audiences'][0]['id']
            audience_name = data['targeting']['custom_audiences'][0]['name']
            audience_ids.append(audience_id)
            audience_names.append(audience_name)
        except:
            audience_ids.append(audience_id)
            audience_names.append(audience_name)
            pass


        publisher_platforms.append(data['targeting']['effective_publisher_platforms'])
        device_platforms.append(data['targeting']['effective_device_platforms'])
        instagram_positions.append(data['targeting']['effective_instagram_positions'])
        facebook_positions.append(data['targeting']['effective_facebook_positions'])
        adserver_ids.append(adserver_id)
#        audience_network_positions.append(data['targeting']['effective_audience_network_positions'])

            #    targeting_ids.append(data['targeting'])

    master_list = [account_ids, campaign_ids, adset_ids ,publisher_platforms,facebook_positions, instagram_positions, device_platforms, audience_ids , audience_names, statuses, adserver_ids, ad_ids]
    df = pd.DataFrame(pd.DataFrame(master_list).T)
    df.columns = ['account_id', 'campaign_id', 'campaign_line_id' , 'publisher','facebook_positions','instagram_positions', 'device','adserver_target_remote_id','adserver_target_name','campaign_status','adserver_id', 'adset_id']
    
    df['budget'] = None
    df['bid_strategy'] = None
    
    df = df[['account_id', 'campaign_id', 'campaign_line_id' , 'publisher','facebook_positions','instagram_positions', 'device', 'adserver_id', 'adserver_target_remote_id' ,'adserver_target_name' , 'campaign_status', 'budget','campaign_status', 'bid_strategy', 'adset_id']]
    df_master = pd.concat([df_master,df], axis=0)
    
    
    
    time.sleep(20)
    
df_ids = df_master[['account_id', 'campaign_id', 'campaign_line_id', 'adset_id']]
df_master.drop('adset_id', inplace=True, axis = 1)
df_master.to_csv('CAMPAIGN_LINE_DETAIL.csv', index=False)
####   CAMPAIGN_LINE_DETAIL_PERFORMANCE   ####


df_adset = pd.DataFrame()
for account_id, campaign_id, adset_id, adserver_id in zip(df_master['account_id'],df_master['campaign_id'],df_master['campaign_line_id'], df_master['adserver_id']):
    url = "https://graph.facebook.com/v12.0/{}/insights?access_token={}&fields=adset_id,cpm,impressions,date_start,date_stop".format(adset_id, FB_Access_Token)
    time.sleep(2)
    response = requests.get(url)
    data = response.json()

    df_temp = pd.DataFrame(columns = ['adset_id','cpm','impressions','date_start','date_stop'])
    if len(data['data']) < 1:
        df_temp.loc[0] = [None, None, None, None, None]
    else:
        df_temp = pd.DataFrame(data.get("data"))
    df_temp['account_id'] = account_id
    df_temp['campaign_id'] = campaign_id
    df_temp['adserver_id'] = adserver_id
    df_temp['metric'] = 'impression'
    
    df_adset = pd.concat([df_adset, df_temp], axis=0)
    df_adset = df_adset[['account_id', 'campaign_id', 'adset_id','cpm','impressions','date_start','date_stop', 'adserver_id', 'metric']]
    print("======= getting data for CAMPAIGN_LINE_DETAIL_PERFORMANCE account_id " + account_id + ", campaign_id " + campaign_id + ", adserver_id " + adserver_id + " ======= ")
df_adset.rename(columns = {'date_stop': 'until'}, inplace = True)
df_adset = df_adset[['account_id', 'campaign_id', 'adset_id', 'date_start', 'until', 'adserver_id', 'impressions', 'cpm', 'metric']]
df_adset['duration'] = pd.to_datetime(df_adset['until']) - pd.to_datetime(df_adset['date_start'])

df_adset.to_csv('CAMPAIGN_LINE_DETAIL_PERFORMANCE.csv', index=False)


####  CREATIVE_PERFORMANCE

quality_ranking = []

df_creative = pd.DataFrame(columns = ['adset_id', 'account_id', 'ad_id', 'quality_ranking','conversion_rate_ranking', 'date_start', 'date_stop', 'campaign_id'])
for account_id, campaign_id, ad_id in zip(df_master['account_id'],df_master['campaign_id'],df_ids['adset_id']):
    for a in ad_id:
        url ='''https://graph.facebook.com/v12.0/{}/insights?access_token={}&fields=adset_id,account_id,ad_id,quality_ranking,conversion_rate_ranking'''.format(a, FB_Access_Token)
        time.sleep(2)
        response = requests.get(url)
        data = response.json()
        list_data = data.get("data")
        
        df_temp = pd.DataFrame(list_data)
        df_temp['campaign_id'] = campaign_id
        
        df_creative = pd.concat([df_creative, df_temp], axis=0)
        print("======= getting data for CREATIVE_PERFORMANCE ad_id  " + a +  " ======= ")
df_creative.drop(['date_start', 'date_stop', 'campaign_id'], axis=1, inplace=True)
df_creative.to_csv("CREATIVE_PERFORMANCE_.csv", index=False)