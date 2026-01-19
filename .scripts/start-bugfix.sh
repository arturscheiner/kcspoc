#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <short-description>"
  echo "Example: $0 installer-fix"
  exit 1
fi

DESC=$1

echo "🔎 Fetching latest tags"
git fetch --tags

LATEST_TAG=$(git tag -l "v*" --sort=-v:refname | head -n1)

if [ -z "$LATEST_TAG" ]; then
  echo "❌ No tags found"
  exit 1
fi

BRANCH_NAME="bugfix/${LATEST_TAG}-${DESC}"

echo "🚀 Creating branch $BRANCH_NAME from $LATEST_TAG"

if git rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
  echo "❌ Branch $BRANCH_NAME already exists"
  exit 1
fi

git checkout -b "$BRANCH_NAME" "$LATEST_TAG"

echo "✅ Branch created and checked out."
echo "💡 Now implement your fix and prepare the release."
