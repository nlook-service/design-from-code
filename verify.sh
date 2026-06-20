#!/usr/bin/env bash
# design-from-code — install & integrity check.
# Usage:  bash verify.sh
# Exit 0 if everything needed to use the skill is in place, 1 otherwise.

set -u
cd "$(dirname "$0")"

pass=0; fail=0
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  \033[31m✗\033[0m %s\n' "$1"; fail=$((fail+1)); }

echo "design-from-code · verification"
echo "--------------------------------"

SKILL="skills/design-from-code/SKILL.md"

# 1) Skill definition
echo "Skill definition"
[ -f "$SKILL" ] && ok "SKILL.md present" || no "SKILL.md missing"
if [ -f "$SKILL" ]; then
  head -1 "$SKILL" | grep -q '^---' && ok "has YAML frontmatter" || no "frontmatter missing"
  grep -q '^name: design-from-code$' "$SKILL" && ok "name matches folder" || no "name != design-from-code"
  grep -q '^description:' "$SKILL" && ok "description present (used for triggering)" || no "description missing"
  grep -q '설계' "$SKILL" && grep -qi 'design' "$SKILL" && ok "bilingual triggers (KO + EN)" || no "triggers not bilingual"
fi

# 2) Reference + example files the skill points to
echo "Referenced files"
for f in \
  skills/design-from-code/references/code-fidelity-reproduction.md \
  skills/design-from-code/references/data-model-verification.md \
  skills/design-from-code/references/html-mockup-recipe.md \
  skills/design-from-code/references/artifact-format.md \
  skills/design-from-code/references/prompt-templates.md \
  skills/design-from-code/examples/issue-976-walkthrough.md \
  examples/mobile-bottom-brand-status-v5.html ; do
  [ -f "$f" ] && ok "$(basename "$f")" || no "missing: $f"
done

# 3) Self-contained example (no external resources)
echo "Example artifact"
if [ -f examples/mobile-bottom-brand-status-v5.html ]; then
  n=$(grep -coiE 'src="https?://|<script|href="https?://[^"]*\.css' examples/mobile-bottom-brand-status-v5.html)
  [ "$n" -eq 0 ] && ok "example HTML is self-contained (0 external deps)" || no "example HTML pulls $n external resources"
fi

# 3b) Output-format fixture (.design/) — proves the artifact format is valid & openable
echo "Output-format example (.design/)"
DESIGN_ROOT="examples/.design"
if [ ! -d "$DESIGN_ROOT" ]; then
  no "missing example fixture: $DESIGN_ROOT/"
elif command -v python3 >/dev/null 2>&1; then
  if python3 - "$DESIGN_ROOT" <<'PY' 2>/dev/null
import json, os, sys
root = sys.argv[1]
errs = []

# index.json
ip = os.path.join(root, "index.json")
try:
    idx = json.load(open(ip))
    if idx.get("schemaVersion") != 1: errs.append("index.json schemaVersion != 1")
    if not idx.get("subjects"): errs.append("index.json has no subjects[]")
    if "events" not in idx: errs.append("index.json missing events[]")
    for s in idx.get("subjects", []):
        if not os.path.isdir(os.path.join(root, s.get("slug", ""))):
            errs.append("index subject points to missing folder: %s" % s.get("slug"))
except Exception as e:
    errs.append("index.json invalid: %s" % e)

# each subject meta.json
subjects = [d for d in os.listdir(root) if os.path.isdir(os.path.join(root, d))]
if not subjects: errs.append("no subject folders under .design/")
for slug in subjects:
    mp = os.path.join(root, slug, "meta.json")
    if not os.path.isfile(mp):
        errs.append("%s/meta.json missing" % slug); continue
    try:
        m = json.load(open(mp))
    except Exception as e:
        errs.append("%s/meta.json invalid: %s" % (slug, e)); continue
    if m.get("schemaVersion") != 1: errs.append("%s schemaVersion != 1" % slug)
    for k in ("slug", "title", "status"):
        if not m.get(k): errs.append("%s meta.json missing '%s'" % (slug, k))
    if m.get("slug") != slug: errs.append("%s meta.json slug mismatch (%s)" % (slug, m.get("slug")))
    vers = m.get("versions") or []
    if not vers: errs.append("%s has no versions[]" % slug)
    for v in vers:
        f = v.get("file", "")
        if not os.path.isfile(os.path.join(root, slug, f)):
            errs.append("%s version file missing: %s" % (slug, f))

if errs:
    print("\n".join(errs)); sys.exit(1)
sys.exit(0)
PY
  then
    ok ".design/ fixture is schema-valid (index + meta + version files)"
  else
    no ".design/ fixture failed schema validation (run: python3 with $DESIGN_ROOT)"
  fi
else
  [ -f "$DESIGN_ROOT/index.json" ] && ok ".design/ fixture present (install python3 for schema check)" \
    || no ".design/index.json missing"
fi

# 4) Plugin manifests (deep JSON check if python3 exists, else shallow)
echo "Plugin manifests"
for j in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  if [ ! -f "$j" ]; then no "missing: $j"; continue; fi
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import json,sys; json.load(open('$j'))" 2>/dev/null \
      && ok "$(basename "$j") valid JSON" || no "$(basename "$j") invalid JSON"
  else
    ok "$(basename "$j") present (install python3 for JSON check)"
  fi
done

# 5) Optional: is it installed for Claude Code / Codex?
echo "Installation (optional)"
checked=0
for d in "$HOME/.claude/skills/design-from-code" "$HOME/.codex/skills/design-from-code"; do
  if [ -e "$d" ]; then
    checked=1
    [ -f "$d/SKILL.md" ] && ok "installed & reachable: ${d/#$HOME/~}" || no "linked but SKILL.md unreachable: ${d/#$HOME/~}"
  fi
done
[ "$checked" -eq 0 ] && echo "  · not installed yet — see README ‘Install’ (this is fine before install)"

echo "--------------------------------"
if [ "$fail" -eq 0 ]; then
  printf '\033[32mPASS\033[0m — %d checks ok. The skill is ready to use.\n' "$pass"
  exit 0
else
  printf '\033[31mFAIL\033[0m — %d ok, %d problem(s) above.\n' "$pass" "$fail"
  exit 1
fi
