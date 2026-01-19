#!/usr/bin/env bash
set -e

# Ensure we've passed the preparation checks
./.scripts/prepare-release.sh

VERSION=$(grep '^VERSION=' lib/common.sh | cut -d'"' -f2)
TAG="v$VERSION"

echo "🚀 Tagging release $TAG"

if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "❌ Tag $TAG already exists locally"
  exit 1
fi

git tag -a "$TAG" -m "Release $TAG"
echo "✅ Tag $TAG created"

echo "❓ Do you want to push the tag to origin? (y/N)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  git push origin "$TAG"
  echo "✅ Tag pushed successfully"
else
  echo "⚠️ Tag not pushed"
fi
