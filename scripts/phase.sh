#!/usr/bin/env bash
set -u

# phase.sh — 三环螺旋模型阶段管理
#
# Usage:
#   scripts/phase.sh set <phase> <next_cmd> <hint> [description]
#   scripts/phase.sh get           # 输出当前阶段名
#   scripts/phase.sh status        # 格式化输出完整状态
#   scripts/phase.sh next          # 输出下一步命令
#   scripts/phase.sh clear         # 重置（无阶段）
#
# Phase transitions:
#   aligned → researched → planned → validated → implementing

PHASE_FILE=".claude/phase"

ensure_dir() {
    mkdir -p "$(dirname "$PHASE_FILE")"
}

set_phase() {
    local phase="$1"
    local next_cmd="$2"
    local hint="$3"
    local description="${4:-}"
    ensure_dir
    cat > "$PHASE_FILE" <<-EOF
	phase=${phase}
	next=${next_cmd}
	hint=${hint}
	ts=$(date +%s)
	EOF
    if [[ -n "$description" ]]; then
        echo "description=${description}" >> "$PHASE_FILE"
    fi
}

get_phase() {
    if [[ -f "$PHASE_FILE" ]]; then
        grep -E '^phase=' "$PHASE_FILE" | cut -d= -f2-
    fi
}

show_status() {
    if [[ ! -f "$PHASE_FILE" ]]; then
        echo "当前未处于任何阶段"
        echo "启动流程: /grill-with-docs 或 /grill-me"
        return
    fi
    local phase next_cmd hint ts description
    phase=$(grep -E '^phase=' "$PHASE_FILE" | cut -d= -f2-)
    next_cmd=$(grep -E '^next=' "$PHASE_FILE" | cut -d= -f2-)
    hint=$(grep -E '^hint=' "$PHASE_FILE" | cut -d= -f2-)
    ts=$(grep -E '^ts=' "$PHASE_FILE" | cut -d= -f2-)
    description=$(grep -E '^description=' "$PHASE_FILE" | cut -d= -f2- || true)

    echo "┌─ 三环螺旋模型 阶段状态 ─────────────────────┐"
    if [[ -n "$description" ]]; then
        printf "│  当前阶段: %-30s │\n" "${description} (${phase})"
    else
        printf "│  当前阶段: %-30s │\n" "${phase}"
    fi
    if [[ -n "$ts" ]]; then
        local time_str
        time_str=$(date -r "$ts" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "unknown")
        printf "│  开始于:   %-30s │\n" "${time_str}"
    fi
    if [[ -n "$next_cmd" && "$next_cmd" != "-" ]]; then
        printf "│  ${GREEN}下一步:%-11s %-24s${NC} │\n" "" "${next_cmd}"
    fi
    if [[ -n "$hint" && "$hint" != "-" ]]; then
        printf "│  ${YELLOW}提示:%-13s %-24s${NC} │\n" "" "${hint}"
    fi
    echo "└────────────────────────────────────────────┘"
}

cmd_get() { get_phase; }
cmd_next() {
    if [[ -f "$PHASE_FILE" ]]; then
        grep -E '^next=' "$PHASE_FILE" | cut -d= -f2-
    fi
}
cmd_clear() { rm -f "$PHASE_FILE"; }

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

case "${1:-}" in
    set)
        if [[ $# -lt 4 ]]; then
            echo "Usage: $0 set <phase> <next_cmd> <hint> [description]" >&2
            exit 1
        fi
        set_phase "$2" "$3" "$4" "${5:-}"
        ;;
    get)    cmd_get ;;
    status) show_status ;;
    next)   cmd_next ;;
    clear)  cmd_clear ;;
    *)
        echo "Usage: $0 {set|get|status|next|clear}" >&2
        exit 1
        ;;
esac
