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
