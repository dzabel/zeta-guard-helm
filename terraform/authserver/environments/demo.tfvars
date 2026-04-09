# Demo environment Terraform variables.
# Copy this file as <stage>.tfvars and adjust for your environment.
#
# Operating modes:
#   use_kubernetes = true  → State in K8s Secret, credentials from cluster secret
#   use_kubernetes = false → State in local file, credentials must be set explicitly
#                            (TF_VAR_keycloak_password and TF_VAR_keycloak_username)

insecure_tls       = true                          # Enable for self-signed certificates (optional, default is false)
use_kubernetes     = true                          # Use Kubernetes backend and fetch credentials from cluster
keycloak_url       = "https://example.domain/auth" # External URL of the Keycloak server
keycloak_namespace = "zeta-demo"                   # Namespace where the authserver is deployed
pdp_scopes         = ["zero:read", "zero:write"]   # Additional PDP scopes
