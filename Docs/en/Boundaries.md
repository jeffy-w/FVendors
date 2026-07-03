# Module Boundaries

FVendors is a lightweight app infrastructure foundation, not a full app framework. Keep each target focused so apps can import only the surface they need.

## Target ownership

- `FVendorsModels`: shared values, domain errors, and cross-cutting enums.
- `FVendorsClients`: protocol-style client abstractions, request builders, wrappers, and test doubles.
- `FVendorsClientsLive`: production implementations and third-party adapters.
- `FVendorsExt`: optional SwiftUI/UIKit helpers.
- `FVendors`: core umbrella only. It re-exports Models + Clients + ClientsLive and must not re-export `FVendorsExt`.

## Enforced rules

`Scripts/check-boundaries.sh` is the CI canary for the most important boundaries. It fails when:

1. UI helper files return to `Sources/FVendors`.
2. `Sources/FVendors/FVendors.swift` re-exports `FVendorsExt`.
3. SwiftUI/UIKit code is added under `Sources/FVendors`.
4. The `FVendorsExt` SwiftPM product disappears or stops targeting `FVendorsExt`.
5. The `FVendors` target depends on anything outside `FVendorsModels`, `FVendorsClients`, and `FVendorsClientsLive`.
6. Hard-gated future client names enter package sources without an approved plan.

Run it locally before changing product boundaries:

```bash
Scripts/check-boundaries.sh
```

## Adding new capabilities

Prefer extending an existing client or adding a wrapper around it before introducing a new package-owned client. New package-owned APIs such as `EnvironmentClient`, `FeatureFlagClient`, `ReachabilityClient`, or `AuthTokenClient` require repeated Demo or real-app proof, test-friendly parity, focused tests, bilingual docs, and a module-boundary rationale.
