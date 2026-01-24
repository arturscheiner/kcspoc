#!/usr/bin/env bash
set -euo pipefail

REPO="arturscheiner/kcspoc"
MODE="stable"
REQUESTED_TAG=""

# ----------------------------
# Argument parsing
# ----------------------------
case "${1:-}" in
  --dev)
    MODE="dev"
    ;;
  --v*)
    MODE="version"
    REQUESTED_TAG="${1#--}"
    ;;
esac

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "🔍 kcspoc bootstrap installer"

# ----------------------------
# Resolve ZIP URL
# ----------------------------
if [[ "$MODE" == "dev" ]]; then
  echo "⚠️ Installing DEVELOPMENT version (main)"
  ZIP_URL="https://github.com/${REPO}/archive/refs/heads/main.zip"

elif [[ "$MODE" == "version" ]]; then
  echo "📌 Installing specific version: ${REQUESTED_TAG}"
  ZIP_URL="https://github.com/${REPO}/archive/refs/tags/${REQUESTED_TAG}.zip"

else
  echo "🔍 Resolving latest stable release"
  LATEST_TAG="$(
    curl -s https://api.github.com/repos/${REPO}/releases/latest \
      | grep '"tag_name"' \
      | cut -d '"' -f 4
  )"

  if [[ -z "$LATEST_TAG" ]]; then
    echo "❌ Failed to determine latest release"
    exit 1
  fi

  ZIP_URL="https://github.com/${REPO}/archive/refs/tags/${LATEST_TAG}.zip"
fi

# ----------------------------
# Download & execute installer
# ----------------------------
echo "⬇️ Downloading package"
curl -sSL "$ZIP_URL" -o "$TMP_DIR/kcspoc.zip"

unzip -q "$TMP_DIR/kcspoc.zip" -d "$TMP_DIR"

INSTALLER="$(find "$TMP_DIR" -maxdepth 2 -name install.sh | head -n1)"

if [[ -z "$INSTALLER" ]]; then
  echo "❌ install.sh not found in downloaded package"
  exit 1
fi

echo "🚀 Executing installer"
bash "$INSTALLER" "$@"
