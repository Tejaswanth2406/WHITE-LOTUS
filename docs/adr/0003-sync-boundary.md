# ADR 0003: Keep sync behind a clear abstraction

- Status: accepted
- Date: 2026-10-24

## Context

The product roadmap includes device and backup synchronization, but the app must not pretend that sync exists before the backend is ready.

## Decision

Create a sync interface boundary and start with a disabled engine that reports synchronization as unavailable.

## Consequences

- Local workflows remain honest and testable
- Future cloud features can be introduced as a specific integration layer
- The UI clearly distinguishes local data from synchronized state
