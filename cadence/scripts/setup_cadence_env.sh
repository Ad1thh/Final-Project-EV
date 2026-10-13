#!/usr/bin/env bash
# ==============================================================================
# Script: setup_cadence_env.sh
# Description: Automated Environment Discovery & Setup for Cadence Genus & Innovus
# Server Target: sbinternetlab65 / Linux EDA Workstation
# Usage:
#   source scripts/setup_cadence_env.sh
#   or:
#   bash scripts/setup_cadence_env.sh
# ==============================================================================

echo "======================================================================"
echo " Cadence EDA Environment Setup & Diagnostic Tool"
echo " Host: $(hostname 2>/dev/null || echo 'Linux Server')"
echo "======================================================================"

GENUS_FOUND=0
INNOVUS_FOUND=0

# ------------------------------------------------------------------------------
# 1. CHECK IF GENUS IS ALREADY IN PATH
# ------------------------------------------------------------------------------
if command -v genus &> /dev/null; then
    echo "[FOUND] 'genus' is already in your PATH:"
    which genus
    GENUS_FOUND=1
else
    echo "[SEARCH] 'genus' is not in PATH. Searching server environment..."
fi

# ------------------------------------------------------------------------------
# 2. PROBE ENVIRONMENT MODULES (module load)
# ------------------------------------------------------------------------------
if command -v module &> /dev/null || type module &> /dev/null; then
    echo "--> Environment Modules detected. Probing available Cadence modules..."
    AVAIL_MODULES=$(module avail 2>&1 | grep -iE "cadence|genus|innovus" || true)
    if [ -n "$AVAIL_MODULES" ]; then
        echo "$AVAIL_MODULES"
        # Try loading standard module naming conventions
        for MOD in cadence/genus genus/latest genus cadence/innovus innovus/latest innovus; do
            if module load "$MOD" 2>/dev/null; then
                echo "[SUCCESS] Loaded module: $MOD"
                if command -v genus &> /dev/null; then
                    GENUS_FOUND=1
                    break
                fi
            fi
        done
    fi
fi

# ------------------------------------------------------------------------------
# 3. SEARCH KNOWN EDA INSTALLATION TREES ON sbinternetlab65
# Target roots: /home/install (where foundry PDK is located), /tools, /cadence, /eda, /opt
# ------------------------------------------------------------------------------
if [ $GENUS_FOUND -eq 0 ]; then
    echo "--> Searching filesystem for Cadence Genus binaries in /home/install and /tools..."
    
    SEARCH_DIRS=("/home/install" "/tools" "/eda" "/cadence" "/opt")
    GENUS_BIN=""
    
    for DIR in "${SEARCH_DIRS[@]}"; do
        if [ -d "$DIR" ]; then
            echo "    Scanning $DIR ..."
            GENUS_CANDIDATE=$(find "$DIR" -maxdepth 5 -type f -name genus 2>/dev/null | grep -E "bin/genus$" | head -n 1)
            if [ -n "$GENUS_CANDIDATE" ] && [ -x "$GENUS_CANDIDATE" ]; then
                GENUS_BIN="$GENUS_CANDIDATE"
                break
            fi
        fi
    done

    if [ -n "$GENUS_BIN" ]; then
        GENUS_DIR=$(dirname "$GENUS_BIN")
        export PATH="${GENUS_DIR}:${PATH}"
        echo "[SUCCESS] Found Genus binary: ${GENUS_BIN}"
        echo "          Added ${GENUS_DIR} to PATH."
        GENUS_FOUND=1
    fi
fi

# ------------------------------------------------------------------------------
# 4. SEARCH FOR CADENCE INNOVUS
# ------------------------------------------------------------------------------
if command -v innovus &> /dev/null; then
    echo "[FOUND] 'innovus' is in your PATH: $(which innovus)"
    INNOVUS_FOUND=1
else
    for DIR in "/home/install" "/tools" "/eda" "/cadence" "/opt"; do
        if [ -d "$DIR" ]; then
            INNOVUS_CANDIDATE=$(find "$DIR" -maxdepth 5 -type f -name innovus 2>/dev/null | grep -E "bin/innovus$" | head -n 1)
            if [ -n "$INNOVUS_CANDIDATE" ] && [ -x "$INNOVUS_CANDIDATE" ]; then
                INNOVUS_DIR=$(dirname "$INNOVUS_CANDIDATE")
                export PATH="${INNOVUS_DIR}:${PATH}"
                echo "[SUCCESS] Found Innovus binary: ${INNOVUS_CANDIDATE}"
                echo "          Added ${INNOVUS_DIR} to PATH."
                INNOVUS_FOUND=1
                break
            fi
        fi
    done
fi

# ------------------------------------------------------------------------------
# 5. VERIFY LICENSE ENVIRONMENT VARIABLES
# ------------------------------------------------------------------------------
echo "----------------------------------------------------------------------"
echo " License Server Status:"
if [ -n "$CDS_LIC_FILE" ]; then
    echo "  [OK] CDS_LIC_FILE = $CDS_LIC_FILE"
elif [ -n "$LM_LICENSE_FILE" ]; then
    echo "  [OK] LM_LICENSE_FILE = $LM_LICENSE_FILE"
else
    echo "  [WARN] Neither CDS_LIC_FILE nor LM_LICENSE_FILE is currently set."
    echo "         If synthesis gives a license error, check with your lab admin"
    echo "         or search for license scripts (e.g. source /home/install/license.sh)."
fi

# ------------------------------------------------------------------------------
# 6. VERIFY TARGET 90nm PDK LIBRARY
# ------------------------------------------------------------------------------
echo "----------------------------------------------------------------------"
echo " 90nm Standard Cell Library Check:"
TARGET_LIB_PATH="/home/install/FOUNDRY/digital/90nm/dig/lib/slow.lib"
if [ -f "$TARGET_LIB_PATH" ]; then
    echo "  [OK] Found target PDK library: $TARGET_LIB_PATH"
else
    echo "  [WARN] Target library not found at $TARGET_LIB_PATH."
    echo "         Checking for alternatives in /home/install/FOUNDRY/..."
    ALT_LIB=$(find /home/install/FOUNDRY -name "slow.lib" 2>/dev/null | head -n 1)
    if [ -n "$ALT_LIB" ]; then
        echo "  [FOUND] Alternative slow.lib located at: $ALT_LIB"
        export PDK_LIB_PATH="$(dirname "$ALT_LIB")"
        export PDK_TARGET_LIB="slow.lib"
        echo "          Configured PDK_LIB_PATH=$PDK_LIB_PATH"
    fi
fi

# ------------------------------------------------------------------------------
# 7. TOOL VERSION VALIDATION
# ------------------------------------------------------------------------------
echo "----------------------------------------------------------------------"
if command -v genus &> /dev/null; then
    echo "[VERIFIED] Genus version:"
    genus -version || genus -help 2>&1 | head -n 2
    echo "======================================================================"
    echo " Cadence Genus environment is READY!"
    echo " To make this permanent across all sessions, add this to ~/.bashrc:"
    if [ -n "$GENUS_DIR" ]; then
        echo "   echo 'export PATH=\"${GENUS_DIR}:\$PATH\"' >> ~/.bashrc"
    fi
    echo "======================================================================"
else
    echo "[ERROR] Could not automatically locate Cadence Genus."
    echo "Please run this command on your terminal to manually find it:"
    echo "   find /home/install -name genus -type f 2>/dev/null"
    echo "Then add its directory to your PATH:"
    echo "   export PATH=/path/to/genus/bin:\$PATH"
    echo "======================================================================"
    return 1 2>/dev/null || exit 1
fi
