# Backend configuration for Kubernetes mode (use_kubernetes = true).
# This file is passed to `terraform init -backend-config=`.
# When using local mode (use_kubernetes = false), this file is empty
# and the backend "local" block in main.tf is used instead.
#
# Generated automatically by generate-main-and-backend.sh.

config_path = "~/.kube/config" # Path to kubeconfig file
namespace   = "zeta-demo"      # Namespace where the TF state secret is stored
