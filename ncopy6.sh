#!/usr/bin/env bash

# ==============================================================================
# NCOPY v6 - Multi-File / Module Tree Iteration Tool
# Developed for: هیناتا (Hinata)
# Features: Full 'src/' Tree Snapshots, Multi-file Reset, Rollback, Hash Tracking
# ==============================================================================

set -euo pipefail

# --- Configuration & Defaults ---
SCRIPT_NAME="$(basename -- "$0")"
DEFAULT_SOURCE_DIR="src"
DEFAULT_TEMPLATE_DIR="./template_src"
DEFAULT_SNAP_DIR="snapshots"
DEFAULT_LOG=".ncopy.log"

# --- State Variables ---
SOURCE_DIR="$DEFAULT_SOURCE_DIR"
TEMPLATE_DIR="$DEFAULT_TEMPLATE_DIR"
SNAP_DIR="$DEFAULT_SNAP_DIR"
LOG_NAME="$DEFAULT_LOG"

# --- Flags ---
DO_FMT=0
DO_CHECK=0
DO_GIT_CHECK=1
VERBOSE=0
DRY_RUN=0
FORCE=0

# --- Colors for TTY ---
if [[ -t 1 ]]; then
    C_RES='\033[0m'
    C_BOLD='\033[1m'
    C_RED='\033[31m'
    C_GRN='\033[32m'
    C_YLW='\033[33m'
    C_BLU='\033[34m'
else
    C_RES='' C_BOLD='' C_RED='' C_GRN='' C_YLW='' C_BLU=''
fi

# --- Helper Functions ---
info()    { printf "${C_BLU}[INFO]${C_RES} %s\n" "$1"; }
success() { printf "${C_GRN}[OK]${C_RES}   %s\n" "$1"; }
warn()    { printf "${C_YLW}[WARN]${C_RES} %s\n" "$1" >&2; }
error()   { printf "${C_RED}[ERR]${C_RES}  %s\n" "$1" >&2; }
die()     { error "$1"; exit 1; }

# --- System Checks ---
check_rust_env() {
    [[ -f "Cargo.toml" ]] || die "Not in a Rust project root (Cargo.toml missing)."
    [[ -d "$SOURCE_DIR" ]] || die "Source directory '$SOURCE_DIR' does not exist."
    
    if [[ "$DO_GIT_CHECK" -eq 1 && -d ".git" ]]; then
        if ! grep -qs "$SNAP_DIR" .gitignore 2>/dev/null; then
            warn "'$SNAP_DIR' is not in .gitignore. Snapshots might be tracked by Git."
        fi
    fi
}

get_tree_hash() {
    # محاسبه هش کلی تمام فایل‌های داخل دایرکتوری به صورت پایدار
    find "$1" -type f -exec sha256sum {} + | sort | sha256sum | awk '{print $1}'
}

log_event() {
    local msg="$1"
    local dir="${2:-}"
    local hash=""
    [[ -n "$dir" && -d "$dir" ]] && hash="$(get_tree_hash "$dir")"
    
    local entry="$(date '+%Y-%m-%d %H:%M:%S') | $msg ${hash:+[TREE_SHA:$hash]}"
    
    if [[ "$DRY_RUN" -eq 1 ]]; then
        info "[dry-run] Log entry: $entry"
    else
        mkdir -p -- "$SNAP_DIR"
        printf '%s\n' "$entry" >> "$SNAP_DIR/$LOG_NAME"
    fi
}

