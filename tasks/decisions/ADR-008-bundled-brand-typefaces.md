# ADR-008: Bundled Brand Typefaces

Date: 2026-07-16

## Status

Accepted

## Context

`main()` awaited `GoogleFonts.pendingFonts([...])` before `runApp`. That call
downloads each typeface over HTTP on first launch. On a slow connection it
stalled startup behind the network; on a bad one it produced the production
Android crash `Failed to load font with url`. A dating app whose first launch
depends on a CDN being reachable is a launch risk, and the failure lands on
exactly the users with the worst connectivity.

The `google_fonts` package can resolve from bundled assets instead, which
raises three questions this ADR settles: where the files live, which variants
ship, and what happens when one is missing.

Three findings from reading `google_fonts` 8.0.2 rather than assuming:

1. An asset matches when its path **ends with** the API filename prefix
   `<Family>-<Variant>` (`google_fonts_base.dart:329`). Any directory works, and
   no pubspec `fonts:` block is required.
2. A requested weight resolves to the family's **closest available** variant
   (`_closestMatch`, `google_fonts_base.dart:97`) — not the requested one.
3. With `allowRuntimeFetching = false`, a variant that is not bundled throws
   (`google_fonts_base.dart:178`). The throw is caught internally, so the text
   silently renders in a fallback typeface.

## Decision

Ship every variant of the four AGENTS.md contract families — Instrument Sans,
Playfair Display, Lora, JetBrains Mono — in `assets/fonts/` (44 files, 4.6 MB),
declare the directory in `pubspec.yaml`, and set
`GoogleFonts.config.allowRuntimeFetching = false` before the first font call.

All 363 `GoogleFonts.*` call sites stay unchanged; they resolve locally.

Files are fetched from the same `fonts.gstatic.com/s/a/<hash>.ttf` URLs the
package itself uses, via the hashes it embeds, so the bundled bytes are
identical to what the runtime download produced and rendering cannot shift.
`tool/fetch_fonts.py` regenerates the set and validates each file's length
against the package's expected value.

**No GoogleFonts family outside the contract four may be called** — it would
fetch at runtime and reintroduce the crash. A test enforces this.

## Alternatives Considered

- **Bundle only the weights currently called.** Rejected. Finding (2) means an
  audit of call sites does not describe the files needed: Instrument Sans ships
  no ExtraBold, so its `w800` sites resolve to Bold — the audited set would have
  chased a file that does not exist. Worse, `TrembleTheme.displayFont` /
  `bodyFont` / `uiFont` accept an arbitrary `FontWeight`, so no static audit
  stays correct as code changes. Combined with finding (3), being wrong is
  silent.
- **Drop `google_fonts` and declare a pubspec `fonts:` block.** Rejected:
  363 call sites would have to change, for no gain over bundled assets.
- **Keep runtime fetching with a longer timeout / retry.** Rejected: it keeps
  first launch coupled to a CDN.

## Consequences

- First launch renders brand type with the radio off. The startup HTTP await is
  gone.
- +4.6 MB of assets, against a 120 MB release budget.
- `GoogleFonts.inter` (4 call sites, never in the contract) moved to Instrument
  Sans. Deliberate visual change in the wave pill and the account-suspended
  screen.
- Adding a new family now requires bundling it — enforced by test, since the
  cost of forgetting is a crash for offline users.
- OFL requires the licence text to travel with the binaries: the four `OFL-*.txt`
  files ship in `assets/fonts/` and register via `LicenseRegistry`.
- Upgrading `google_fonts` could in principle change the filename convention or
  the variant list. The behavioural load test would catch it.
