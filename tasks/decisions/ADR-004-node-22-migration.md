# ADR-004: Node.js 22 Runtime Migration

## Status
Accepted

## Context
Firebase Cloud Functions currently support Node.js 20 as the default stable runtime. However, Node.js 22 is now available and recommended for long-term support (LTS) longevity and performance improvements. Continuing with Node.js 20 would introduce technical debt as the version approaches its end-of-life.

## Decision
All 19 Cloud Functions in the Tremble Interaction System have been migrated to the **Node.js 22** runtime.

## Consequences
- **Deployment**: `package.json` must specify `"node": "22"` in the `engines` field.
- **Consistency**: All developers must run `npm install` in the `functions/` directory to ensure metadata consistency in `package-lock.json`.
- **Performance**: Improved cold start times and ES module support in the Node.js 22 environment.
