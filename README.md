# szl-fleet-overlay — SZL Fleet Deployment Overlay

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg?style=flat-square)](LICENSE)

**Doctrine v11 LOCKED 749/14/163** · Λ = Conjecture 1 · SLSA L1+L2 honest (NOT L3) · Kernel `c7c0ba17`

UDS Operator packages, Helm chart, and Zarf bundle for five SZL flagship surfaces plus the Defensive Control Plane.

> **Trademark / non-affiliation notice.** SZL Holdings' use of "UDS" references Defense Unicorns' Unified Defense Stack (USPTO Serial 99831122). SZL Holdings is **not affiliated with Defense Unicorns**. SZL contributions to the UDS ecosystem are made through upstream PRs. Upstream **UDS Core** (AGPL-3.0) is used as a **deployment pattern / dependency only — it is not vendored or adopted into this repository**. See https://defenseunicorns.com/uds

Layers doctrine-pinned, hash-chained modeled receipt fixtures on top of UDS Fleet. The post-merge release workflow separately emits the signed Zarf artifact and DSSE SBOM attestation.

**Deployment story:** this overlay is the UDS Operator entry point. Bundle manifests live in [uds-bundles](https://github.com/szl-holdings/uds-bundles); air-gap deploy procedures in [szl-uds-deployment](https://github.com/szl-holdings/szl-uds-deployment); the CRDT coordination layer is [szl-mesh](https://github.com/szl-holdings/szl-mesh).

## Prerequisites

- [Zarf](https://docs.zarf.dev/getting-started/install/) v0.77+
- [UDS CLI](https://uds.defenseunicorns.com/docs/getting-started/) v0.32+
- [cosign](https://docs.sigstore.dev/cosign/installation/) v2.2+ (for signature verification)
- A running UDS Core cluster (K3d for development: `uds deploy k3d-core`)

## Quickstart — Register the Fleet and Deploy DCP

```bash
# Pull the v0.2.0 overlay (register five pre-existing flagships; deploy DCP)
zarf package pull oci://ghcr.io/szl-holdings/packages/szl-fleet-overlay:0.2.0-amd64

# Download the durable verification bundle from the matching GitHub release
gh release download v0.2.0 --repo szl-holdings/szl-fleet-overlay \
  --pattern 'zarf-package-szl-fleet-overlay-amd64-0.2.0.tar.zst.cosign.bundle'

# Verify before deploying
cosign verify-blob \
  --certificate-identity "https://github.com/szl-holdings/szl-fleet-overlay/.github/workflows/zarf-package-sign.yml@refs/tags/v0.2.0" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --bundle zarf-package-szl-fleet-overlay-amd64-0.2.0.tar.zst.cosign.bundle \
  zarf-package-szl-fleet-overlay-amd64-0.2.0.tar.zst

uds zarf package deploy zarf-package-szl-fleet-overlay-amd64-0.2.0.tar.zst --confirm
```

Before deployment, apply `configs/namespaces.yaml` and create `szl-defensive-control-plane-signing-keys` in `szl-defensive-control-plane` with two different 64-character lowercase hexadecimal values named `event-root-key-hex` and `evidence-key-hex`. Generate them independently through the cluster secret manager; never commit them. Zarf vendors the private DCP image into its seed registry. For direct Helm installs, set `apps.defensiveControlPlane.imagePullSecretName` to an existing `kubernetes.io/dockerconfigjson` Secret.

The DCP image is private while this overlay repository is public. Do not grant the public repository package-wide Actions access: GitHub warns that forks of a public repository may then be able to access a private package. Credentialed CI and the tag publisher instead require `DCP_PULL_USERNAME` and `DCP_PULL_TOKEN` Actions secrets for a dedicated low-privilege principal whose classic token has `read:packages` only. GitHub withholds those secrets from fork and Dependabot pull requests; those events explicitly report private-image pull, container self-smoke, and full Zarf build as `UNAVAILABLE` while public structural gates continue. Trusted same-repository PRs, pushes, and dispatches fail closed when either secret is absent. The `v0.2.0` publisher also fails closed until both secrets exist.

The DCP Service is cluster-only and default-deny. This release creates no public gateway, ingress, OIDC claim, provider connector, event-ingestion API, approval API, or execution API. Its status routes are `/livez`, `/readyz`, `/api/build-info`, `/api/lanes`, and `/api/v1/lanes`; they continue to report external connectors unavailable and production operation false.

## Runtime demonstration

The two products run live on Hugging Face — same payload, different runtime:
- **a11oy:** [szlholdings-a11oy.hf.space](https://szlholdings-a11oy.hf.space)
- **killinchu:** [szlholdings-killinchu.hf.space](https://szlholdings-killinchu.hf.space)

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Package CR in `Pending` | Istio not ready | Wait for UDS Core istio-system; `kubectl get pods -n istio-system` |
| SSO redirect loops | Keycloak client not registered | Re-run `uds deploy` to sync SSO CRs |
| `zarf: permission denied` | Registry auth | `zarf tools registry login ghcr.io` |
| Pods not starting | Image pull backoff | Check GHCR token; `kubectl describe pod -n szl-<flagship>` |
| cosign verify fails | Wrong bundle filename | Match exact tag from release assets |
| Bad version deployed | Need to revert to last known-good | See [Rollback](docs/WARHACKER_DEMO_RUNBOOK.md#49-rollback--revert-the-overlay-to-a-known-good-version) (`helm rollback` / redeploy prior OCI tag / git-tag revert) |

---

<!-- Doctrine: v11 LOCKED 749/14/163 at kernel commit c7c0ba17 | Λ = Conjecture 1 | SLSA L1+L2 honest (NOT L3) | Section 889 = 5 vendors -->



`szl-fleet-overlay` registers the SZL applications — the **a11oy** command platform (and its policy, memory and operator capability services) plus **killinchu** (drones & vessels) — as first-class UDS-managed applications running on top of [UDS Core](https://github.com/defenseunicorns/uds-core). The per-service workload names below retain the original internal identifiers.

It provides:

1. **UDS `Package` CRs** for each application — Istio routing, NetworkPolicy, SSO (Keycloak), and portal tiles
2. **Doctrine-pinned evidence**: deterministic source checksums and modeled hash-chain fixtures; the `v0.2.0` tag workflow requires its target on protected main history, then produces the outer cosign bundle and DSSE SBOM attestation
3. **Three deployment variants**: pure Zarf (air-gap canonical), Helm chart (GitOps), peat-mesh-node (CRDT sync)

All variants share the same `Package` CR definitions in `configs/packages/` but differ in how application workloads are delivered.

See [`SZL_FLEET_OVERLAY_DESIGN.md`](https://github.com/szl-holdings/szl-fleet-overlay/blob/main/SZL_FLEET_OVERLAY_DESIGN.md) for full architecture, Package CR spec, and receipt generation details.

---

## Fleet Application Inventory

| App / capability        | Namespace      | Port | SSO Client ID       | Peat Node |
|-------------------------|---------------|------|---------------------|-----------|
| a11oy (command)         | `szl-a11oy`   | 8080 | `uds-szl-a11oy`     | Yes       |
| a11oy — policy/gate     | `szl-sentra`  | 8080 | `uds-szl-sentra`    | Yes       |
| a11oy — memory          | `szl-amaru`   | 8080 | `uds-szl-amaru`     | Yes       |
| a11oy — operator        | `szl-rosie`   | 8080 | `uds-szl-rosie`     | Yes       |
| killinchu               | `szl-killinchu`| 8080 | `uds-szl-killinchu` | Yes       |
| defensive control plane | `szl-defensive-control-plane` | 8080 | None | No |

The five flagship surfaces use the UDS tenant gateway and `/szl-operators` SSO gate. The Defensive Control Plane remains cluster-only, has no SSO claim, and is pinned to source `cbb7bddf0b584987830617e68725e36e9ed27434` and image digest `sha256:01f1fa2d3a4eb3cffb873f7393b64050df77f4383fa9d219163fa0be0bd6dce6`.

---

## Three Deployment Variants

### Variant 1 — Pure Zarf (canonical air-gap)

Produces a self-contained `.tar.zst` requiring only `zarf init` and `zarf package deploy`.

```bash
# Build
uds zarf package create . -a amd64 --confirm

# Deploy
uds zarf package deploy zarf-package-szl-fleet-overlay-amd64-0.2.0.tar.zst --confirm
```

Use `tasks.yaml` (Maru) for local build and verification. Canonical publication is tag-workflow-only:

```bash
uds run build
uds run sign-receipts
uds run validate
```

### Variant 2 — Helm Chart (GitOps / ArgoCD / Flux)

Helm does not create the target application namespaces or any Secret values. Apply `configs/namespaces.yaml`, provision the two DCP signing keys, and—when pulling directly from private GHCR—precreate a registry Secret and set `apps.defensiveControlPlane.imagePullSecretName` before running the commands below. `--create-namespace` creates only `szl-system`.

The DCP PVC carries `helm.sh/resource-policy: keep`; ordinary Helm uninstall and `uds run clean` preserve its SQLite evidence. Zarf removal is not claimed to preserve evidence. Destructive evidence removal is a separate, explicit operator action after an off-cluster backup and is intentionally not automated here.

```bash
# Install with prod values
helm upgrade --install szl-fleet-overlay ./chart \
  -n szl-system --create-namespace \
  -f chart/values/prod.yaml

# Dev values
helm upgrade --install szl-fleet-overlay ./chart \
  -n szl-system --create-namespace \
  -f chart/values/dev.yaml
```

The chart renders the same Package CRs as the Zarf variant, parameterized via `chart/values.yaml`.

### Variant 3 — Peat Mesh Node (CRDT state sync)

The peat-mesh-node variant wraps the fleet overlay with `peat-node` sidecars, enabling Automerge+Iroh QUIC CRDT-based state sync between SZL applications.

Configs live in `configs/peat/`. Deploy via the Zarf or Helm variant — peat mesh nodes are an optional component (`required: false, default: true` in `zarf.yaml`).

---

## Deployment Order (strictly follows SHARED_CONTEXT.md sequence)

```
Phase                     Command
─────────────────────────────────────────────────────────────────
1. Zarf init (once)       uds zarf init --confirm
2. Deploy uds-core        uds deploy oci://ghcr.io/defenseunicorns/packages/uds/core:1.5.0-upstream
3. Pull fleet package     zarf package pull oci://ghcr.io/szl-holdings/packages/szl-fleet-overlay:0.2.0-amd64
   Deploy fleet package   uds zarf package deploy zarf-package-szl-fleet-overlay-amd64-0.2.0.tar.zst --confirm
   (or Helm variant)      helm upgrade --install szl-fleet-overlay ./chart -n szl-system --create-namespace \
                            -f chart/values/prod.yaml
4. Verify portal tiles    curl -sk https://portal.uds.dev/api/packages | jq '.[] | select(.name | startswith("szl"))'
5. Verify source hashes   python3 scripts/source_checksums.py check
```

---

## Repository Layout

```
szl-fleet-overlay/
├── zarf.yaml                          # Pure-Zarf variant (canonical source)
├── uds-bundle.yaml                    # UDS Bundle for fleet deployment
├── tasks.yaml                         # Maru build/deploy tasks
│
├── chart/                             # Helm variant
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values/
│   │   ├── dev.yaml
│   │   ├── staging.yaml
│   │   └── prod.yaml
│   └── templates/
│       ├── _helpers.tpl
│       ├── package-{app}.yaml         # Six UDS Package CR templates
│       └── workload-defensive-control-plane.yaml
│
├── configs/
│   ├── packages/                      # Six Package CR YAMLs
│   ├── workloads/                     # DCP PVC, Deployment, Service, policy
│   └── peat/                          # Five legacy Peat mesh node configs
│
└── receipts/                          # Doctrine-pinned receipts
    ├── checksums.txt                  # deterministic source checksum manifest
    └── doctrine-pin.yaml             # Doctrine version lock record
```

---

## Compliance Posture

| Control              | Status                                    |
|----------------------|-------------------------------------------|
| SLSA Level           | L1+L2 (honest attestation only — NOT L3)  |
| Doctrine             | v11 LOCKED — 749/14/163 — kernel `c7c0ba17` |
| Λ                    | Conjecture 1 (NEVER theorem)              |
| Section 889 vendors  | 5 — Huawei, ZTE, Hytera, Hikvision, Dahua (excluded) |
| Not Iron Bank certified | Not used or required |
| FedRAMP              | NOT claimed                               |
| CMMC                 | NOT claimed                               |
| SWFT                 | NOT used                                  |
| DoD identity         | NOT present                               |

---

## Prerequisites

- [`uds-cli`](https://github.com/defenseunicorns/uds-cli) ≥ 0.16
- [`zarf`](https://github.com/defenseunicorns/zarf) ≥ 0.38
- `helm` ≥ 3.14 (Helm variant only)
- `cosign` ≥ 2.2 (receipt verification)
- `kubectl` with cluster access running UDS Core

---

## License

Apache-2.0. See [LICENSE](LICENSE).

## Contributing

DCO required. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Security

See [SECURITY.md](SECURITY.md) for honest disclosure of our security posture.

---

## UDS Package CRs — `uds-packages/` Directory

> **Gap 2 fix (P0, Warhacker June 9):** Added `uds-packages/` alongside the existing
> `configs/packages/` directory. These are the canonical, stand-alone Package CR YAMLs
> for use when deploying SZL flagships independently of the full fleet overlay chart.

The UDS Operator watches `Package` CRs in each flagship namespace. Without a Package CR,
UDS Core is blind to the workload — no Istio integration, no auto-generated NetworkPolicy,
no Keycloak SSO client, no ServiceMonitor.

### Package CR locations

| File | App / capability | Namespace |
|------|------------------|-----------|
| `uds-packages/a11oy.yaml` | a11oy (command) | `szl-a11oy` |
| `uds-packages/sentra.yaml` | a11oy — policy/gate | `szl-sentra` |
| `uds-packages/amaru.yaml` | a11oy — memory | `szl-amaru` |
| `uds-packages/rosie.yaml` | a11oy — operator | `szl-rosie` |
| `uds-packages/killinchu.yaml` | killinchu | `szl-killinchu` |
| `uds-packages/defensive-control-plane.yaml` | defensive control plane | `szl-defensive-control-plane` |

### Apply stand-alone Package CRs

```bash
# Apply a single flagship's Package CR (requires UDS Core already running)
kubectl apply -f uds-packages/a11oy.yaml

# Apply all at once
kubectl apply -f uds-packages/

# Verify operator reconciliation
kubectl get packages -A
kubectl describe package szl-a11oy -n szl-a11oy
```

### Package CR fields

Each Package CR configures:
- **`spec.network.expose`** — Istio VirtualService + tenant gateway ingress
- **`spec.network.allow`** — UDS-managed NetworkPolicy rules (egress to Keycloak, Peat mesh, etc.)
- **`spec.sso`** — Keycloak OIDC client registration (group-gated to `/szl-operators`)
- **`spec.monitor`** — Prometheus ServiceMonitor for the metrics endpoint

These are rendered from the Helm chart `_helpers.tpl` `szl-fleet.package` template when
deploying via the Helm variant, and applied directly via the Zarf `szl-<flagship>-package`
component.
