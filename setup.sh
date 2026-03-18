#!/bin/bash
#
# setup.sh - Local setup script for agent-containerization
#
# This script is meant to be run on the user's local machine (NOT in CI).
# It will:
#   1. Download the Site24x7MonitoringAgent.install file into source/
#   2. Ask the user for an image TAG and persist it in a VERSION file
#   3. Commit and push all changes to GitHub, triggering the CI workflow
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/source"
INSTALL_FILE="Site24x7MonitoringAgent.install"
VERSION_FILE="$SCRIPT_DIR/VERSION"

echo "============================================"
echo "  Site24x7 Agent Containerization - Setup"
echo "============================================"
echo ""

# Step 1: Copy the Site24x7MonitoringAgent.install from local downloads
echo "[1/3] Copying $INSTALL_FILE from local download folder ..."

DEFAULT_DOWNLOAD_PATH="$HOME/Downloads"
read -p "Enter the path to the folder containing $INSTALL_FILE (default: $DEFAULT_DOWNLOAD_PATH): " DOWNLOAD_FOLDER_PATH
DOWNLOAD_FOLDER_PATH="${DOWNLOAD_FOLDER_PATH:-$DEFAULT_DOWNLOAD_PATH}"

LOCAL_INSTALLER_PATH="$DOWNLOAD_FOLDER_PATH/$INSTALL_FILE"

if [ ! -f "$LOCAL_INSTALLER_PATH" ]; then
    echo "ERROR: $INSTALL_FILE not found at $LOCAL_INSTALLER_PATH"
    exit 1
fi

cp "$LOCAL_INSTALLER_PATH" "$SOURCE_DIR/$INSTALL_FILE"

if [ ! -f "$SOURCE_DIR/$INSTALL_FILE" ]; then
    echo "ERROR: Failed to copy $INSTALL_FILE to $SOURCE_DIR/"
    exit 1
fi

echo "Copied $INSTALL_FILE to $SOURCE_DIR/"
echo ""

# Step 2: Ask user for the image tag
CURRENT_TAG=""
if [ -f "$VERSION_FILE" ]; then
    CURRENT_TAG=$(cat "$VERSION_FILE" | tr -d '[:space:]')
    echo "Current image tag: $CURRENT_TAG"
fi

read -p "Enter the image TAG for this build (e.g., 1.0.0, v2.1.0): " IMAGE_TAG

if [ -z "$IMAGE_TAG" ]; then
    echo "ERROR: Image TAG cannot be empty."
    exit 1
fi

echo "$IMAGE_TAG" > "$VERSION_FILE"
echo "Image tag '$IMAGE_TAG' saved to VERSION file."
echo ""

# Step 3: Git add, commit, and push
echo "[3/3] Committing and pushing changes to GitHub ..."

cd "$SCRIPT_DIR"

# Stage the relevant files
git add "$SOURCE_DIR/$INSTALL_FILE"
git add "$VERSION_FILE"
git add -A

echo ""
echo "The following changes will be committed:"
git status --short
echo ""

read -p "Proceed with commit and push? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborted. Changes are staged but not committed."
    exit 0
fi

git commit -m "Update agent installer and set image tag to $IMAGE_TAG"
git push origin main

echo ""
echo "============================================"
echo "  Done! Changes pushed to GitHub."
echo "  The CI workflow will be triggered to build"
echo "  the image with tag: $IMAGE_TAG"
echo "============================================"
