#!/usr/bin/env bash
set -e

# kcspoc Release Preparation Script
# Usage: .scripts/prepare-release.sh [vX.Y.Z]

TARGET_VER=$1
DATE=$(date +%Y-%m-%d)

# 1. Basic Safety Checks
echo "🔎 Checking working tree..."
if ! git diff --quiet; then
    echo "❌ Uncommitted changes detected. Please commit or stash them first."
    exit 1
fi

echo "🔎 Checking branch..."
BRANCH=$(git branch --show-current)
[[ "$BRANCH" == release/* ]] || [[ "$BRANCH" == main ]] || {
    echo "❌ Not on a release or main branch (current: $BRANCH)"
    exit 1
}

# 2. Version and Structure Update
if [[ -n "$TARGET_VER" ]]; then
    CLEAN_VER=${TARGET_VER#v}
    echo "⚙️ Preparing structure for v$CLEAN_VER"

    # A. Update lib/common.sh
    sed -i "s/VERSION=\".*\"/VERSION=\"$CLEAN_VER\"/" lib/common.sh
    echo "✅ v$CLEAN_VER set in lib/common.sh"

    # B. Update CHANGELOG.md Header
    if ! grep -q "## \[$CLEAN_VER\]" CHANGELOG.md; then
        # Insert after the retro note or after the first line if no note
        if grep -q "v0.5.0 predates the formal changelog" CHANGELOG.md; then
            LINE_NUM=$(grep -n "v0.5.0 predates the formal changelog" CHANGELOG.md | cut -d: -f1)
            LINE_NUM=$((LINE_NUM + 2))
            sed -i "${LINE_NUM}a \n## [$CLEAN_VER] - $DATE\n### Added\n- [TBD]\n" CHANGELOG.md
        else
            sed -i "9a \n## [$CLEAN_VER] - $DATE\n### Added\n- [TBD]\n" CHANGELOG.md
        fi
        echo "✅ Created CHANGELOG.md section for v$CLEAN_VER"
    fi

    # C. Update CHANGELOG.md Links
    PREV_VER=$(grep "^## \[" CHANGELOG.md | sed -n '2p' | cut -d'[' -f2 | cut -d']' -f1)
    if [[ -n "$PREV_VER" ]] && ! grep -q "\[$CLEAN_VER\]:" CHANGELOG.md; then
        NEW_LINK="[$CLEAN_VER]: https://github.com/arturscheiner/kcspoc/compare/v$PREV_VER...v$CLEAN_VER"
        # Insert after the last link or at the end
        if grep -q "^\[.*\]: http" CHANGELOG.md; then
            sed -i "/^\[.*\]: http/i $NEW_LINK" CHANGELOG.md
        else
            echo -e "\n---\n$NEW_LINK" >> CHANGELOG.md
        fi
        echo "✅ Added comparison link for v$CLEAN_VER"
    fi
fi

# 3. Final Validation
echo "🔎 Validating release readiness..."
CURRENT_VER=$(grep '^VERSION=' lib/common.sh | cut -d'"' -f2)
LATEST_CH_VER=$(grep "^## \[" CHANGELOG.md | head -n1 | cut -d'[' -f2 | cut -d']' -f1)

if [[ "$CURRENT_VER" != "$LATEST_CH_VER" ]]; then
    echo "❌ Version mismatch: common.sh (v$CURRENT_VER) vs CHANGELOG (v$LATEST_CH_VER)"
    exit 1
fi

if grep -q "\[TBD\]" CHANGELOG.md; then
    echo "❌ CHANGELOG contains [TBD] placeholders. Please fill them out."
    exit 1
fi

echo "✨ Release v$CURRENT_VER is structurally ready and validated."