export DASHBOARD_TOKEN=$(kubectl -n kube-system get secret $(kubectl -n kube-system get sa/dashboard-account -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}")
 
echo $DASHBOARD_TOKEN

