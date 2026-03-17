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
read -p "Enter the download URL for Site24x7MonitoringAgent.install (e.g., https://staticdownloads.site24x7.com/server/Site24x7MonitoringAgent.install): " DOWNLOAD_URL
VERSION_FILE="$SCRIPT_DIR/VERSION"

# Load .env variables if .env file exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "Loading credentials from .env file..."
    set -a # automatically export all variables
    . "$SCRIPT_DIR/.env"
    set +a
    if [ -z "$user" ] || [ -z "$password" ]; then
        echo "WARNING: 'user' or 'password' variables in .env are empty. Proceeding without authentication."
        AUTH_ARGS=""
        CURL_AUTH=""
    else
        AUTH_ARGS="--user \"$user\" --password \"$password\""
        CURL_AUTH="-u \"$user:$password\""
    fi
else
    echo "No .env file found. Proceeding without authentication for download."
    AUTH_ARGS=""
    CURL_AUTH=""
fi

echo "============================================"
echo "  Site24x7 Agent Containerization - Setup"
echo "============================================"
echo ""

# Step 1: Download the Site24x7MonitoringAgent.install
echo "[1/3] Downloading $INSTALL_FILE ..."
if command -v wget &> /dev/null; then
    wget -O "$SOURCE_DIR/$INSTALL_FILE" "$DOWNLOAD_URL" --no-check-certificate $AUTH_ARGS
elif command -v curl &> /dev/null; then
    curl -fSL $CURL_AUTH -o "$SOURCE_DIR/$INSTALL_FILE" "$DOWNLOAD_URL"
else
    echo "ERROR: Neither wget nor curl is available. Please install one of them."
    exit 1
fi

if [ ! -f "$SOURCE_DIR/$INSTALL_FILE" ]; then
    echo "ERROR: Failed to download $INSTALL_FILE"
    exit 1
fi

echo "Downloaded $INSTALL_FILE to $SOURCE_DIR/"
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
