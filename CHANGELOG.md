# Changelog

All notable changes to **design-from-code**. This project adheres to [Semantic Versioning](https://semver.org).

## [1.1.0] — 2026-06-21

### Added
- **Portable `.design/` artifact format** — designs and their planning history now persist to a tool-agnostic format (`meta.json` schema, derived `index.json`, two-layer per-version + global timeline) so they outlive the session and any viewer can load them. → `references/artifact-format.md`
- **Anti-"AI look" guardrail** — restraint by default (no emoji-icons / gradient blobs / rainbow accents); ground each mockup in real product tokens, a user reference, or a named style. Fully overridable; recorded in `meta.direction`. → `html-mockup-recipe.md` §0
- **Mandatory AS-IS fidelity self-check** — a rough "before" guarantees a wrong "after", so the reproduction must pass a source-diff self-check before TO-BE; how it was verified is recorded in `meta.asIs`. → `code-fidelity-reproduction.md` §6
- **Conforming example fixture** at `examples/.design/`, schema-validated by `verify.sh`, so the format spec can't silently drift from a working example.

### Changed
- SKILL workflow steps 4–7 now write output to `.design/<slug>/`.
- `verify.sh` gained a `.design/` schema validator (now 18 checks).

### Notes
- No breaking changes. `.design/` outputs in your own projects are unaffected — they live in your repo, not in the skill.

## [1.0.0]

- Initial release: the 8-step design-from-code workflow (issue → code map → data verification → HTML mockup → confirm → faithful AS-IS/TO-BE → design doc → delegated build), reference guides, and a fully worked example (issue #976).
