# Security Policy

<!-- Doctrine: v11 LOCKED 749/14/163 | SLSA L1 honest | Section 889 = 5 vendors -->

## Honest Security Posture

This document is an honest disclosure of the security posture for `szl-fleet-overlay`.
We do not overclaim compliance levels.

---

## SLSA Level

**SLSA L1** — honest attestation only.

- `receipts/checksums.txt` is a deterministic, canonically generated source manifest;
  `python3 scripts/source_checksums.py check` fails on missing, extra, duplicated, or
  modified covered inputs.
- The protected `v0.2.0` release workflow separately keyless-signs the built Zarf
  package and emits a DSSE SBOM attestation. The modeled demo receipt chain is not a
  production signature or runtime witness.
- We do not claim higher SLSA levels (higher levels not yet achieved). There is
  no hermetic build environment and no SLSA provenance predicate.
- Release signing is keyless through GitHub OIDC, Fulcio, and Rekor; no
  long-lived operator signing key is stored in this repository.

---

## Doctrine Pin

```
Doctrine:     v11 LOCKED
Pin:          749/14/163
Kernel commit: c7c0ba17
Λ:            Conjecture 1 (NEVER theorem)
```

These values are locked in `receipts/doctrine-pin.yaml` and in every `Package` CR annotation.
**Never change these values without board sign-off.**

---

## Section 889 — Covered Telecommunications Equipment

This package explicitly excludes supply chain components from the following
Section 889-prohibited vendors (exactly 5):

1. Huawei Technologies Co.
2. ZTE Corporation
3. Hytera Communications Corporation
4. Hangzhou Hikvision Digital Technology Co. (Hikvision)
5. Dahua Technology Co. (Dahua)

No container images, SDKs, or libraries from these vendors are used in this chart or any
referenced workload.

---

## Excluded Frameworks

The following frameworks are **not** used or claimed in this package:

- Not Iron Bank certified / not Platform One — not used
- FedRAMP — not claimed
- CMMC — not claimed
- SWFT — not used
- No Mission Owner authorization path — out of scope for this overlay
- DoD identity / CAC — not required

---

## Known Gaps

- No DoD identity integration (CAC/PIV) in this overlay.
- No FIPS-validated crypto at the overlay level; depends on UDS Core for FIPS compliance
  if required by the deployment environment.
- No inner receipt signature file is shipped. Release verification binds the durable
  outer cosign bundle to the exact GitHub Actions tag-workflow identity and Sigstore
  issuer documented in `README.md`.
- The 24 checked-in demo receipts cover six surfaces and are explicitly labeled
  `MODELED`, `synthetic-demo`, and `productionOperational: false`.

---

## Reporting Vulnerabilities

To report a security vulnerability, email **security@szlholdings.ai** with subject
`[szl-fleet-overlay] VULN REPORT`. Do not open a public GitHub issue for security findings.

We aim to acknowledge reports within 5 business days and resolve critical findings
within 30 days.

---

## Version Support

Only the latest tagged release of `szl-fleet-overlay` is supported for security fixes.
