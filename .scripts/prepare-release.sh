#!/usr/bin/env bash
set -e

echo "🔎 Checking working tree"
git diff --quiet || {
  echo "❌ Uncommitted changes detected"
  exit 1
}

echo "🔎 Checking CHANGELOG"
grep -q "^## \\[" CHANGELOG.md || {
  echo "❌ CHANGELOG.md has no release entry"
  exit 1
}

echo "🔎 Checking branch"
BRANCH=$(git branch --show-current)
[[ "$BRANCH" == release/* ]] || {
  echo "❌ Not on a release branch (must be release/*)"
  exit 1
}

echo "🔎 Checking version consistency"
VERSION_BASE=$(grep '^VERSION_BASE=' lib/model/version_model.sh | cut -d'"' -f2)
CHANGELOG_VER=$(grep "^## \[" CHANGELOG.md | head -n1 | cut -d'[' -f2 | cut -d']' -f1)

if [[ "$VERSION" != "$CHANGELOG_VER" ]]; then
  echo "❌ Version mismatch detected!"
  echo "   lib/model/version_model.sh:  v$VERSION"
  echo "   CHANGELOG.md:   v$CHANGELOG_VER"
  exit 1
fi

echo "✅ Ready to tag release v$VERSION"