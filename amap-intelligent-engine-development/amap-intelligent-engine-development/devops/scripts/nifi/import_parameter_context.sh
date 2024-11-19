#!/bin/bash

PARAM_ID=""

kubectl cp -n dm parameter_context.json nifi-dm-0:/opt/nifi/nifi-current -c server

kubectl exec -i -n dm nifi-dm-0 -c server -- /opt/nifi/nifi-toolkit-current/bin/cli.sh nifi import-param-context -p /opt/nifi/nifi-toolkit-current/bin/cli.properties -i /opt/nifi/nifi-current/parameter_context.json -pcn AMAP_NifiConnectors_Params

