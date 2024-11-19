# Nifi CLI
The NiFi CLI is used to import / export context parameters and templates between environments. 

When running a file, indicate the properties file:
```
./cli.sh -p /path/to/file.properties
```

Or set the default properties file:
```
./cli.sh session set nifi.props /path/to/file.properties
```

All commands would hten use the same properties file. 

### How to get details for the properties file:
The nifi.properties file would include the credentials needed to be able to make CLI calls. The values needed are:
- truststore
- truststorePasswd
- keystorePasswd
- keystore
- keystorePasswd
- proxiedEntity

Get the Passwd from the nifi pod
```
kubectl exec -it -n dm nifi-dm-0 -c server -- cat /opt/nifi/nifi-current/conf/nifi.properties | grep Passwd

## Should return:
nifi.security.keystorePasswd=6y8sK4xI6Tj4WIc8crzZQgUIpJ4bQ2RIIHcDX/Hz1vM
nifi.security.keyPasswd=6y8sK4xI6Tj4WIc8crzZQgUIpJ4bQ2RIIHcDX/Hz1vM
nifi.security.truststorePasswd=1dh5dWuc53WVQ3zcpi3LV3ZnMjHVwJFHfDGsnBBvHv0
```

Modify the cli.properties file with the proper details listed in nifi.properties and copy to the kube node
```
kubectl cp -n dm cli.properties nifi-dm-0:/opt/nifi/nifi-toolkit-current/bin -c server
```

List the param-context or get the param context id:
```
## if properties file is not copied over to the cluster, use the following command:
./cli.sh nifi list-param-contexts -u https://nifi-dm-0.nifi-dm-headless.dm.svc.cluster.local:8443 \
--truststore /opt/nifi/nifi-current/config-data/certs/truststore.jks \
--truststoreType JKS \
--truststorePasswd bVIbVdydI/6BatVG2HttxSQ7iGKtOrZE5yywRu+GSS \
--keystore /opt/nifi/nifi-current/config-data/certs/keystore.jks \
--keystoreType JKS \
--keystorePasswd G0Y0LjrW2rscj26qc0vy5LpmwPesWpVu4QZFYYiTb9U \
--proxiedEntity nifiuser

## if cli.properties is copied over to the node:
kubectl exec -it -n dm nifi-dm-0 -c server -- /opt/nifi/nifi-toolkit-current/bin/cli.sh nifi list-param-contexts -p /opt/nifi/nifi-toolkit-current/bin/cli.properties
```


keystorePasswd=G0Y0LjrW2rscj26qc0vy5LpmwPesWpVu4QZFYYiTb9U
keyPasswd=G0Y0LjrW2rscj26qc0vy5LpmwPesWpVu4QZFYYiTb9U
truststore=/opt/nifi/nifi-current/config-data/certs/truststore.jks
truststoreType=JKS
truststorePasswd=bVIbVdydI/6BatVG2HttxSQ7iGKtOrZE5yywRu+GSS
proxiedEntity=nifiuser

Should return the param context id that you should export:
```
#   Id                                     Name                         Description
-   ------------------------------------   --------------------------   -----------
1   81e00614-017b-1000-bb1d-5d78681c5f91   AMAP_NifiConnectors_Params
```

### Export the context params
```
kubectl exec -it -n dm nifi-dm-0 -c server -- /opt/nifi/nifi-toolkit-current/bin/cli.sh nifi export-param-context -o /opt/nifi/nifi-toolkit-current/bin/parameter_context.json -pcid 81e00614-017b-1000-bb1d-5d78681c5f91 -p /opt/nifi/nifi-toolkit-current/bin/cli.properties
```

Context param file is now saved as `parameter_context.json` ready to be copied over to local drive:
```
## Copy exported json file to local
kubectl cp -n dm -c server nifi-dm-0:/opt/nifi/nifi-toolkit-current/bin/parameter_context.json parameter_context.json
```

### Export the templates
Can be done through CLI and UI

UI Method
1. Log in to the nifi ui
2. go to menu button top right
3. click on templates
4. export the template needed
5. save the xml file somewhere


### Importing the context param in a new environment
1. Modify the values in cli.properties with the right values
2. Copy the following files to the pod:
    - cli.properties
    - nifi_template.xml (exported template file)
    - parameter_context.json
3. import 
4. check UI if context params are present

Importing the parameter context:
```
## copying the files to the pod:
kubectl cp -n dm cli.properties nifi-dm-0:/opt/nifi/nifi-current -c server
kubectl cp -n dm parameter_context.json nifi-dm-0:/opt/nifi/nifi-current -c server
kubectl cp -n dm nifi_template.xml nifi-dm-0:/opt/nifi/nifi-current -c server

## Import the param context
kubectl exec -it -n dm nifi-dm-0 -c server -- /opt/nifi/nifi-toolkit-current/bin/cli.sh nifi import-param-context -p /opt/nifi/nifi-toolkit-current/bin/cli.properties -i parameter_context.json -pcn AMAP_NifiConnectors_Params

## Get the processGroupId for uploading the template


## Upload the template
## process group ID can be taken from the dev or the test instance in NiFi UI.
kubectl exec -it -n dm nifi-dm-0 -c server -- /opt/nifi/nifi-toolkit-current/bin/cli.sh nifi upload-template -p cli.properties -i nifi_template.xml --processGroupId [processGroupId]
```

Uploading the template
```
## process group id should be changed to target processGroupId
./cli.sh nifi upload-template -p cli.properties -i nifi_template_09122021.xml --processGroupId a3c0cf90-b77c-4bd7-a4eb-2215e50177d7
```
