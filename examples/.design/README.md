# `.design/` — conforming example & test fixture

This is a **real, schema-valid example** of the [`.design/` artifact format](../../skills/design-from-code/references/artifact-format.md) — the format the `design-from-code` skill writes when it produces a design. It doubles as the **test fixture** that `verify.sh` validates, so the format spec can never silently drift from a working example.

```
.design/
  index.json            # derived rollup + global timeline
  issue-976/
    meta.json           # the contract: status, versions[], decisions[], dataModel[], direction, asIs
    v5.html             # the actual mockup (open it in a browser)
```

`v5.html` is the same artifact shown at the repo root — the faithful AS-IS / TO-BE / empty-state mockup the skill produced for issue #976.

## What `verify.sh` checks here

- `index.json` and every `*/meta.json` are valid JSON with `schemaVersion: 1`
- each `meta.json` has the required fields (`slug`, `title`, `status`, non-empty `versions[]`)
- `slug` matches its folder, and every `versions[].file` actually exists
- `index.json` has `subjects[]` + `events[]`, and each subject points to a real folder

A viewer (built separately) consumes exactly this layout — see the consumer contract in the format spec.
