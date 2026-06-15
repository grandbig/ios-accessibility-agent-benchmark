#!/bin/bash
#
# SwiftUIApp のアクセシビリティツリーを docs/trees/*.txt に書き出す。
# AccessibilityTreeSnapshotTests を実行し、標準出力のマーカー付きツリーを取り出す。
# OSS 依存なし（Xcode 同梱の XCUITest のみ）。
#
# 使い方:
#   scripts/dump-accessibility-trees.sh
#   scripts/dump-accessibility-trees.sh 'platform=iOS Simulator,name=iPhone 15,OS=17.5'
set -euo pipefail

cd "$(dirname "$0")/.."

DESTINATION="${1:-platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.0}"
OUT_DIR="docs/trees"
mkdir -p "$OUT_DIR"

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

echo "Running AccessibilityTreeSnapshotTests on: $DESTINATION"
if ! xcodebuild \
    -project AccessibilityBenchmark.xcodeproj \
    -scheme SwiftUIApp \
    -destination "$DESTINATION" \
    -only-testing:SwiftUIAppUITests/AccessibilityTreeSnapshotTests \
    test > "$LOG" 2>&1; then
    echo "xcodebuild test failed:" >&2
    tail -40 "$LOG" >&2
    exit 1
fi

awk -v out="$OUT_DIR" '
    /===TREE-START:/ {
        name = $0
        sub(/.*===TREE-START:/, "", name)
        sub(/===.*/, "", name)
        file = out "/" name ".txt"
        printf "" > file   # truncate
        capturing = 1
        next
    }
    /===TREE-END:/ { capturing = 0; close(file); next }
    capturing && /Requesting snapshot of accessibility hierarchy/ { next }
    capturing { print >> file }
' "$LOG"

echo "Wrote trees to $OUT_DIR/:"
ls -1 "$OUT_DIR"
