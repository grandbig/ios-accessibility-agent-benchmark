#!/bin/bash
#
# SwiftUIApp / UIKitApp のアクセシビリティツリーを docs/trees/*.txt に書き出す。
# 各アプリの *AccessibilityTreeSnapshotTests を実行し、標準出力のマーカー付き
# ツリーを取り出す。OSS 依存なし（Xcode 同梱の XCUITest のみ）。
#
# 出力: docs/trees/swiftui-<state>.txt, docs/trees/uikit-<state>.txt
#
# 使い方:
#   scripts/dump-accessibility-trees.sh
#   scripts/dump-accessibility-trees.sh 'platform=iOS Simulator,name=iPhone 15,OS=17.5'
set -euo pipefail

cd "$(dirname "$0")/.."

DESTINATION="${1:-platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.0}"
OUT_DIR="docs/trees"
mkdir -p "$OUT_DIR"

# 既存の採取結果(*.txt)を消してから作り直す（README.md は残す）
find "$OUT_DIR" -maxdepth 1 -name '*.txt' -delete

dump_app() {
    local scheme="$1"
    local prefix="$2"
    local log
    log="$(mktemp)"

    echo "Running $scheme on: $DESTINATION"
    if ! xcodebuild \
        -project AccessibilityBenchmark.xcodeproj \
        -scheme "$scheme" \
        -destination "$DESTINATION" \
        test > "$log" 2>&1; then
        echo "xcodebuild test failed ($scheme):" >&2
        tail -40 "$log" >&2
        rm -f "$log"
        exit 1
    fi

    awk -v out="$OUT_DIR" -v prefix="$prefix" '
        /===TREE-START:/ {
            name = $0
            sub(/.*===TREE-START:/, "", name)
            sub(/===.*/, "", name)
            file = out "/" prefix name ".txt"
            printf "" > file
            capturing = 1
            next
        }
        /===TREE-END:/ { capturing = 0; close(file); next }
        capturing && /Requesting snapshot of accessibility hierarchy/ { next }
        capturing { print >> file }
    ' "$log"
    rm -f "$log"
}

dump_app SwiftUIApp-Trees "swiftui-"
dump_app UIKitApp-Trees   "uikit-"

echo "Wrote trees to $OUT_DIR/:"
ls -1 "$OUT_DIR"
