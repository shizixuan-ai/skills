#!/usr/bin/env bash
set -uo pipefail

# architecture-scan.sh
# Lightweight architecture health scan for the outer ring of the spiral model.
# Use as a pre-push hook or CI check.
#
# Returns:
#   0 — PASS (no issues)
#   1 — WARNING (minor issues, suggest review)
#   2 — FAIL (significant issues, recommend improve-codebase-architecture)

# ── Config ──────────────────────────────────────────────────────────
MAX_FILE_LINES="${MAX_FILE_LINES:-500}"
BASE_REF="${1:-origin/main}"
SCAN_DIR="${2:-.}"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

ISSUES_FOUND=0
WARNINGS_FOUND=0
PASS_COUNT=0

# ── Helpers ─────────────────────────────────────────────────────────
pass()  { echo -e "  ${GREEN}✓${NC} $1"; ((PASS_COUNT++)); }
warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; ((WARNINGS_FOUND++)); }
fail()  { echo -e "  ${RED}✗${NC} $1"; ((ISSUES_FOUND++)); }

header() { echo -e "\n${BOLD}── $1 ──${NC}"; }

# ── Checks ──────────────────────────────────────────────────────────

echo -e "${BOLD}ARCHITECTURE SCAN${NC}"
echo "  Base ref: ${BASE_REF}"
echo "  Max file lines: ${MAX_FILE_LINES}"
echo "  Dir: ${SCAN_DIR}"

# Check 1: File size — flag files over threshold
header "File Size"
while IFS= read -r -d '' file; do
    lines=$(wc -l < "$file")
    if (( lines > MAX_FILE_LINES )); then
        fail "${file#$SCAN_DIR/}: ${lines} lines (limit: ${MAX_FILE_LINES})"
    fi
done < <(find "$SCAN_DIR" \( -name '*.go' -o -name '*.ts' -o -name '*.tsx' \
    -o -name '*.py' -o -name '*.rs' -o -name '*.js' -o -name '*.jsx' \
    -o -name '*.vue' -o -name '*.css' -o -name '*.scss' \) \
    ! -path '*/node_modules/*' ! -path '*/vendor/*' ! -path '*/dist/*' \
    ! -path '*/.git/*' ! -path '*/target/*' ! -path '*/build/*' \
    -type f -print0 2>/dev/null)
if (( ISSUES_FOUND == 0 )); then
    pass "No files exceed ${MAX_FILE_LINES} lines"
fi

# Check 2: TODO/FIXME/HACK without ticket reference — tech debt markers
header "Tech Debt Markers"
found_debt=0
while IFS= read -r line; do
    file="${line%%:*}"
    content="${line#*:}"
    # Skip if has a ticket reference like PROJ-123 or [#123] or (issue 123)
    if ! echo "$content" | grep -qiE '(proj-[0-9]+|#[0-9]+|issue [0-9]+|TODO|FIXME|HACK)'; then
        # Check if it actually contains TODO/FIXME/HACK without ticket
        if echo "$content" | grep -qiE '(TODO|FIXME|HACK)'; then
            warn "${file#$SCAN_DIR/}: missing ticket reference"
            ((found_debt++))
        fi
    fi
done < <(git -C "$SCAN_DIR" diff "$BASE_REF"..HEAD --diff-filter=ACMR \
    -G '(TODO|FIXME|HACK)' -U0 -- . 2>/dev/null | grep -E '^\+.*(TODO|FIXME|HACK)' || true)
# Also scan for new bare TODOs in staged files
while IFS= read -r line; do
    file="${line%%:*}"
    content="${line#*:}"
    if echo "$content" | grep -qiE '(TODO|FIXME|HACK)' && \
       ! echo "$content" | grep -qiE '(proj-[0-9]+|#[0-9]+)'; then
        warn "${file#$SCAN_DIR/}: missing ticket reference"
        ((found_debt++))
    fi
done < <(git -C "$SCAN_DIR" diff --cached --diff-filter=ACMR \
    -G '(TODO|FIXME|HACK)' -U0 -- . 2>/dev/null | grep -E '^\+.*(TODO|FIXME|HACK)' || true)

if (( found_debt == 0 )); then
    pass "No untracked tech debt markers"
fi

