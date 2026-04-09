#!/bin/bash
set -e

TEMPLATE_DIR="templates"
TARGET_DIR="."
ENV_DIR="environments"
MAIN_TF_TPL="$TEMPLATE_DIR/main.tf.tpl"
BACKEND_K8S_TPL="$TEMPLATE_DIR/backend.k8s.tpl"
BACKEND_LOCAL_TPL="$TEMPLATE_DIR/backend.local.tpl"
MAIN_TF="$TARGET_DIR/main.tf"

USE_K8S="${TF_VAR_use_kubernetes:-true}"
STAGE="${STAGE:-local}"
NAMESPACE="${NAMESPACE:-zeta-local}"
CONFIG_PATH="${TF_VAR_config_path:-~/.kube/config}"
BACKEND_HCL="$ENV_DIR/${STAGE}.backend.hcl"

# select backend block
if [ "$USE_K8S" = "true" ]; then
    BACKEND_BLOCK_FILE="$BACKEND_K8S_TPL"
else
    BACKEND_BLOCK_FILE="$BACKEND_LOCAL_TPL"
fi

# generate main.tf — read replacement file directly in awk (avoids multiline -v issues)
awk 'NR==FNR {block = block sep $0; sep="\n"; next} {sub(/\{\{BACKEND_BLOCK\}\}/, block)} 1' "$BACKEND_BLOCK_FILE" "$MAIN_TF_TPL" > "$MAIN_TF"
echo "Generated $MAIN_TF with backend: $(head -1 "$BACKEND_BLOCK_FILE")"

# generate backend.hcl
if [ "$USE_K8S" = "true" ]; then
    cat > "$BACKEND_HCL" <<EOF
config_path   = "$CONFIG_PATH"
namespace     = "$NAMESPACE"
EOF
else
    : > "$BACKEND_HCL"
fi
echo "Generated $BACKEND_HCL"
