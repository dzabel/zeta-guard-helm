# How to configure ZETA Guard Authserver

## Overview

This guide describes how to configure the ZETA Guard Authserver (PDP) using Terraform
and the provided Makefile. The Makefile supports robust CI/CD execution and optional
admin password handling to streamline deployments and updates.

This step can be performed multiple times to configure and reconfigure the authserver
without the need to deploy it from scratch.

> Configuration is managed via Terraform and provides both customizable and predefined settings:
>
> Customizable properties:
> - Authserver URL
> - Kubernetes namespace
> - TLS configuration (self-signed certificates are supported)
> - Additional PDP scopes
>
> Predefined settings:
> - PDP scopes `zero:manage` and `zero:register` are automatically created
> - Realm token encryption is set to ES256
> - Trusted Hosts, Max Clients Limit, Consent Required Policies are removed
> - ZETA Max Clients Limit Policy added

> The name of the ZETA Guard realm is `zeta-guard` and must be kept unchanged.

---

## Operating Modes

Terraform can run in two modes, controlled by the `TF_VAR_use_kubernetes` variable:

| | **Kubernetes mode** (default) | **Local mode** |
|---|---|---|
| **State backend** | Kubernetes Secret in the cluster | Local `terraform.tfstate` file |
| **Credentials** | Read from K8s Secret `authserver-admin` | Must be provided explicitly |
| **Typical use** | CI/CD pipelines, cluster-connected admins | Local development, no cluster access required |
| **Set via** | `TF_VAR_use_kubernetes=true` (default) | `TF_VAR_use_kubernetes=false` |

---

## Prerequisites

### Common (both modes)

- Terraform installed (version compatible with the providers)
- Make installed
- `curl` and `jq` available in PATH
- Network access to the Keycloak instance from the machine running Terraform

### Kubernetes mode (default)

- A running ZETA Guard Kubernetes cluster
- `kubectl` configured to access the cluster
- Keycloak admin credentials stored in K8s Secret `authserver-admin` (created by the Helm chart)

### Local mode

- `TF_VAR_use_kubernetes=false` set in the Makefile invocation or as environment variable
- Keycloak admin credentials provided explicitly:
  - `TF_VAR_keycloak_password` (required)
  - `TF_VAR_keycloak_username` (defaults to `admin`)
- Terraform state is stored locally in `terraform.tfstate` (not in the cluster)

> When using self-signed certificates (e.g. local KIND cluster), set `insecure_tls = true`
> in the tfvars file. The management script will automatically extract the server certificate
> and configure a temporary Java truststore for `kcadm.sh`.

---

## Terraform Variables

Set environment-specific variables in `environments/STAGE.tfvars` (or `private/STAGE.tfvars` for local development). Key variables include:

```hcl
insecure_tls       = true                         # Set to true if using self-signed certificates
use_kubernetes     = true                         # Set to false for local mode (no K8s backend)
keycloak_url       = "https://.../auth"           # URL of the Keycloak instance
keycloak_namespace = "zeta-demo"                  # Kubernetes namespace where Keycloak runs
pdp_scopes         = ["zero:read", "zero:write"]  # Optional scope list
```

The following validations are enforced:
- `keycloak_namespace` must be a valid Kubernetes namespace name
- `keycloak_url` must start with `http://` or `https://`
- `pdp_scopes` entries may only contain alphanumeric characters, underscores, colons, or hyphens
- When `use_kubernetes = false`, both `keycloak_username` and `keycloak_password` must be set

---

## Applying Configuration

### Kubernetes mode (default)

```shell
# Set the Keycloak admin password (optional if stored in K8s Secret)
export TF_VAR_keycloak_password=your_password

# Configure the authserver
make config stage=demo
```

If the Keycloak admin password is stored in the K8s Secret `authserver-admin`, you can omit `TF_VAR_keycloak_password` entirely:

```shell
make config stage=demo
```

### Local mode

```shell
# Required: set credentials
export TF_VAR_keycloak_password=your_password

# Run without Kubernetes backend
make config stage=local TF_VAR_use_kubernetes=false
```

> If using the terminal the default path to the kubeconfig is `~/.kube/config`.
> Set `TF_VAR_config_path` if it differs.

### Dry-run (both modes)

