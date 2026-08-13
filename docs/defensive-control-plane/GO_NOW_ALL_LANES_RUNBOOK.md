# Go-NOW Runbook: Solo Team "Everything" Path (Local + Production Follow-Through)

This is the execution plan to move from the verified local defensive control-plane
to end-to-end operational posture.

## Current truth snapshot (do not skip)

- This workspace contains a completed local defensive control-plane artifact at
  version `0.3.0`.
- Source/delivery integrity is already captured in:
  - `defensive-control-plane-v0.3.0.zip`
  - `defensive-control-plane/evidence/local-verification.json`
- External product/runtime proof is **not** established in this workspace.
- Replit machine lookup for Machine Innovate was previously unavailable, and no PR,
  merge, push, deploy, domain, or secret mutation was executed here.

If we try to claim `productionOperational = true` without the steps below, we will
be making an unsupported claim.

## Track A — Product lane hardening (parallelizable now)

1. Register the exact destination environment:
   - source worktree/repo path
   - runtime host/container
   - CI workflow identifiers
2. Wire runtime routes with auth and TLS first:
   - `POST /events` (signed event ingestion)
   - `POST /envelopes`
   - `POST /approvals`
   - `POST /executions`
   - `GET /evidence/export`
   - health routes remain read-only and loopback-safe in internal mode
3. Replace `FakeTicketConnector` with a hardened production connector adapter:
   - explicit idempotency key
   - provider readback
   - signed receipt validation
4. Add tenant-scoped key management via managed secret store.
5. Add deployment probes for:
   - TLS cert validity
   - host allowlists
   - method/path allowlist
   - rate limiting + request sizing

## Track B — Cybersecurity lane (parallelizable now)

1. Connect identity source:
   - event author identity, SSO claims, and token issuance
2. Attach detector sources:
   - endpoint logs
   - cloud control plane logs
   - SIEM/SOAR alerts
3. Enforce policy gates:
   - SOD for approval paths
   - explicit approver role checks
   - approval TTL and rotation
4. Confirm evidence and retention:
   - immutable evidence DB path
   - backup and DR restore drill scheduling
   - case chain export verification in CI

## Track C — Data + AI lane (parallelizable now)

1. Add signed data schema manifests for incoming event payloads.
2. Add tenant-scoped data controls:
   - DLP classes
   - masking/pseudonymization policy
3. Add model/API abuse detection on any AI-driven playbooks.
4. Ensure no model connector can bypass defensive envelope allowlist.

## Track D — Operations lane (parallelizable now)

1. Define incident runbook with named roles:
   - first responder
   - approver
   - analyst
   - evidence owner
2. Add runbook steps for:
   - CLAIMED timeout response
   - BLOCKED_UNCERTAIN reconciliation
   - export chain verification failure
3. Add scheduled DR restore test with pre/post digest checks.
4. Add metrics:
   - ingest error rate
   - approval latency
   - execution duration
   - blocked/uncertain ratio

## Track E — People lane (parallelizable now)

1. Onboard every operator to principal issuance flow.
2. Run simulated dry-run phishing / privilege scenario training.
3. Add role review cadence:
   - monthly approver audit
   - quarterly access review
4. Lock service accounts and rotate connector tokens quarterly.

## Track F — Governance lane (parallelizable now)

1. Maintain a risk register with owner + due date for every unresolved exception.
2. Promote evidence posture monthly:
   - local lane: PASS
   - proof lane: PENDING until runtime witness
3. Freeze any production promotion if:
   - any critical dependency is `UNAVAILABLE`
   - any schema digest check fails
   - any cross-tenant validation fails

## Parallel execution structure (solo with deterministic batching)

You can run this in waves to keep momentum:

1. Wave 1: finalize deployment target + credentials.
2. Wave 2: implement product/cyber/security connector boundaries.
3. Wave 3: add data/control policy and operations/people controls.
4. Wave 4: governance sign-off + launch review + evidence witness.

## Execution criteria to call deployment ready

- Local artifact and tests already green.
- Production environment has real connectors for at least one lane with independent
  signed witness.
- All critical lanes move from `UNAVAILABLE`/`PARTIAL` to explicit evidence-backed
  truth labels.
- CI has a gate that runs local package verification before merge.
- No claims of production operation are published until external witness is attached.

## Immediate commands we still need once target is known

When you provide the target repository/runtime, I will execute:

1. exact checkout and branch refresh
2. protected checks integration
3. route integration patch
4. CI-safe commit plan
5. merge and post-merge proof capture
6. deployment, witness, and status update

No silent shortcuts; everything above is required before claiming full operational parity.
