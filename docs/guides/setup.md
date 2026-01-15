# 環境セットアップ

## 必要条件

- Ruby 3.2.2
- PostgreSQL
- Node.js（TailwindCSS用）

## セットアップ手順

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd shift_manager
```

### 2. Ruby バージョンの確認

```bash
ruby -v
# => ruby 3.2.2
```

rbenvを使用している場合:

```bash
rbenv install 3.2.2
rbenv local 3.2.2
```

### 3. 依存関係のインストール

```bash
bundle install
```

### 4. データベースのセットアップ

```bash
bin/rails db:create
bin/rails db:migrate
```

### 5. 環境変数の設定

`.env` ファイルを作成（または環境変数を設定）:

```bash
# AI提案機能を使用する場合
ANTHROPIC_API_KEY=sk-ant-xxxxx
```

### 6. サーバーの起動

```bash
bin/rails server
```

http://localhost:3000 でアクセス。

## 開発用データの投入

### CSVインポート

1. http://localhost:3000/imports/new にアクセス
2. 勤次郎形式のCSVをアップロード

CSVフォーマットの詳細: [docs/features/csv_import.md](../features/csv_import.md)

### 店舗必要人数の設定

店舗ごとに曜日タイプ別の必要人数を設定:

```ruby
# Rails console
store = Store.find_by(code: 'S001')

StoreRequirement.create!(
  store: store,
  day_type: :weekday,
  pharmacist_count: 2,
  clerk_count: 1
)

StoreRequirement.create!(
  store: store,
  day_type: :saturday,
  pharmacist_count: 1,
  clerk_count: 1
)

StoreRequirement.create!(
  store: store,
  day_type: :holiday,
  pharmacist_count: 1,
  clerk_count: 0
)
```

## テストの実行

```bash
bin/rails spec
```

## トラブルシューティング

### PostgreSQLに接続できない

```bash
# PostgreSQLが起動しているか確認
brew services list

# 起動
brew services start postgresql
```

### TailwindCSSが反映されない

```bash
bin/rails tailwindcss:build
```

開発中は監視モードで:

```bash
bin/rails tailwindcss:watch
```
