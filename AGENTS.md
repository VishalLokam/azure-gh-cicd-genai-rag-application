# Repository guide

## Layout

- `bootstrap/` is a separate Terraform root that creates the Azure AD GitHub OIDC application, remote-state storage, and GitHub Actions secrets. It requires bootstrap-specific variables (including a sensitive `github_token`); its state is not the `infrastructure/` state.
- `infrastructure/` is the application platform Terraform root: resource group, Key Vault, PostgreSQL, and Azure OpenAI deployments. Its `azurerm` backend uses OIDC and the fixed state key `terraform.tfstate`.
- `environment/dev.tfvars.json` is the tracked input for infrastructure plans. CI additionally passes `subscription_id` from `AZURE_SUBSCRIPTION_ID` rather than relying on the value in that file.
- `mcp_server/mcp_server.py` is the only application entrypoint. It starts a local HTTP FastMCP server on `127.0.0.1:8080` and exposes Tavily-backed `web_search`.

## Commands and verification

- Format-check Terraform from each root: `terraform -chdir=bootstrap fmt -check` and `terraform -chdir=infrastructure fmt -check`.
- The CI-equivalent infrastructure plan sequence is: initialize `infrastructure/` with the three backend settings (`resource_group_name`, `storage_account_name`, `container_name`), run `terraform validate`, then run `terraform plan -var-file=../environment/dev.tfvars.json -var="subscription_id=$AZURE_SUBSCRIPTION_ID" -out=main.tfplan`.
- `make bootstrap` and `make bootstrap-destroy` source the ignored root `.env`. Put the bootstrap GitHub credential there as `TF_VAR_github_token`; Terraform automatically maps that environment variable to `github_token`.
- `make bootstrap` is not a dry run: after a speculative plan it runs `terraform apply -auto-approve`, which creates a fresh plan and applies it. It does not save `bootstrap.tfplan`. `make bootstrap-destroy` destroys that root. Do not run either as routine verification.
- For the MCP service, from `mcp_server/`: `uv sync`, then set `TAVILY_API_KEY` in the root `.env` and run `uv run python mcp_server.py`. No Python test, lint, or typecheck configuration is currently tracked.

## Operational constraints

- Preserve the split Terraform roots and initialize each from its own directory; provider and backend configuration are intentionally different.
- Azure OpenAI is deliberately hard-coded to `southindia` in `infrastructure/openai.tf`; the resource group, PostgreSQL, and Key Vault use `var.location`. Do not assume changing `location` moves every resource.
- CI plans and then applies infrastructure on both `main` pushes and pull requests. The apply job consumes the uploaded `main.tfplan`; changes to this flow can affect real Azure resources.
- The manual destroy workflow currently reads `environment/platform.json`, but that file is not tracked. Repair or remove that step before relying on the workflow.
- Keep generated local Terraform directories, state, plans, `.env`, and virtual environments out of commits; they are ignored. Do not add credentials or backend secrets to Terraform variable files.
