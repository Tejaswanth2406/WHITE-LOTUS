# ADR 0001: Use Flutter for the shared app shell

- Status: accepted
- Date: 2026-10-24

## Context

The application must run on desktop and later expand to additional devices while preserving a shared user experience.

## Decision

Use Flutter + Dart as the shared UI foundation.

## Consequences

- One shared codebase for desktop and future mobile surfaces
- Clear separation between UI and local persistence boundaries
- Platform-specific adaptation remains necessary for file and installation behavior
