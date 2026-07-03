# ADR-006: Node.js 22 Runtime Migration

## Status
Accepted

## Context
Tremble previously ran Cloud Functions on Node.js 20. Node.js 22 is now the project runtime for long-term support (LTS) longevity and performance. Continuing with Node.js 20 would introduce technical debt as the version approaches its end-of-life.

## Decision
All 19 Cloud Functions in the Tremble Interaction System have been migrated to the **Node.js 22** runtime.

## Consequences
- **Deployment**: `package.json` must specify `"node": "22"` in the `engines` field.
- **Consistency**: All developers must run `npm ci` in the `functions/` directory to install from `package-lock.json` without lockfile drift.
- **Performance**: Improved cold start times and ES module support in the Node.js 22 environment.
