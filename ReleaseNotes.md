<img align="right" width="250" height="47" src="docs/img/Gematik_Logo_Flag.png"/> <br/>

# Release Notes ZETA Guard Helm Charts

## Release 0.5.3

### changed:

- authserver 0.5.1
- hsm_sim 0.5.0

## Release 0.5.2

### added:
 
- authserver hsm support (TLS)
- upgrade cert-manager v1.20.1
- hsm_sim 0.5.0 disabled by default

## Release 0.5.1

### added:

- pep hsm support (TLS)

## Release 0.5.0

### added:

- Description and examples for more or less all values in `charts/zeta-guard/values.schema.json`
- Support configuration of OCSP stapling for ASL
- Option to enable or disable no-travel enforcement
- Option to deploy hsm proxy simulator for the test setup
- Provisioning Processor (run in sidecars) that downloads the provisioning container from gematik and derives the trust anchors from it.
- Terraform configuration now supports Kubernetes and local operating modes. Set `use_kubernetes = true` (default) to store state in a K8s Secret and fetch credentials from the cluster, or `use_kubernetes = false` to use a local state file and explicit credentials. See [How to configure authserver](docs/how-to_guides/How_to_configure_authserver.md).
- Terraform variable validations for `keycloak_namespace`, `keycloak_url`, `pdp_scopes`, and a cross-variable check that credentials are provided in local mode

### changed:

- Replaced OpenShift Route (`openshiftRoute`) with Ingress-based TLS support (`openshiftIngress`). The custom `openshift-route.yaml` template has been removed. Migrate from `openshiftRoute.enabled` / `openshiftRoute.host` / `openshiftRoute.issuer` to `openshiftIngress.enabled` + `openshiftIngress.certName`. This works with OpenShift's Ingress-to-Route controller and creates edge-terminated routes with TLS redirect.
- Testdriver ingress is now configurable: added `ingressEnabled`, `nginxIngressEnabled`, and `openshiftIngress` toggles to the testdriver subchart.
- Fixed configuration of telemetry-collector in `local-test/values.local.yaml`.
- Fixed erroneous TLS configuration for telemetry-gateway.
- You can now provide your own secrets to the zeta-guard sub chart instead of having them created. 
- Make it optional for the chart to deploy secrets. It's now possible to reference existing secrets.
- `managePolicies.sh` now uses the Keycloak REST API (`curl`+`jq`) instead of `kubectl exec` + `kcadm.sh` into the Keycloak pod. No Java or Keycloak CLI installation required.
- `main.tf` is now generated dynamically from templates and gitignored; the backend block is selected based on `use_kubernetes`
- Keycloak admin username and password are resolved dynamically in both the Terraform provider and the policy management script
- `keycloak_password` and `keycloak_username` are now both marked `sensitive` in Terraform variables
- Keycloak provider version constraint updated to `>= 5.7.0`
- Updated OpenTelemetry collector to version 0.149.0.

## Release 0.4.1

### added:

- Configurable authserver DB connection pool and HTTP thread pool
- Configurable resource limits and requests

### changed:

- Updated OPA and NGINX-Ingress

### removed:

- Removed log-collector component

## Release 0.4.0

### added:

- Support for container image digests in compound `image` values
- Support for custom affinities, labels, pod annotations and tolerances
- Support for individual security context per pod
- Support for OpenShift compatibility
- OPA simulation support
- Enabled telemetry delivery to gematik by default
- Configurable replica counts
- PEP sticky sessions for multi-replica deployments
- Support for external Infinispan

### changed:

- `GENESIS_HASH` and `SMCB_HASHING_PEPPER` are now provided exclusively via Kubernetes Secrets and are no longer configured directly in the template file. These values must be present in the respective values.yaml during the initial deployment; for upgrades, existing Secrets are retained.
- For external database configurations, both the Keycloak database username and password are now expected as keys within the same Kubernetes Secret (`authserverDb.kcDbSecretName`).
- Charts have been tested with RedHats local OpenShift testplatform, CodeReady Containers (CRC) with standard pod security `restricted-v2`.
- It is now possible to set the `securityContext` on a per-pod basis via Helm values.
- Support for lists of image pull secrets and aligned values with Kubernetes
  syntax
- Database modes: only `cloudnative` (CloudNativePG) and `external` are
  supported. Use a single cluster-wide CloudNativePG operator.
- `opa.image` is now a string value instead of a compound value.
- Container images of CronJobs and nginx-prometheus-exporter are now
  configurable.
- Aligned values for image pull policies with Kubernetes syntax.
- Updated OpenTelemetry collector to version 0.147.0.
- Updated OpenPolicyAgent to version 1.14.0-static.
- **BREAKING CHANGE** Pod selectors now use Kubernetes' well-known labels
- Configurable smc-b keystore
- The chart's Ingresses have become optional, and you can configure their annotations.
- `nginx-ingress.enabled` has been replaced by `nginxIngressEnabled`.
- k8sattributes processor deactivated for log-collector and telemetry-gateway
- Restricted log collection to OPA pods and containers.

