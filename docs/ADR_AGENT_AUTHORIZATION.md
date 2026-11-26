# Architecture decision pending for target-agent authorization

NovaDesk currently requires a manager to have the relevant team rights, the target to be an active member of that team and the target to hold the effective `ZNVD_AGT` right for that team. Assignment must remain unavailable when any of these conditions cannot be established. The current RAP candidate already rejects the assignment when the effective target right is unknown.

## SAP evidence

- SAP documents `AUTHORITY-CHECK` in ABAP Environment as a check against the **current** user's rights. The actual cloud-language check in `NOVADESK_DEV` rejects the addition `FOR USER`. No released in-process API for an equivalent effective-right check was confirmed on this release. [SAP authorization basics](https://help.sap.com/docs/sap-btp-abap-environment/abap-environment/authorization-basics)
- SAP publishes an OData V4 integration for reading business roles and their assigned users and catalogs. That documentation does not establish an answer equivalent to checking `ZNVD_AGT`, activity `02` and the concrete `ZNVD_TEAM` value for another user. A role name or catalog assignment alone cannot establish the effective right. [SAP Business Role - Read Integration](https://help.sap.com/docs/btp/sap-business-technology-platform/business-role-read-integration)
- SAP IAM evaluates activity and configured restrictions. A candidate external integration would need a documented source for the effective restriction values, supported authentication and provisioning, and a defined response to revocation and unavailability. [SAP authorization restrictions](https://help.sap.com/docs/sap-btp-abap-environment/abap-environment/restrictions-and-app-behavior)

## Alternatives

| Alternative | Enforcement and consequence |
| --- | --- |
| **Recommend manager proposal and acceptance by the target agent** | The manager starts a pending assignment for a verified ticket in a permitted team. Before committing the effective assignment, the target agent authenticates individually. RAP requires the target to match the proposal and checks the target's own `ZNVD_AGT` grant for that team with the normal `AUTHORITY-CHECK`. The server rechecks current team, active membership, ticket status, eligibility, proposal version and concurrent drafts at acceptance. A stale or unauthorized proposal cannot change the effective assignee. The workflow becomes two steps and needs explicit approval for the pending-assignment data and user flow. |
| **Administrative eligibility from a released authoritative integration** | Preserve one-step assignment only if a released SAP service exposes the effective target entitlement at team and activity level and the system can establish freshness and revocation semantics. The manager cannot edit the entitlement source through NovaDesk. Trial communication and permissions would need separate verification. No suitable integration contract has been confirmed. |
| **Keep direct assignment closed** | Preserve the current security contract while IAM integration remains unresolved. Membership, role names, technical-user impersonation and unreleased APIs are insufficient to enable assignment. |

The recommended decision is to approve the two-step assignment flow if one-step assignment cannot be supported through a released effective-entitlement interface. A pending proposal must have its own narrow access rule for a named, authenticated target. That access must not expose the existing ticket, its attachments, or its internal notes before acceptance. No alternative has been implemented in the active service.

## Trial acceptance identities

The seven agreed identities are two Requesters, two Agents in different teams, one Manager, one Admin and one identity without NovaDesk rights. Each must have a separate login and appropriately restricted business-role grants. Do not use shared sessions or include the developer test catalog. No independent identities were created or verified for this step. [SAP business-user maintenance](https://help.sap.com/docs/btp/sap-business-technology-platform/how-to-maintain-business-users)
