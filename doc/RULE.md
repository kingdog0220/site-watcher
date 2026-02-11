# RULE.md

## 1. 基本方針
- Vivaldi blog などの監視対象サイトに対し、**確実で再現性のある変更検知**を行い、結果を Discord 通知へ確実に反映させる。
- GitHub Actions 上での実行を前提に、**ローカル依存のない Bash スクリプト**とワークフローを保つ。
- キャッシュ（`prev/` ディレクトリ配下）を用いた差分検出がコア機能のため、**状態管理・ログ出力を明確に**してトラブルシュートを容易にする。
- 変更は小さく保ち、README やワークフローのコメントで背景を共有する。必要に応じて `scripts/watch_<target>.sh` を複製して新監視対象を追加する。
- APIキーなどの秘密情報はSecretsに設定して使用する。

## 2. 使用言語・技術スタック
- **スクリプト:** Bash（`scripts/watch_vivaldi.sh` など）。
- **自動化:** GitHub Actions（`.github/workflows/watch_vivaldi.yml` など）。
- **通知:** Discord Webhook
- **補助ツール:** `gh` CLI（キャッシュ削除）、`shellcheck`（Bash lint）、`yamllint` や `act`（YAML/ワークフローテスト）。

## 3. 命名規約
- **ファイル:** 小文字スネークケース。ドキュメントは大文字（例: `README.md`, `RULE.md`）。
- **Bash 変数:** 大文字スネークケース（例: `STATE_DIR`, `BLOG_URL`）。関数は小文字スネークまたはハイフンなし（例: `fetch_urls`).
- **YAML キー:** 小文字 + ハイフン。ジョブ/ステップ名は実行内容が一目で分かるよう動詞から始める。
- **キャッシュキー:** `watch-vivaldi-${{ github.run_id }}` のように対象名 + 実行識別子で衝突を避ける。

## 4. フォーマット / インデント
- **インデント:** YAML/Bash/Markdown ともに 2 スペース。タブは使用しない。
- **Bash:** `set -euo pipefail` を基本にし、長いパイプは行継続 `\` で折り返す。コメントは `#` + 半角スペース。
- **YAML:** キー順は論理順（例: `name` → `on` → `jobs`）。ブール値は `true/false`。複数行コマンドは `|` ブロックを使う。
- **Markdown:** 見出しは `#` から順番に。箇条書きは `-` で統一し、コードブロックには言語指定を付ける。
- **lint:** 可能な限り `shellcheck scripts/watch_vivaldi.sh` / `yamllint .github/workflows/*.yml` を実行し、警告は無視せず修正する。
