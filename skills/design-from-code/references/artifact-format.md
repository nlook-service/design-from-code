# `.design/` artifact format (v1)

> A portable, tool-agnostic format for **persisting design artifacts and their planning history** so that
> (1) any viewer can render a gallery/timeline without knowing this skill, and
> (2) the AI can re-read past designs as grounded context for the next one.
>
> This spec is **independent of `design-from-code`**. Other skills, scripts, or projects may produce or
> consume it. The skill is the *method*; this format is the *contract* between method, data, and viewer.

## Why this exists

Keep three things separated:

- **Method** (how to design) → the skill's markdown. Stateless, shareable, loaded into context.
- **Data** (the designs + decisions + verified facts) → `.design/`. Grows per project. Lives in the consuming repo.
- **Viewer** (the "spec tool" UI) → a separate program that only reads `.design/`.

The valuable, reusable asset is the **metadata** — what each version changed, which decision was made and why,
what each number actually counts. The viewer is convenience on top; the metadata is what feeds back into the AI.

## Directory layout

Written into the **consuming project** (not the skill repo), one folder per design subject:

```
.design/
  index.json                  # DERIVED rollup + global timeline (generated, never hand-edited)
  <slug>/                     # e.g. issue-976, bottom-bar-metrics
    meta.json                 # REQUIRED — the contract (schema below)
    design.md                 # the Step-7 design doc (optional but recommended)
    v1.html  v2.html  …        # the mockups, one file per iteration
    v1.png   v2.png  …         # optional screenshots/thumbnails for the viewer
```

- `<slug>` is kebab-case and stable. Prefer `issue-<n>` when there's a tracker ref, else a short feature name.
- `meta.json` is the **only hand-written source of truth**. `index.json` is **derived** from all `meta.json`
  files (see "Index & timeline" below) — regenerate it, never edit it by hand.

## `meta.json` schema

```jsonc
{
  "schemaVersion": 1,
  "slug": "issue-976",
  "title": "Bottom bar: brand status metrics card",
  "source": { "type": "issue", "ref": "976", "url": "https://github.com/owner/repo/issues/976" },
  "status": "approved",          // draft | in-review | approved | shipped | abandoned
  "fidelity": "full",            // full | partial | fresh  (mirrors the skill's Step-0 branch)
  "createdAt": "2026-06-21",
  "updatedAt": "2026-06-21",
  "tags": ["mobile", "dashboard"],

  "direction": {                 // the visual direction this design follows (anti-"AI look" record)
    "source": "product-tokens",  // product-tokens | reference | named-style | restraint-default
    "note": "reuse themes.css + existing BottomBar component set",
    "references": ["https://…/inspo.png"]   // optional: screenshots/URLs the user supplied
  },

  "asIs": {                      // how the AS-IS (before) was confirmed — the TO-BE is only as good as this
    "verified": "source-diff",   // source-diff | screenshot | both | none
    "selfChecked": true,         // did the fidelity self-check pass before TO-BE was drawn?
    "component": "src/components/mobile/MobileBottomBar.tsx"
  },

  "versions": [
    {
      "v": 1,
      "file": "v1.html",
      "screenshot": "v1.png",    // optional
      "date": "2026-06-21",
      "summary": "First pass, 3 layout options",
      "feedback": "User: top/bottom is reversed",   // what triggered the next version
      "decisions": ["chose option B (card above the fold)"]
    },
    { "v": 5, "file": "v5.html", "date": "2026-06-21", "summary": "Final: monotone, 7-day window" }
  ],

  "decisions": [                 // cumulative, the ones that survived
    { "q": "A vs B layout?", "choice": "B", "why": "keeps the existing nav untouched" },
    { "q": "time window?",   "choice": "7 days" }
  ],

  "dataModel": [                 // verified meanings — the anti-guessing record
    {
      "field": "activeBrands",
      "means": "distinct brand_id with >=1 event in the last 7 days",
      "source": "src/server/usecases/brandStatus.ts:42 → brandRepo.countActive()"
    }
  ],

  "build": {                     // hand-off contract for implementation
    "entryPoints": ["src/components/BottomBar.tsx"],
    "verify": ["pnpm build", "pnpm test bottom-bar"]
  }
}
```

### Field reference

