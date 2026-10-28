# Antigravity Jules CD Plugin Invariants (AGENTS.md)

## 1. The Core Doctrine
All continuous integration, task delegation, and pull request management MUST strictly operate at the intersection of:
**LOGIC • REASON • STRATEGY**

No action may be taken outside of this intersection.

---

## 2. The Single-Branch Remote Invariant
- **Permanent State:** The remote repository must only have **1 active branch** (`main` or `master`).
- **Ephemeral Isolation:** Jules works on transient feature branches created by its cloud sandbox.
- **Immediate Pruning:** As soon as a Jules PR is verified and squash-merged into `main`, its remote branch MUST be deleted immediately.
- **Zero Stale Branches:** Any superseded, non-mergeable, or abandoned Jules branches must be cleanly closed and removed from remote.

---

## 3. Mandatory Sovereign Ledger (`JULES_HANDOFF.md`)
- Every repository connected to Jules MUST maintain a `JULES_HANDOFF.md` at its root on the default branch.
- Any merge, closure, or agent handoff MUST append an entry documenting:
  - Timestamp (ISO 8601 / formatted)
  - PR number and title
  - Action taken (Squash-merged / Closed superseded)
  - Files modified or scope of changes
  - Next steps for subsequent agents (Antigravity, Hermes, Qwen, Jules)

---

## 4. Multi-Agent Cohesion
- When multiple AI agents (Antigravity, Hermes Prime, Qwen Desktop, Google Jules) operate on the same repository, they MUST inspect `JULES_HANDOFF.md` before making structural modifications.
- Uncommitted or unmerged divergent branches are strictly forbidden.
