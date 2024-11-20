INSERT INTO monitoring.usecases_downstream
(usecase_name, downstream_system, dmoutputtable_list, downstreamtable_list, description)
VALUES('Campaign_Monitoring', 'SA', 'trf_campaign,trf_fact_input,trf_monitoring_insights,to_recommendation,tl_recommendation', 'TO_Recommendation__c,TL_Recommendation__c,Campaign_Monitoring__c', 'Campaign_Monitoring'),
('Suggested_For_you', 'SA', 'Buying_Profile_Media_KPI,Buying_Profile_Total_KPI', 'Suggested_Proposal__c,Suggested_Product__c', 'Suggested_For_You')
