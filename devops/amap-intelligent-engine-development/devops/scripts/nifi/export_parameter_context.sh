#!/bin/bash

PARAM_ID=""

kubectl exec -it -n dm nifi-dm-0 -c server -- /opt/nifi/nifi-toolkit-current/bin/cli.sh nifi list-param-contexts -p /opt/nifi/nifi-toolkit-current/bin/cli.properties > param.temp

PARAM_ID=$(cat param.temp | grep 1 | cut -d' ' -f4)

kubectl exec -it -n dm nifi-dm-0 -c server -- /opt/nifi/nifi-toolkit-current/bin/cli.sh nifi export-param-context -o /opt/nifi/nifi-toolkit-current/bin/parameter_context.json -pcid $PARAM_ID -p /opt/nifi/nifi-toolkit-current/bin/cli.properties


kubectl cp -n dm -c server nifi-dm-0:/opt/nifi/nifi-toolkit-current/bin/parameter_context.json parameter_context.json
