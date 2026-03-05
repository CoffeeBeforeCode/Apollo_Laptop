#!/usr/bin/env bash
# =============================================================================
# update_conky.sh
# Part of the Apollo_Laptop repo (github.com/CoffeeBeforeCode/Apollo_Laptop)
#
# Purpose: Pull the latest Conky configs from GitHub, deploy them to their
#          correct locations, and restart Conky cleanly.
#
# Cron entry (replace the old one with this):
#   */5 9-22 * * * /bin/bash ~/Apollo_Laptop/update_conky.sh >> ~/Apollo_Laptop/logs/update_conky.log 2>&1
# =============================================================================

set -euo pipefail

# --- Configuration -----------------------------------------------------------
REPO_DIR="$HOME/Apollo_Laptop"
LOG_DIR="$REPO_DIR/logs"
LOGFILE="$LOG_DIR/update_conky.log"

# Source files inside the repo
CONKY1_SRC="$REPO_DIR/conky.conf"
CONKY2_SRC="$REPO_DIR/conky2.conf"

# Destination locations Conky reads from
CONKY1_DEST="$HOME/.conkyrc"
CONKY2_DEST="$HOME/.conkyrc2"
# -----------------------------------------------------------------------------

# Ensure the log directory exists
mkdir -p "$LOG_DIR"

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log() {
    echo "[$(timestamp)] $*" | tee -a "$LOGFILE"
}

log "---------------------------------------------------"
log "Starting Conky update run"

# --- 1. Pull latest changes from GitHub --------------------------------------
log "Pulling from origin/main..."
cd "$REPO_DIR"

# Capture git output so it goes into the log
GIT_OUTPUT=$(git pull origin main 2>&1)
log "$GIT_OUTPUT"

# If nothing changed, skip the rest to avoid an unnecessary Conky restart
if echo "$GIT_OUTPUT" | grep -q "Already up to date."; then
    log "No changes detected. Skipping deploy and restart."
    log "Done."
    exit 0
fi

# --- 2. Verify source files exist before copying ----------------------------
for src in "$CONKY1_SRC" "$CONKY2_SRC"; do
    if [[ ! -f "$src" ]]; then
        log "ERROR: Source file not found: $src — aborting."
        exit 1
    fi
done

# --- 3. Back up existing configs (keeps the previous version only) -----------
log "Backing up existing configs..."
[[ -f "$CONKY1_DEST" ]] && cp "$CONKY1_DEST" "${CONKY1_DEST}.bak"
[[ -f "$CONKY2_DEST" ]] && cp "$CONKY2_DEST" "${CONKY2_DEST}.bak"

# --- 4. Deploy updated configs -----------------------------------------------
log "Deploying conky.conf  → $CONKY1_DEST"
cp "$CONKY1_SRC" "$CONKY1_DEST"

log "Deploying conky2.conf → $CONKY2_DEST"
cp "$CONKY2_SRC" "$CONKY2_DEST"

# --- 5. Restart Conky --------------------------------------------------------
log "Stopping any running Conky instances..."
pkill -x conky 2>/dev/null || true   # '|| true' prevents set -e from firing if no process found
sleep 1                               # Brief pause to let processes exit cleanly

log "Starting Conky with primary config..."
DISPLAY=:0 conky -c "$CONKY1_DEST" -d   # -d = daemonise (run in background)

log "Starting Conky with secondary config..."
DISPLAY=:0 conky -c "$CONKY2_DEST" -d

log "Conky restarted successfully."
log "Done."
