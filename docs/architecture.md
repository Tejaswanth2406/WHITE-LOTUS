# Architecture

White Lotus follows a local-first architecture. The application is intentionally split into presentation, application logic, local services, and a future sync interface so that cloud features can be added without contaminating core workflows.

## Layers

- Presentation layer: Command Center, Vault, Search, Settings, Device UI
- Application core: navigation, state management, use cases, permissions, domain models
- Local services: SQLite, file system, secure local settings
- Sync interface: queue, tracking, conflict resolution
- Future cloud adapter: auth, APIs, object storage, backup, device management

The sync boundary is intentionally isolated. Until remote services exist, the app behaves as local-first and clearly marks synchronization as unavailable.
