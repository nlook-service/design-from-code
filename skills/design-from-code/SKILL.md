---
name: design-from-code
description: Workflow skill that turns one issue/requirement into a design in the order "verify real code & data → iterate faithful HTML mockups → design doc (.md) → delegate implementation." When designing a change to existing UI, it reads the actual component source and data model instead of imagining them, and reproduces the current screen pixel-for-pixel. Triggers (EN) "design this", "make a mockup", "how should this feature look", "add ~ to the existing screen"; (KO) "설계해줘", "시안 만들어줘", "이 기능 어떻게 보여줄지", "기존 화면에 ~ 추가".
---

# design-from-code — design mockups grounded in real source

> One line: **lock facts with code → agree via HTML → nail it in a `.md` → ship by delegating.**
> The key difference: mockups are not *imagined*. They are reproduced down to the pixel and the number by **reading the real component JSX and data queries.**

## When to use

- Designing a change that **adds or modifies something** in an existing screen/component (e.g. "add a metrics card to the bottom bar")
- **UI re-layout / emphasis** requests like "it's hard to see / I want it shown like this"
- Exposing data (numbers, stats) on screen when you need to **pin down exactly what each number counts**
- When the user says "mockup first / show me in HTML"

## When NOT to use

- Pure backend/CLI work, changes with no UI
- A simple, already-agreed bug fix (no mockup needed)

## Core principles (these override every other decision)

1. **No guessing — read the code.** "How does this stat work?" is wrong ~100% of the time if you imagine it. Trace handler→query→schema all the way down, confirm it as *fact*, then design. → `references/data-model-verification.md`
2. **Reproduce the real component faithfully.** Before any new mockup, draw the **current state (AS-IS) exactly as the real JSX renders it**. Schematic drawings cause misunderstandings. **Don't reproduce from a glance** — a rough AS-IS guarantees a wrong TO-BE; confirm it with the fidelity self-check before moving on. → `references/code-fidelity-reproduction.md` (★ the heart of this skill)
3. **Pictures over prose.** Iterate with self-contained HTML you can see and fix. Bump the version (v2, v3…) on every round of feedback. → `references/html-mockup-recipe.md`
4. **Confirm one decision at a time.** "A vs B?" → "7-day window?" → "monotone color?" — ask narrowly.
5. **Mark keep / new / changed.** When "leave the rest as-is" is a requirement, use 🟦keep / 🟩new / 🟨changed color tags to show what you are *not* touching.
6. **Empty / initial state is first-class.** Always design the data-zero (new user) screen alongside the populated one.
7. **Delegate the build, but verification is mandatory.** Close it out with build / type-check / tests.
8. **Check for source before promising fidelity.** First confirm enough real code exists to read (Step 0). If it doesn't, say so and downgrade to a clearly-labeled proposal — don't pretend to reproduce something that isn't there.
9. **Ground the look — don't default to AI decoration.** What's firm: never invent a generic AI aesthetic. Anchor every mockup to something real — the product's actual tokens/components (you already read them), a reference the user gives, or a named style — and if a *new* look is wanted but no reference exists, **ask for one** rather than inventing it. With nothing supplied, fall back to the restraint guardrail (no emoji-icons, no gradient blobs, one semantic accent, hierarchy from scale not decoration). The *specific aesthetic* is the user's to direct and override; what doesn't bend is that it's grounded, not guessed. Record the choice in `meta.json.direction`. → `references/html-mockup-recipe.md` §0

## The 8-step workflow

> **Step 0 (gate) — does enough real source exist?** Before committing to full-fidelity mode, check that the code this design touches is actually readable. Locate the target component/screen and its data path (handler → query → schema). Then branch:
> - **Sufficient source found** → run all 8 steps as written (reproduce AS-IS, verify data to the schema).
> - **Partial** (component exists, data path is a black-box API / not yet built) → reproduce what you *can* read; for the rest, state it as an **assumption to confirm**, never as verified fact.
> - **None** (greenfield / empty repo / idea-only) → skip Steps 2–3 and 6 (nothing to map, verify, or reproduce); go straight to fresh mockups (4–5) and record every data meaning as a **defined-here spec**, flagged for the user to confirm.
>
> Announce which branch you're on in one line ("No existing component for this — designing fresh, assumptions flagged") so the user knows the output's fidelity up front. Never fabricate a fake "current screen" to fill the gap.