# --- Core Logic ---
get_next_index() {
    local max=0
    shopt -s nullglob
    for d in "$SNAP_DIR"/src_*; do
        local base=$(basename "$d")
        if [[ "$base" =~ ^src_([0-9]{3})_ ]]; then
            local idx=$((10#${BASH_REMATCH[1]}))
            (( idx > max )) && max=$idx
        fi
    done
    printf "%03d" $((max + 1))
}

create_snapshot() {
    local src="$1"
    local idx=$(get_next_index)
    local ts=$(date '+%Y%m%d_%H%M%S')
    local target="$SNAP_DIR/src_${idx}_${ts}"

    info "Creating tree snapshot #$idx for '$src'..."
    if [[ "$DRY_RUN" -eq 1 ]]; then
        info "[dry-run] cp -a $src $target"
    else
        mkdir -p -- "$SNAP_DIR"
        cp -a -- "$src" "$target"
        log_event "Snapshot created: $(basename "$target")" "$target"
        success "Directory tree saved: $target"
    fi
}

create_backup() {
    local src="$1"
    local ts=$(date '+%Y%m%d_%H%M%S')
    local bak=".${src}.bak.$ts"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        info "[dry-run] Backup $src -> $bak"
    else
        cp -a -- "$src" "$bak"
        log_event "Backup created: $bak" "$bak"
    fi
}

init_template_if_missing() {
    if [[ ! -d "$TEMPLATE_DIR" ]]; then
        info "Template directory '$TEMPLATE_DIR' not found. Creating a default multi-file template..."
        mkdir -p "$TEMPLATE_DIR"
        cat << 'EOF' > "$TEMPLATE_DIR/lib.rs"
pub fn hello_from_lib() {
    println!("Hello from modular lib.rs!");
}
EOF
        cat << 'EOF' > "$TEMPLATE_DIR/main.rs"
// Replaced dynamically by package name or used directly
fn main() {
    println!("Bootstrapping new exercise...");
}
EOF
        success "Created default template in '$TEMPLATE_DIR'."
    fi
}

perform_reset() {
    init_template_if_missing

    # مقایسه محتوای دایرکتوری سورس و قالب
    local current_hash=$(get_tree_hash "$SOURCE_DIR")
    local template_hash=$(get_tree_hash "$TEMPLATE_DIR")

    if [[ "$current_hash" == "$template_hash" ]]; then
        info "Source directory and Template are identical. Skipping reset."
        return 0
    fi

    create_backup "$SOURCE_DIR"
    
    info "Resetting $SOURCE_DIR/ from $TEMPLATE_DIR/..."
    if [[ "$DRY_RUN" -eq 1 ]]; then
        info "[dry-run] rm -rf $SOURCE_DIR/* && cp -a $TEMPLATE_DIR/* $SOURCE_DIR/"
    else
        rm -rf -- "$SOURCE_DIR"
        mkdir -p -- "$SOURCE_DIR"
        cp -a "$TEMPLATE_DIR"/. "$SOURCE_DIR"/
        log_event "Reset performed from $TEMPLATE_DIR" "$SOURCE_DIR"
        success "Reset complete. Clean multi-file structure ready."
    fi

    # Hooks
    [[ "$DO_FMT" -eq 1 ]] && { info "Running cargo fmt..."; cargo fmt || true; }
    [[ "$DO_CHECK" -eq 1 ]] && { info "Running cargo check..."; cargo check || warn "Cargo check failed!"; }
}

# --- Subcommands ---
cmd_run() {
    create_snapshot "$SOURCE_DIR"
    perform_reset
}

cmd_latest() {
    local last=$(ls -1d "$SNAP_DIR"/src_* 2>/dev/null | sort | tail -n 1)
    if [[ -z "$last" ]]; then
        warn "No snapshots found."
    else
        info "Latest snapshot directory: $last"
        if [[ "$VERBOSE" -eq 1 ]]; then
            printf "${C_BOLD}Files in snapshot:${C_RES}\n"
            find "$last" -maxdepth 3 -not -path '*/.*'
        fi
    fi
}

cmd_rollback() {
    local latest_bak=$(ls -1d .${SOURCE_DIR}.bak.* 2>/dev/null | sort | tail -n 1)
    [[ -z "$latest_bak" ]] && die "No backup directories found."
    
    info "Rolling back from backup $latest_bak..."
    if [[ "$DRY_RUN" -eq 1 ]]; then
        info "[dry-run] Restore $latest_bak -> $SOURCE_DIR"
    else
        rm -rf -- "$SOURCE_DIR"
        cp -a -- "$latest_bak" "$SOURCE_DIR"
        success "Rollback successful."
        log_event "Rollback from $latest_bak" "$SOURCE_DIR"
    fi
}

cmd_clean() {
    if [[ "$FORCE" -ne 1 ]]; then
        read -p "Are you sure you want to delete all snapshots and backups? (y/N) " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || die "Abort."
    fi
    rm -rf "$SNAP_DIR"/src_*
    rm -rf .${SOURCE_DIR}.bak.*
    success "Cleaned all directory snapshots and backups."
}

cmd_status() {
    printf "${C_BOLD}--- Multi-File Workflow Status ---${C_RES}\n"
    printf "Project Root  : %s\n" "$(pwd)"
    printf "Source Dir    : %s/ (Tree Hash: %s)\n" "$SOURCE_DIR" "$(get_tree_hash "$SOURCE_DIR")"
    if [[ -d "$TEMPLATE_DIR" ]]; then
        printf "Template Dir  : %s/ (Tree Hash: %s)\n" "$TEMPLATE_DIR" "$(get_tree_hash "$TEMPLATE_DIR")"
    else
        printf "Template Dir  : [Not yet initialized]\n"
    fi
    printf "Snapshots     : %s\n" "$(ls -1d "$SNAP_DIR"/src_* 2>/dev/null | wc -l)"
    
    if [[ -d ".git" ]]; then
        printf "Git Branch    : %s\n" "$(git rev-parse --abbrev-ref HEAD)"
    fi
}

# --- CLI Boilerplate ---
show_help() {
    cat <<EOF
${C_BOLD}NCOPY v6 - The Multi-File Rust Workflow Engine${C_RES}
Usage: $SCRIPT_NAME <command> [options]

Commands:
  run        Full cycle: Snapshot src/ -> Backup -> Reset to template
  snapshot   Take a snapshot of current src/ directory
  reset      Reset src/ from template directory ($TEMPLATE_DIR)
  rollback   Revert to latest src/ backup
  latest     Show/Preview the newest snapshot
  list       List all directory snapshots
  status     Show project & tree status
  clean      Delete snapshots and backups
  help       Show this help

Options:
  --fmt      Run 'cargo fmt' after reset
  --check    Run 'cargo check' after reset
  --dry-run  Show what would happen
  --force    Skip confirmation for 'clean'
  -v         Verbose output (shows directory tree in 'latest')

EOF
}

# --- Main Entry ---
[[ $# -lt 1 ]] && { show_help; exit 1; }
COMMAND="$1"; shift

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fmt) DO_FMT=1 ;;
        --check) DO_CHECK=1 ;;
        --dry-run) DRY_RUN=1 ;;
        --force) FORCE=1 ;;
        -v) VERBOSE=1 ;;
        *) warn "Unknown option: $1" ;;
    esac
    shift
done

check_rust_env

case "$COMMAND" in
    run)      cmd_run ;;
    snapshot) create_snapshot "$SOURCE_DIR" ;;
    reset)    perform_reset ;;
    rollback) cmd_rollback ;;
    latest)   cmd_latest ;;
    status)   cmd_status ;;
    clean)    cmd_clean ;;
    list)     ls -ld "$SNAP_DIR"/src_* 2>/dev/null || warn "No snapshots." ;;
    help)     show_help ;;
    *)        die "Unknown command: $COMMAND. Use 'help'." ;;
esac

