# szl-fleet-overlay

UDS Operator package + Helm chart + Zarf bundle + peat-mesh nodes for the 5 SZL flagships.
Layers doctrine-pinned DSSE receipts on top of UDS Fleet.

<!-- Doctrine: v11 LOCKED 749/14/163 at kernel commit c7c0ba17 | Λ = Conjecture 1 | SLSA L1 | Section 889 = 5 vendors -->

## What This Is

`szl-fleet-overlay` registers each SZL flagship application — **a11oy, sentra, amaru, rosie, killinchu** — as a first-class UDS-managed application running on top of [UDS Core](https://github.com/defenseunicorns/uds-core).

It provides:

1. **UDS `Package` CRs** for each flagship — Istio routing, NetworkPolicy, SSO (Keycloak), and portal tiles
2. **Doctrine-pinned receipts** (`checksums.txt` + cosign detached signatures) for SLSA L1 honest attestation
3. **Three deployment variants**: pure Zarf (air-gap canonical), Helm chart (GitOps), peat-mesh-node (CRDT sync)

All variants share the same `Package` CR definitions in `configs/packages/` but differ in how application workloads are delivered.

See [`SZL_FLEET_OVERLAY_DESIGN.md`](https://github.com/szl-holdings/szl-fleet-overlay/blob/main/SZL_FLEET_OVERLAY_DESIGN.md) for full architecture, Package CR spec, and receipt generation details.

---

## Fleet Application Inventory

| App        | Namespace      | Port | SSO Client ID       | Peat Node |
|------------|---------------|------|---------------------|-----------|
| a11oy      | `szl-a11oy`   | 8080 | `uds-szl-a11oy`     | Yes       |
| sentra     | `szl-sentra`  | 8080 | `uds-szl-sentra`    | Yes       |
| amaru      | `szl-amaru`   | 8080 | `uds-szl-amaru`     | Yes       |
| rosie      | `szl-rosie`   | 8080 | `uds-szl-rosie`     | Yes       |
| killinchu  | `szl-killinchu`| 8080 | `uds-szl-killinchu` | Yes       |

All applications are served over the UDS **tenant** gateway. SSO group gate: `/szl-operators`.

---

## Three Deployment Variants

### Variant 1 — Pure Zarf (canonical air-gap)

Produces a self-contained `.tar.zst` requiring only `zarf init` and `zarf package deploy`.

```bash
# Build
uds zarf package create . -a amd64 --confirm

# Deploy
uds zarf package deploy zarf-package-szl-fleet-overlay-amd64-0.1.0.tar.zst --confirm
```

Use `tasks.yaml` (Maru) for the full build/sign/publish workflow:

```bash
uds run build
uds run sign-receipts
uds run publish
uds run validate
```

### Variant 2 — Helm Chart (GitOps / ArgoCD / Flux)

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

The peat-mesh-node variant wraps the fleet overlay with `peat-node` sidecars, enabling Automerge+Iroh QUIC CRDT-based state sync between SZL flagship apps.

Configs live in `configs/peat/`. Deploy via the Zarf or Helm variant — peat mesh nodes are an optional component (`required: false, default: true` in `zarf.yaml`).

---

## Deployment Order (strictly follows SHARED_CONTEXT.md sequence)

```
Phase                     Command
─────────────────────────────────────────────────────────────────
1. Zarf init (once)       uds zarf init --confirm
2. Deploy uds-core        uds deploy oci://ghcr.io/defenseunicorns/packages/uds/core:0.33.0-upstream
3. Deploy fleet overlay   uds deploy oci://ghcr.io/szl-holdings/fleet-overlay:0.1.0 --confirm
   (or Helm variant)      helm upgrade --install szl-fleet-overlay ./chart -n szl-system --create-namespace \
                            -f chart/values/prod.yaml
4. Verify portal tiles    curl -sk https://portal.uds.dev/api/packages | jq '.[] | select(.name | startswith("szl"))'
5. Verify receipts        cosign verify-blob --key cosign.pub --signature receipts/checksums.txt.sig receipts/checksums.txt
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
│       ├── package-{app}.yaml         # One per flagship (5 total)
│       └── namespace-{app}.yaml       # (rendered by _helpers.tpl)
│
├── configs/
│   ├── packages/                      # Package CR YAMLs (all variants)
│   │   └── package-{app}.yaml         # One per flagship
│   └── peat/                          # Peat mesh node configs
│       └── peat-node-{app}.yaml       # One per flagship
│
└── receipts/                          # Doctrine-pinned receipts
    ├── checksums.txt                  # SHA256 of every config file
    ├── checksums.txt.sig              # cosign detached signature
    └── doctrine-pin.yaml             # Doctrine version lock record
```

---

## Compliance Posture

| Control              | Status                                    |
|----------------------|-------------------------------------------|
| SLSA Level           | L1 (honest attestation only)              |
| Doctrine             | v11 LOCKED — 749/14/163 — kernel `c7c0ba17` |
| Λ                    | Conjecture 1 (NEVER theorem)              |
| Section 889 vendors  | 5 — Huawei, ZTE, Hytera, Hikvision, Dahua (excluded) |
| Iron Bank            | NOT used                                  |
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