### removed:

- Support for Bitnami PostgreSQL subchart removed.
- Support for Zalando Postgres Operator removed (`databaseMode: operator` no
  longer available).
- Unused value `global.registry`
- Labels containing container image tags

## Release 0.3.2

### changed
- authserver-version

## Release 0.3.1

### added
- websocket support

## Release 0.3.0

### added:
- added support for postgres operator by documentation and makefile; also in
  local test setup
- telemetry-gateway can redact known kinds of secrets and personal information
  from logs, metrics and traces
- Mergeable Ingress (F5 NIC: master + minions)

### changed:
- Helm 4 required; Kubernetes >= 1.25;
- TLS defaults hardened (protocols, ciphers, HSTS)
- **BREAKING CHANGE**. We changed the ingress to F5 nginx-ingress NIC mergeable (master + minions).
  If you were using the original community ingress-nginx from the ZETA umbrella chart,
  delete the cluster-scoped IngressClass and ValidatingWebhookConfiguration, and remove the
  associated Deployment/Services/Lease in your target namespace before deploying the new
  version. For example (replace NAMESPACE and STAGE):
  ```shell
  # cluster-scoped admission webhook (community ingress-nginx)
  kubectl delete validatingwebhookconfiguration zeta-testenv-STAGE-ingress-nginx-admission --ignore-not-found

  # namespaced community controller objects
  kubectl -n NAMESPACE delete deploy zeta-testenv-STAGE-ingress-nginx-controller --ignore-not-found
  kubectl -n NAMESPACE delete svc zeta-testenv-STAGE-ingress-nginx-controller --ignore-not-found
  kubectl -n NAMESPACE delete svc zeta-testenv-STAGE-ingress-nginx-controller-admission --ignore-not-found
  kubectl -n NAMESPACE delete lease zeta-testenv-STAGE-ingress-nginx-leader --ignore-not-found

  # cluster-scoped IngressClass used by the old controller
  kubectl delete ingressclass nginx-STAGE --ignore-not-found
  ```
  If Helm fails with lease ownership/validation errors during upgrade:
  - Adopt the existing Lease into the release:
    ```shell
    kubectl -n NAMESPACE annotate lease zeta-testenv-STAGE-nginx-ingress-leader-election meta.helm.sh/release-name=zeta-testenv-STAGE --overwrite
    kubectl -n NAMESPACE annotate lease zeta-testenv-STAGE-nginx-ingress-leader-election meta.helm.sh/release-namespace=NAMESPACE --overwrite
    kubectl -n NAMESPACE label lease zeta-testenv-STAGE-nginx-ingress-leader-election app.kubernetes.io/managed-by=Helm --overwrite
    ```
  - Or delete the Lease and redeploy:
    ```shell
    kubectl -n NAMESPACE delete lease zeta-testenv-STAGE-nginx-ingress-leader-election
    ```

  Notes:
  - Stray community ingress-nginx ValidatingWebhookConfigurations from other environments can block Ingress
    applies cluster-wide if their admission Service has no endpoints. Remove unused
    `*-ingress-nginx-admission` webhooks (or temporarily set `failurePolicy: Ignore`) before deploying.
  - hardened security context for all components

## Release 0.2.8

### changed:
- authserver and testdriver/exauthsim now have separate keystores/truststores.
  This chart now includes an RU based truststore for the authserver. For the
  testdriver/exauthsim you still need to bring your own cert&key. 
- The values for the SMCB keystore have changed slightly. Now they are
  `smcb_keystore.keystore` and `smcb_keystore.password` with the same semantics.
  No changes are needed when using the makefile for the test setup.

## Release 0.2.7

### added:
- ability to configure external DBs. See helm values authserverDb.* in zeta-guard subchart
- improvements for better compliance with some kubernetes security policies

### changed:
- Makefile: streamlined stage/namespace/values selection; safer templating; clearer help
- Enforce admin-password of Authserver on initial deployment

## Release 0.2.6

### added:
- config for ASL test mode
- improved Betriebsdatenlieferung

### changed:
- updated versions of several subcomponents

## Release 0.2.5

### changed:
- fix missing opa service account
- fix popp token config

## Release 0.2.4

### added:
- missing file(s) for local deployments

### changed:
- minor doc improvements
- updated individual components to their newes versions
- functional userdata and clientdata headers (beware clientdata schema is still subject to change)

## Release 0.2.0

### added:
- bundling functionality of milestone 2 incl client registration, smcb token exchange
- public release of test setup

## Release 0.1.3

### added:
- Helm chart for the prototype of ZETA Guard added