| # | Step | Key tools | Detail |
|---|------|-----------|--------|
| 0 | **Source-availability check** | `Agent(Explore)` / `Bash` (grep) | Confirm the target code + data path are readable; pick the branch above |
| 1 | Read the issue verbatim | `Bash` + `gh issue view` | Don't open GitHub via WebFetch (auth fails) |
| 2 | Map the code | `Agent(Explore)` ×N | Get just the conclusions for related components/hooks/schema |
| 3 | **Verify the data** | `Bash` (grep/sed) + Explore | handler→use-case→repository→schema. `references/data-model-verification.md` |
| 4 | HTML mockup v1 | `Write` (.html) + `SendUserFile` | Write to `.design/<slug>/v1.html` + create `meta.json`. Phone frame, 2–3 options, per-state, inline SVG. `references/html-mockup-recipe.md`, `references/artifact-format.md` |
| 5 | User confirmation | reply / `AskUserQuestion` | Confirm one at a time; add `vN.html` + a `versions[]` entry per round |
| 6 | **Faithful AS-IS/TO-BE** | `Bash` (read JSX with sed) + `Write` | Extract real render fns/classes/labels → HTML in the same folder. **Run the fidelity self-check before TO-BE** (re-diff vs source always; screenshot-compare when the app can render). `references/code-fidelity-reproduction.md` |
| 7 | Design doc `.md` | `Write` | `.design/<slug>/design.md` + set `status`/`build` in `meta.json`. Approved mockup + verified data model + build entry points + phases |
| 8 | Delegate + verify | `Agent` (language expert) + direct | Delegate with the contract & verify commands baked in; close with build/tests |

## Output contract — persist to `.design/`

Every mockup and its planning history is written to a portable, tool-agnostic format so the design *outlives the
session* and any viewer can render it. Don't keep artifacts only in chat: write each version to
`.design/<slug>/vN.html`, and record the decisions, verified data meanings, and version history in `meta.json`.
This is the federation point — the skill produces the format; a separate **viewer/spec tool reads it** (gallery +
timeline). Full spec, schema, and index/timeline model: → `references/artifact-format.md`.

## Reference files

- `references/artifact-format.md` — **the `.design/` output format**: `meta.json` schema, derived `index.json`, and the two-layer timeline (per-version + global). The contract between this skill, other producers, and any viewer.
- `references/code-fidelity-reproduction.md` — **★ concrete technique for reading the real component with sed and reproducing it 1:1 in HTML** (worked `renderSeg` example)
- `references/data-model-verification.md` — how to trace the data model all the way down (events-table username-attribution example)
- `references/html-mockup-recipe.md` — recipe for self-contained HTML (phone frame, inline-SVG charts, design tokens, empty state)
- `references/prompt-templates.md` — copy-paste prompts for each step
- `examples/issue-976-walkthrough.md` — the full flow of a real case (v1→v5, including the point where the user corrected "top/bottom is reversed")

## Common mistakes (checklist)

- [ ] Wrote data behavior from a **guess** → did you confirm it in code?
- [ ] Mockup is **schematic** so it differs from reality → did you read the real JSX and reproduce classes & labels?
- [ ] Asked several decisions at once and caused confusion → did you confirm one at a time?
- [ ] "Keep existing" was the requirement but it's unclear what stays untouched → did you add keep/new/changed tags?
- [ ] Forgot the empty / initial state (data-zero) → did you include the empty-state design?
- [ ] Pulled in a chart library for the graph → did you use inline SVG instead?
- [ ] Skipped build/type-check after implementing → did you close it out with verification commands?
- [ ] Mockup looks **AI-generic** (emoji-icons, gradient blobs, icon soup, rainbow accents) → did you match real product tokens / a reference, or fall back to the restraint guardrail and record `direction`?
