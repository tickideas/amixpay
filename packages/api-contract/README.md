# @amixpay/api-contract

Shared API contract between the backend and mobile app.

## Purpose

This package will hold:

- **OpenAPI 3.1 specification** — single source of truth for all API endpoints
- **JSON Schema definitions** — request/response types shared between Node.js and Dart
- **Generated types** — auto-generated TypeScript types (API) and Dart models (mobile)

## Status

🚧 **Coming soon** — currently the API contract is implicit (defined by Express routes and consumed by Dio in Flutter). This package will formalize it.

## Planned workflow

```
1. Edit openapi.yaml
2. Run codegen:
   - npm run generate:ts   → apps/api/src/types/
   - npm run generate:dart → apps/mobile/lib/core/api/
3. Both apps get type-safe, in-sync API definitions
```