| Field | Required | Purpose |
|---|---|---|
| `schemaVersion` | ✓ | This format's version. Bump only on breaking change. Consumers must tolerate unknown fields. |
| `slug` | ✓ | Stable folder id. |
| `title` | ✓ | Human label for the gallery. |
| `source` | – | Where the request came from (`issue` / `idea` / `adhoc`) + ref/url. |
| `status` | ✓ | Lifecycle. Drives filtering/badges in the viewer. |
| `fidelity` | ✓ | `full`/`partial`/`fresh` — **mirrors Step 0**, so the viewer can label how trustworthy the mockup is. |
| `createdAt`/`updatedAt` | ✓ | ISO `YYYY-MM-DD`. Get real dates with `date +%F`, never invent them. |
| `direction` | – | The visual direction (product tokens / user reference / named style / restraint default). Persists the look so it isn't re-guessed. See `html-mockup-recipe.md` §0. |
| `asIs` | – | How the AS-IS was confirmed (`source-diff`/`screenshot`/`both`) and whether the fidelity self-check passed. A wrong AS-IS = a wrong TO-BE, so this records the before's trust level. See `code-fidelity-reproduction.md` §6. |
| `versions[]` | ✓ | The iteration history (v1→vN) with what changed and the feedback that drove each step. |
| `decisions[]` | – | The narrow, one-at-a-time choices that survived — the *why* behind the final design. |
| `dataModel[]` | – | Verified meaning of each number + the source path it was confirmed from. The anti-guessing ledger. |
| `build` | – | Entry points + verify commands for the delegated implementation. |

## Index & timeline (derived)

There are **two layers of time**:

1. **Per-subject (micro):** `meta.json.versions[]` — the v1→vN iteration history of one design.
2. **Global (macro):** `index.json.events[]` — one activity feed across *all* subjects.

`index.json` is **generated by scanning every `\.design/*/meta.json`** — by the viewer, a small script, or a
slash command. Never maintain it by hand; regenerate it so it can't drift from the `meta.json` truth.
Committing it is optional but handy: the AI can load this one file to recall the whole design history at a glance.

```jsonc
{
  "schemaVersion": 1,
  "generatedAt": "2026-06-21T09:30:00Z",
  "subjects": [
    {
      "slug": "issue-976",
      "title": "Bottom bar: brand status metrics card",
      "status": "approved",
      "fidelity": "full",
      "updatedAt": "2026-06-21",
      "latestVersion": 5,
      "versionCount": 5,
      "thumb": "issue-976/v5.png"
    }
  ],
  "events": [                    // flattened from every subject, sorted newest-first
    { "ts": "2026-06-21", "slug": "issue-976", "type": "status",  "to": "approved" },
    { "ts": "2026-06-21", "slug": "issue-976", "type": "version", "v": 5 },
    { "ts": "2026-06-21", "slug": "issue-976", "type": "created" }
  ]
}
```

- `subjects[]` = card grid for the gallery (sort by `updatedAt`).
- `events[]` = the chronological feed / timeline. `type` ∈ `created | version | status | shipped | abandoned`.
- Derivation rule: `created` from `meta.createdAt`; one `version` event per `versions[]` entry (`ts = version.date`);
  `status`/`shipped`/`abandoned` from `meta.status` transitions (use `updatedAt` when no per-event date exists).

## Producer rules (what the skill writes, and when)

- **Step 4 (first mockup):** create `\.design/<slug>/`, write `v1.html`, write `meta.json` with `versions:[{v:1,…}]`.
- **Every feedback round (Step 5):** add `vN.html` and append a `versions[]` entry. Record the `feedback` that caused it on the *previous* entry. Bump `updatedAt`.
- **Step 6 (AS-IS/TO-BE):** these HTMLs go in the same folder as additional versions or `as-is.html` / `to-be.html`.
- **Step 3 verification:** every fact you confirm goes into `dataModel[]` with its `source` path — this is the same record you'd otherwise lose after the session.
- **Step 7:** write `design.md` into the folder and set `status`, `build`.
- **Dates:** always real (`date +%F`). **Never** fabricate timestamps.
- Keep `meta.json` the single source of truth; don't duplicate it into a central index.

## Consumer contract (for the viewer, built elsewhere)

- Discover subjects: glob `\.design/*/meta.json`. Sort by `updatedAt`.
- Render: title + status badge + fidelity badge; open `versions[].file` in an iframe; show `decisions[]` and `dataModel[]` as the "spec" panel; use `versions[].summary/feedback` as a timeline.
- **Tolerate unknown fields and missing optional fields.** Only `schemaVersion`, `slug`, `title`, `status`, `versions[].file` are guaranteed.
- Treat the directory as read-only; never write back into a producer's folder.

## Reuse beyond this skill

Any other skill/tool can adopt `.design/` by writing a conforming `meta.json`. That is the federation point:
producers vary, the format is fixed, one viewer reads them all.
