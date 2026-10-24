# ADR 0002: Keep the app local-first

- Status: accepted
- Date: 2026-10-24

## Context

A personal command ecosystem must remain useful even when offline or when the remote backend is unavailable.

## Decision

All domain workflows and local persistence operate without cloud dependency.

## Consequences

- The core app remains functional without a network connection
- Sync is treated as an optional, explicit layer
- Remote data integration can evolve without breaking offline behavior
