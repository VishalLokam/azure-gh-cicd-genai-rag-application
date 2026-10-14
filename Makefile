.PHONY: bootstrap bootstrap-destroy


bootstrap:
	@set -eu; set -a; . ./.env; set +a; cd ./bootstrap && terraform init && terraform plan && terraform apply -auto-approve


bootstrap-destroy:
	@set -eu; set -a; . ./.env; set +a; cd ./bootstrap && terraform init && terraform destroy -auto-approve


