#!/usr/bin/env bash
set -euo pipefail

BLOG_URL="https://vivaldi.com/ja/blog/latest/"
STATE_DIR="prev"
STATE_FILE="${STATE_DIR}/urls.txt"

mkdir -p "$STATE_DIR"

echo "===== DEBUG: working directory ====="
pwd
ls -la

echo "===== DEBUG: prev directory ====="
ls -la "$STATE_DIR" || true

# 最新ページ取得
curl -s "$BLOG_URL" > full.html

# 記事URL抽出（正規化）
sed -n '/<div class="column w50 w100-mobile">/,/<\/div><\/div><\/div>/p' full.html \
  | grep -oE 'https://vivaldi\.com/ja/blog/[^"]+' \
  | sort -u \
  > current_urls.txt

echo "===== DEBUG: current_urls.txt ====="
nl -ba current_urls.txt || echo "(current_urls.txt is empty)"

changed=false

if [ -f "$STATE_FILE" ]; then
  echo "===== DEBUG: prev/urls.txt ====="
  nl -ba "$STATE_FILE" || true
  
  if ! diff "$STATE_FILE" current_urls.txt > /dev/null; then
    echo "DEBUG: diff detected"
    changed=true
  fi
else
  # 初回実行
  echo "DEBUG: prev/urls.txt does NOT exist (first run)"
  changed=true
fi

# 状態保存（次回比較用）
mv current_urls.txt "$STATE_FILE"

# GitHub Actions 出力
echo "changed=$changed" >> "$GITHUB_OUTPUT"