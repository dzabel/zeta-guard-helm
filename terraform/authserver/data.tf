data "kubernetes_secret_v1" "keycloak_admin" {
  count = var.use_kubernetes ? 1 : 0
  metadata {
    name      = var.keycloak_admin_secret
    namespace = var.keycloak_namespace
  }
}
