.PHONY: bootstrap


bootstrap:
	cd ./bootstrap && terraform init && terraform plan -out="bootstrap.tfplan"
	cd ./bootstrap && terraform apply -auto-approve "bootstrap.tfplan" 


bootstrap-destroy:
	cd ./bootstrap && terraform init && terraform destroy -auto-approve