In case you want a dry-run of the Terraform operations, use `config-plan` instead.
This will not change your settings but print the differences between the current state
and the desired state:

```shell
make config-plan stage=demo
```

---

## Makefile Details

The configuration targets perform the following steps:

1. **`generate-main-and-backend`** generates `main.tf` and the backend configuration
   file from templates, based on `TF_VAR_use_kubernetes`:
   - `true`: uses `backend "kubernetes"` with state stored in a K8s Secret
   - `false`: uses `backend "local"` with state stored on disk
2. **`config-init`** runs the generator and initializes the Terraform backend
3. **`config`** runs `config-init`, then applies the Terraform configuration
4. **`config-plan`** runs `config-init`, then plans without applying
5. **`config-import`** imports existing resources not yet managed by Terraform

Key Makefile variables:

| Variable | Default | Description |
|---|---|---|
| `TF_VAR_use_kubernetes` | `true` | Toggle Kubernetes vs. local mode |
| `TF_VAR_config_path` | `~/.kube/config` | Path to kubeconfig (K8s mode only) |
| `TF_VAR_keycloak_password` | *(empty)* | Keycloak admin password |

---

## Pipeline Considerations

### CI/CD with Kubernetes mode

The pipeline uses Kubernetes mode by default. Required CI/CD variables:

| Variable | Required | Description |
|---|---|---|
| `TF_VAR_config_path` | Yes | Path to the kubeconfig file on the runner |
| `TF_VAR_keycloak_password` | No | Override password (otherwise read from K8s Secret) |
| `KUBECONFIG_B64` | Yes | Base64-encoded kubeconfig for cluster access |

The pipeline stages `config` and `config-plan` rely on:
- The runner having `terraform`, `curl`, and `jq` available
- Network connectivity from the runner to the Keycloak endpoint
- A valid kubeconfig with permissions to read Secrets and manage the TF state Secret

### CI/CD with local mode

For pipelines that cannot access the Kubernetes cluster (e.g. GitLab runners without
cluster connectivity), set `TF_VAR_use_kubernetes=false` and provide credentials
explicitly via CI/CD variables.

> Note: In local mode, Terraform state is stored on the runner filesystem and will be
> lost between pipeline runs unless persisted via artifacts or cache.

### Self-signed certificates in CI/CD

When `insecure_tls = true` is set in the tfvars, the `managePolicies.sh` script
automatically skips TLS certificate verification for its API calls (`curl -k`).
No additional tools (openssl, keytool, Java) are required.

---

## Troubleshooting

- **Terraform init fails:** Verify that `config_path` points to a valid kubeconfig
  file and the current context is correct (`kubectl config get-contexts`).
- **Terraform apply fails initializing Keycloak provider:**
  - Check the `keycloak_url` in your `STAGE.tfvars`.
  - In K8s mode: confirm the admin password is present in the cluster secret
    (`kubectl get secret authserver-admin -n <namespace> -o yaml`). The secret
    should contain base64-encoded `username` and `password` fields.
  - In local mode: ensure `TF_VAR_keycloak_password` is set.
  - If you encounter TLS certificate errors (`x509: certificate signed by unknown
    authority` or `PKIX path validation failed`), set `insecure_tls = true` in the
    tfvars.
- **`curl` or `jq` not found:** The policy management script requires `curl` and
  `jq`. Both are standard tools available on most systems and CI runners.
- **State conflicts in local mode:** If switching between K8s and local mode, run
  `make clean` first to remove the old backend state and re-initialize.

---

## Additional Notes

- In Kubernetes mode, Terraform state is stored in a Kubernetes Secret within the
  environment namespace. Secret name format: `tfstate-<workspace>-state`
  (e.g., `tfstate-default-state`).
- In local mode, state is stored in `terraform/authserver/terraform.tfstate` (gitignored).
- The `main.tf` file is generated dynamically and should not be edited manually (gitignored).
- The Makefile and Terraform configurations are designed for seamless CI/CD integration.
- In some cases when starting from scratch, deleting the Terraform state may be required.

---

## Related Resources

- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Terraform Keycloak Provider](https://registry.terraform.io/providers/keycloak/keycloak/latest/docs)
- [Keycloak Admin REST API](https://www.keycloak.org/docs-api/latest/rest-api/index.html)
