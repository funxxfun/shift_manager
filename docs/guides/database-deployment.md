# データベースとデプロイメント

## 概要

本システムはPostgreSQLをデータベースとして使用している。
開発環境ではローカルに保存され、本番運用ではクラウドへのデプロイを推奨する。

## データベース構成

### 使用DB

**PostgreSQL**（リレーショナルデータベース）

### 環境別データベース

| 環境 | データベース名 | 用途 |
|------|--------------|------|
| development | shift_manager_development | 開発・テスト |
| test | shift_manager_test | 自動テスト |
| production | shift_manager_production | 本番運用 |

設定ファイル: `config/database.yml`

### データの保存場所（開発環境）

ローカルのPostgreSQLデータディレクトリに保存される：

```
# Mac (Homebrew) の場合
/opt/homebrew/var/postgresql@14/

# または
/usr/local/var/postgres/
```

## ローカル vs クラウド

### 比較表

| 項目 | ローカル | クラウド |
|------|---------|---------|
| **複数人アクセス** | 不可（1台のPCのみ） | 可能（どこからでも） |
| **データ共有** | できない | 全店舗でリアルタイム共有 |
| **バックアップ** | 自分で管理 | 自動バックアップ |
| **PC故障時** | データ消失リスク | 影響なし |
| **費用** | 無料 | 月額数百〜数千円 |
| **セットアップ** | 簡単 | やや手間 |

### 本システムの要件

```
課題: 店舗間の応援シフト調整に約7時間/週かかっている
解決: 複数店舗で過不足を共有し、自動補填
```

**店舗間共有が前提のため、本番運用ではクラウド必須**

### 使い分けの目安

| フェーズ | 推奨環境 | 理由 |
|---------|---------|------|
| 開発・検証 | ローカル | 手軽、費用なし |
| 社内テスト | クラウド（無料枠） | 複数人で検証可能 |
| 本番運用 | クラウド（有料プラン） | 安定性、バックアップ |

## クラウドサービスの選択肢

### 推奨サービス

| サービス | 特徴 | 月額目安 | 難易度 |
|---------|------|---------|--------|
| **Render** | 簡単、無料枠あり | 無料〜$7 | 低 |
| **Heroku** | Rails定番、実績豊富 | $5〜 | 低 |
| **Railway** | モダン、従量課金 | 従量課金 | 低 |
| **AWS (EC2 + RDS)** | 本格的、柔軟 | 要見積 | 高 |
| **Google Cloud Run** | スケーラブル | 従量課金 | 中 |

### 小規模運用の推奨

**Render** または **Heroku** がおすすめ：
- Railsとの相性が良い
- PostgreSQLが簡単にセットアップできる
- 無料枠で検証可能
- 有料プランも安価

## アーキテクチャ

### 開発環境（現在）

```
あなたのMac
├── shift_manager/（Railsアプリ）
│   └── localhost:3000
└── PostgreSQL
    └── shift_manager_development
```

- 自分のPCでのみアクセス可能
- `rails server` でサーバー起動

### 本番環境（クラウド）

```
クラウド（Render / Heroku / AWS など）
├── Webサーバー
│   └── Railsアプリ
│       └── https://your-app.onrender.com
└── データベースサーバー
    └── PostgreSQL
        └── shift_manager_production

        ↓ アクセス

┌─────────┐  ┌─────────┐  ┌─────────┐
│ 博多店  │  │ 天神店   │  │ 六本松店 │
│ スタッフ │  │ スタッフ │  │ スタッフ │
└─────────┘  └─────────┘  └─────────┘
```

- インターネット経由で全店舗からアクセス可能
- 24時間稼働

## データベース関連コマンド

### 基本操作

```bash
# DBを作成
rails db:create

# マイグレーション実行（テーブル作成・変更）
rails db:migrate

# Seedデータ投入
rails db:seed

# DBを完全リセット（削除→作成→マイグレーション→Seed）
rails db:reset

# PostgreSQLに直接接続
rails dbconsole
```

### データのバックアップ（ローカル）

```bash
# バックアップ
pg_dump shift_manager_development > backup.sql

# 復元
psql shift_manager_development < backup.sql
```

## Seedデータ vs 実データ

| 項目 | Seedデータ | 実データ |
|------|-----------|---------|
| 用途 | 開発・テスト用の初期データ | 実際の業務データ |
| 実行 | `rails db:seed` | 画面操作・CSVインポート |
| リセット | `rails db:reset` で再投入可 | 消えたら復旧不可 |
| 管理 | `db/seeds.rb` | データベース |

## 本番デプロイ時の注意点

1. **環境変数の設定**
   - `RAILS_ENV=production`
   - `ANTHROPIC_API_KEY`（AI提案機能用）
   - `SECRET_KEY_BASE`（セッション暗号化用）
   - `DATABASE_URL`（クラウドDBの接続情報）

2. **アセットのプリコンパイル**
   ```bash
   rails assets:precompile
   ```

3. **マイグレーション実行**
   ```bash
   rails db:migrate RAILS_ENV=production
   ```

4. **HTTPS対応**
   - クラウドサービスが自動で提供することが多い

5. **バックアップ設定**
   - クラウドDBの自動バックアップを有効化

## 関連ドキュメント

- [環境セットアップ](./setup.md)
- [アーキテクチャ概要](../architecture/README.md)
