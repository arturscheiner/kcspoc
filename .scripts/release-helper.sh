#!/bin/bash
# Internal release helper - NOT for distribution

VERSION=$(grep '^VERSION=' lib/common.sh | cut -d'"' -f2)
echo "Current project version: v$VERSION"

check_consistency() {
    echo "Checking version consistency..."
    grep -r "$VERSION" . --exclude-dir=".git" --exclude-dir=".agent"
}

case "$1" in
    check)
        check_consistency
        ;;
    *)
        echo "Usage: $0 {check}"
        exit 1
        ;;
esac
