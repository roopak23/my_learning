init:
	terraform  init -upgrade  -backend-config=config/${ENV}/backend.tfvars 
validate:
	terraform validate 
plan:
	terraform plan -var-file="./globals_$(ENV).tfvars"

apply:
	terraform apply -auto-approve -var-file="./globals_$(ENV).tfvars"

destroy: 
	terraform destroy -auto-approve -var-file="./globals_$(ENV).tfvars"