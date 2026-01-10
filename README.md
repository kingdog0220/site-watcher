# site-watcher

GitHub Actions を使用してウェブサイトの定期的な監視と更新検知、Discord への自動通知を行うリポジトリです。

## 概要

このプロジェクトでは、YAML ワークフローと Bash シェルスクリプトを組み合わせて、指定したウェブサイトの変更を監視し、更新があった場合に Discord に通知します。

**主な特徴**
- 定期スケジュール実行（cron ベース）または手動トリガー対応
- 複数サイト監視に対応（スクリプト分離設計）
- GitHub Actions Cache を使用した前回状態の保存と差分検知
- シェルスクリプト分離による保守性向上

## ファイル構成

```
.
├── .github/
│   └── workflows/
│       ├── watch_vivalidi.yml       # Vivaldi ブログ監視ワークフロー
│       └── test_notify.yml          # 通知テストワークフロー
├── scripts/
│   └── watch_vivaldi.sh             # Vivaldi ブログ監視スクリプト
└── README.md
```

## ワークフロー説明

### `watch_vivalidi.yml`
Vivaldi ブログの最新記事更新を監視するワークフロー

**スケジュール**
- 毎日 23:00 UTC（朝 8:00 JST）に自動実行
- `workflow_dispatch` で手動実行可能

**ステップ詳細**
1. **キャッシュ復元** - 前回実行時の状態を復元
2. **監視スクリプト実行** - `scripts/watch_vivaldi.sh` を実行して差分検知
3. **通知送信** - 変更検知時に Discord へ通知
4. **キャッシュ保存** - 今回の状態を保存

### `watch_vivaldi.sh`
監視ロジックをシェルスクリプトで実装

**処理フロー**
1. Vivaldi ブログの最新ページをダウンロード
2. 記事 URL を正規表現で抽出・正規化
3. 前回保存した URL リストと比較
4. 変更があれば `changed=true` を出力

**環境変数（カスタマイズ時）**
- `BLOG_URL` - 監視対象 URL（デフォルト: `https://vivaldi.com/ja/blog/latest/`）
- `STATE_DIR` - 状態ファイルの保存ディレクトリ（デフォルト: `prev`）

## セットアップ方法

### 1. リポジトリの複製
```bash
git clone <repository-url>
cd site-watcher
```

### 2. 必要なシークレット設定
GitHub リポジトリの **Settings → Secrets and variables → Actions** で以下を設定：

| シークレット名 | 説明 | 例 |
|---|---|---|
| `DISCORD_WEBHOOK_URL` | Discord Webhook URL | `https://discord.com/api/webhooks/...` |
| `DISCORD_USER_ID` | 通知対象の Discord ユーザー ID | `123456789` |

**Discord Webhook 取得方法**
1. サーバーの設定 → チャンネルの編集
2. 連携 → Webhook を作成
3. URL をコピーして秘密情報として登録

### 3. ワークフロー有効化
このリポジトリを GitHub に push すると、`.github/workflows/` 内のワークフローは自動で有効になります。
**Settings → Actions** で有効状態を確認できます。

## カスタマイズガイド

### 新しいサイト監視を追加する場合

1. **シェルスクリプト作成** - `scripts/watch_<site-name>.sh` を作成
   - ターゲットサイトに合わせて HTML 解析ロジックを実装
   - 必ず最後に `echo "changed=true/false" >> "$GITHUB_OUTPUT"` を出力

2. **ワークフロー作成** - `.github/workflows/watch_<site-name>.yml` を作成
   - スケジュール（cron）を設定
   - スクリプト実行ステップで `scripts/watch_<site-name>.sh` を呼び出し
   - 通知先（Slack、Discord など）を追加

### 既存監視の調整
- **スケジュール変更** - ワークフロー内の `cron` 値を編集
- **通知メッセージ** - ワークフロー内の `curl` コマンドの `-d` パラメータを編集
- **検知ロジック** - シェルスクリプト内の `sed` や `grep` パターンを編集

## テスト

### 通知のテスト実行
```bash
# ローカルテスト（Discord 通知をテスト）
# watch_vivalidi.sh を実行前に DISCORD_WEBHOOK_URL、DISCORD_USER_ID を設定
DISCORD_WEBHOOK_URL="<your-webhook-url>" \
DISCORD_USER_ID="<your-user-id>" \
scripts/watch_vivaldi.sh
```

### ワークフロー手動実行
GitHub の **Actions** タブで、該当ワークフローを選択 → **Run workflow** をクリック

## トラブルシューティング

**通知が来ない場合**
1. Webhook URL とユーザー ID が正しく設定されているか確認
2. ワークフローの実行ログで エラーを確認
   - **Actions** → 対象ワークフロー → 最新実行 → ステップ詳細
3. サイト構造が変わっていないか確認（HTML 解析パターンが合致しているか）

**キャッシュが機能していない場合**
- GitHub Actions のキャッシュ保持期間は 7 日間です
- 期間超過後は初回実行扱いとなり `changed=true` が出力されます

## ライセンス
MIT

---
問題や改善提案があれば Issue を作成してください。