# Check 3: Module boundary — new files outside expected directories
header "Module Boundaries"
if git -C "$SCAN_DIR" rev-parse "$BASE_REF" >/dev/null 2>&1; then
    new_files=$(git -C "$SCAN_DIR" diff "$BASE_REF"..HEAD --diff-filter=A \
        --name-only -- . 2>/dev/null | grep -E '\.(go|ts|tsx|py|rs|js|vue)$' || true)

    if [[ -n "$new_files" ]]; then
        # Known module directories (heuristic: top-level dirs with source files)
        known_modules=$(find "$SCAN_DIR" -maxdepth 2 -type d \
            ! -path '*/node_modules/*' ! -path '*/.git/*' ! -path '*/vendor/*' \
            ! -path '*/dist/*' ! -path '*/target/*' ! -path '*/build/*' \
            ! -path '*/.*' \
            | grep -vE '\.' | sort -u || true)

        boundary_issues=0
        while IFS= read -r file; do
            # Check if file is in a known module directory
            dir=$(dirname "$file")
            found=0
            while IFS= read -r mod; do
                mod_rel="${mod#$SCAN_DIR/}"
                if [[ "$dir" == "$mod_rel" || "$dir" == "$mod_rel"/* ]]; then
                    found=1
                    break
                fi
            done <<< "$known_modules"
            if (( found == 0 )); then
                warn "New file outside known modules: ${file}"
                ((boundary_issues++))
            fi
        done <<< "$new_files"

        if (( boundary_issues == 0 )); then
            pass "All new files within known module boundaries"
        fi
    else
        pass "No new source files in this diff"
    fi
else
    pass "Base ref ${BASE_REF} not found — skipping boundary check"
fi

# Check 4: CONTEXT.md staleness — check if it was updated in this branch
header "Domain Glossary"
if git -C "$SCAN_DIR" rev-parse "$BASE_REF" >/dev/null 2>&1; then
    if git -C "$SCAN_DIR" diff "$BASE_REF"..HEAD --name-only -- CONTEXT.md 2>/dev/null | grep -q CONTEXT.md; then
        pass "CONTEXT.md was updated in this branch"
    else
        # Check if new domain-like terms were introduced
        new_terms=$(git -C "$SCAN_DIR" diff "$BASE_REF"..HEAD \
            --diff-filter=ACMR -G '^[a-z]+([A-Z][a-z]+)+' -U0 -- . 2>/dev/null \
            | grep -E '^\+' | grep -oE '[a-z]+([A-Z][a-z]+)+' | sort -u | head -5 || true)
        if [[ -n "$new_terms" ]]; then
            warn "New terms found but CONTEXT.md not updated: ${new_terms}"
        else
            pass "No new domain terms detected"
        fi
    fi
else
    pass "Base ref ${BASE_REF} not found — skipping CONTEXT.md staleness check"
fi

# Check 5: Breadth of change — how many modules were touched
header "Change Breadth"
if git -C "$SCAN_DIR" rev-parse "$BASE_REF" >/dev/null 2>&1; then
    changed_dirs=$(git -C "$SCAN_DIR" diff "$BASE_REF"..HEAD --name-only \
        -- . 2>/dev/null | grep -E '\.(go|ts|tsx|py|rs|js|vue)$' \
        | xargs -I {} dirname {} | sort -u | wc -l | tr -d ' ')
    if (( changed_dirs > 8 )); then
        warn "Touch ${changed_dirs} modules in one branch (consider splitting)"
    elif (( changed_dirs > 4 )); then
        warn "Touch ${changed_dirs} modules — verify this change is cohesive"
    else
        pass "Change touches ${changed_dirs} module(s) — cohesive"
    fi
fi

# ── Summary ─────────────────────────────────────────────────────────

echo -e "\n${BOLD}──────────────────────────────────────────────${NC}"
if (( ISSUES_FOUND > 0 )); then
    echo -e "${BOLD}Result: ${RED}FAIL${NC} (${ISSUES_FOUND} issues, ${WARNINGS_FOUND} warnings)"
    echo -e "${YELLOW}Recommend running /improve-codebase-architecture before merging${NC}"
    exit 2
elif (( WARNINGS_FOUND > 0 )); then
    echo -e "${BOLD}Result: ${YELLOW}WARNING${NC} (${WARNINGS_FOUND} warnings)"
    echo -e "${YELLOW}Review warnings before merge. Consider /improve-codebase-architecture if patterns persist.${NC}"
    exit 1
else
    echo -e "${BOLD}Result: ${GREEN}PASS${NC} (${PASS_COUNT} checks passed)"
    exit 0
fi
