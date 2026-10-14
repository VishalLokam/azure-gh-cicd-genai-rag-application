# azure-gh-cicd-genai-rag-application

## [WIP]Architecture Diagram

![Architecture Diagram](/architecture_diagram.png)

## Terraform bootstrap and CI/CD

The repository has two independent Terraform roots:

- `bootstrap/` creates the GitHub Actions OIDC application and service principal, the `Platform Administrators` Entra security group, Terraform remote-state storage, role assignments, and repository secrets needed by CI.
- `infrastructure/` provisions the application resources. GitHub Actions plans and applies this root using OIDC authentication.

Bootstrap uses local state in `bootstrap/terraform.tfstate`. The storage it creates is used by `infrastructure/`, whose backend state key is `terraform.tfstate`; bootstrap does not migrate its own state to that backend.

### Bootstrap prerequisites

Install Terraform **1.10 or newer**, Azure CLI, and Make with a POSIX-compatible shell (for example, Git Bash on Windows). Sign in with `az login` to the tenant containing your subscription. The Azure identity must be able to create Entra applications, service principals, and security groups; create the resource group and storage resources; and assign roles at subscription scope.

Create `bootstrap/terraform.tfvars` with all the non-secret bootstrap inputs below, replacing the example values. The file is ignored by Git. Set `github_owner` to the username that owns the personal repository; both the GitHub provider and the OIDC subject use this value.

```hcl
subscription_id                = "00000000-0000-0000-0000-000000000000"
github_owner                   = "your-github-username"
repository_name                = "azure-gh-cicd-genai-rag-application"
application_display_name       = "github-actions-oidc"
github_issuer                  = "https://token.actions.githubusercontent.com"
default_audience_name          = "api://AzureADTokenExchange"
resource_group_name            = "rg-terraform-bootstrap"
location                       = "southindia"
backend_storage_account_name   = "youruniquetfstateaccount"
backend_storage_container_name = "tfstate"
```

The storage account name must be globally unique and contain 3–24 lowercase letters or numbers.

Store the GitHub personal access token in the ignored root `.env` file instead of `terraform.tfvars`:

```dotenv
TF_VAR_github_token=your_github_personal_access_token
```

Terraform automatically reads environment variables prefixed with `TF_VAR_`. The Makefile sources and exports `.env` before it invokes Terraform and stops if sourcing fails. For direct Terraform plan/apply/destroy commands, export `TF_VAR_github_token` yourself or source `.env` with `set -a; . ./.env; set +a` from the repository root.

The token must belong to `github_owner` and be valid and authorized for this personal repository. Use a classic token with the `repo` scope, or a fine-grained token with access to this repository and repository **Secrets: Read and write** permission.

`github_token` is marked both `sensitive` (redacted from normal Terraform output) and `ephemeral` (omitted from Terraform plan and state files). Keep it in the environment, not in Terraform source or variable files. Local state and backups can still contain Azure Storage access keys, so keep state, saved plans, `.env` files, and credentials out of Git and shared logs. The ignore rules cover these generated files; they do not remove files already tracked or erase Git history.

### Bootstrap commands

```sh
make bootstrap
make bootstrap-destroy
```

Run these commands from the repository root. `make bootstrap` initializes Terraform, displays a speculative plan, then runs `terraform apply -auto-approve`, which generates a fresh plan and applies it without confirmation. It does not save or apply a `bootstrap.tfplan` file. `make bootstrap-destroy` initializes Terraform and destroys the bootstrap-managed resources without confirmation, including the remote-state storage and GitHub secrets. Destroy application infrastructure before removing its backend storage.

### GitHub Actions configuration

Bootstrap sets these six repository secrets, matching the workflow references:

- `AZURE_CLIENT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_TENANT_ID`
- `BACKEND_RESOURCE_GROUP_NAME`
- `BACKEND_STORAGE_ACCOUNT_NAME`
- `BACKEND_STORAGE_ACCOUNT_CONTAINER_NAME`

The service principal receives subscription-wide **Contributor**, **User Access Administrator**, and **Key Vault Secrets Officer** roles, plus **Storage Blob Data Contributor** on the state container.

The federated credential trusts only `repo:<github_owner>/<repository_name>:ref:refs/heads/main`. Pushes to `main` and manual runs on `main` without a GitHub environment match that subject. Pull-request jobs use a different OIDC subject and cannot authenticate with this bootstrap credential.

### Infrastructure checks

```sh
terraform -chdir=bootstrap fmt -check
terraform -chdir=bootstrap init -backend=false
terraform -chdir=bootstrap validate
terraform -chdir=infrastructure fmt -check
```

The infrastructure CI workflow initializes the Azure Storage backend, validates the configuration, then plans with `environment/dev.tfvars.json` and overrides `subscription_id` using `AZURE_SUBSCRIPTION_ID`. It is configured to apply the saved plan on pushes and pull requests targeting `main`, and on manual runs. Pull-request runs are currently blocked by the OIDC subject mismatch described above.

The manual infrastructure destroy workflow also references `environment/platform.json`, which is not tracked. That step needs repair before the workflow can be relied on.

## [WIP]CICD Setup

![CICD Setup](/cicd_diagram.png)
