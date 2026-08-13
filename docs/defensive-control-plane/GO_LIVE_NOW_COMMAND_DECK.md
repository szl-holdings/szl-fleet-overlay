# Go-Live Command Deck (All Lanes — Immediate Execution)

This deck assumes we proceed immediately and in parallel, but still require explicit
target details to execute against real infrastructure.

## 0) Green-light state now

- Local control-plane: green (`LocalDefensiveControlPlaneVerificationV1`, state
  `VERIFIED_LOCAL`).
- Evidence boundary: explicit and non-promoting (`UNAVAILABLE` for external deploy/runtime).
- Security posture: safe defaults still enforced (dry-run, tenant isolation, approvals,
  tenant-bound evidence/signing, no external side effects).
- Next truth transition target: production witness + connector integration.

## 1) One command set to run once the target is known

### Infrastructure bootstrap
1. Export deployment and target variables:
   - `TARGET_REPO`
   - `TARGET_BRANCH`
   - `TARGET_RUNTIME`
   - `CI_WORKFLOW`
2. Validate checkout and protected-gate visibility.

### Source + security integration
1. Add connector adapters for lanes:
   - identity
   - endpoint
   - siem
   - email
   - cloud
   - ticketing
2. Replace `FakeTicketConnector` only at configured boundary points.
3. Add managed secret reads for:
   - event signing keys
   - evidence signing keys
   - assertion secret
   - connector credentials

### Deployment + evidence
1. Wire read/write HTTP surface behind auth and internal auth policy.
2. Extend CI with:
   - full suite gate
   - demo gate
   - verify gate
3. Deploy and capture:
   - runtime URL
   - TLS and host details
   - startup hash and environment hash

### Truth and witness
1. Attach independent witness output (external runner not the same process that built.
2. Re-run local verification in target-equivalent mode and archive receipt.
3. Keep `PARTIAL`/`UNAVAILABLE` lane states visible until each connector lane has
   independent evidence.

## 2) Parallel lane execution matrix

| Lane | Immediate action now | Proof required to leave `PARTIAL` |
|---|---|---|
| cybersecurity | finalize external ingest sources + connector integration | production evidence that signed events execute with real outcomes |
| product | route exposure + auth + key rotation | deployment proof for `/events`, `/approvals`, `/executions` |
| data-ai | schema + data policy enforcement | witness of policy enforcement and tamper-evident evidence |
| operations | DR, alerting, paging runbooks | restore + alert drill artifacts attached |
| people | role issuance and review cadence | approver/analyst roster with attested identities |
| governance | risk register + board scorecard | monthly signed risk and exception closure evidence |

## 3) Hard constraints (do not bypass)

1. No PR/merge/deploy claim without exact CI + protected branch state.
2. No production readiness claim without readback witness.
3. No connector replacement without tenant-scoped idempotency + readback binding.
4. No runtime operational state update from local-only outputs.
5. No secret material in code, docs, or plain logs.

## 4) Exit criteria (all lanes green)

- `productionOperational == true`
- `deployedRuntime != UNAVAILABLE`
- lane connector states no longer `UNAVAILABLE`
- all critical exceptions closed with owner + due date
- external witness attached for deploy and recovery drill
- source and evidence hashes recorded in final handoff package

If you want me to execute live now, I’ll begin with the target bootstrap block
and apply all of the above in one pass, lane by lane.
