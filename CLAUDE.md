# Shift Manager

調剤薬局チェーン向けシフト管理システム。
複数店舗間の人員過不足を可視化し、AIによる補填提案を行う。

## プロジェクト背景

### 解決したい課題

- 店舗間の応援シフト調整に **約7時間/週**（7人 × 1時間）かかっている
- 電話での個別交渉が必要で、断られることも多い
- 店舗間で労働力に偏りがある

### 実現したいこと

1. **過不足の自動算出** - 勤次郎のシフト × 必要人数で自動計算
2. **店舗間共有** - Googleドライブ相当の機能
3. **自動補填** - 管理者権限で過剰→不足へ補填
4. **客観的基準** - 「自動算出」で応援業務を断れなくする

### 実装状況

| 機能 | 状態 |
|------|------|
| CSVインポート | 実装済み |
| 過不足算出・表示 | 実装済み |
| AI補填提案 | 実装済み |
| 店舗間共有 | 未実装 |
| ユーザー認証・権限 | 未実装 |

詳細: [docs/architecture/README.md](docs/architecture/README.md)

## Plan Stack ワークフロー

### 基本原則

1. **Research → Plan → Implement** — 計画フェーズを飛ばさない
2. **planはアーティファクト** — 実装と同等の成果物として扱う
3. **planは蓄積する** — 削除せず、知識を積み重ねる
4. **planはセーブポイント** — `/clear`しても復帰できる

### 実装前の必須ステップ

1. `docs/plans/` で類似の過去実装を検索
2. Plan Mode に入る（Claude Code で Shift+Tab を2回）
3. `docs/plans/YYYYMMDD_機能名.md` に実装計画を作成
4. **人間の承認を得てから** コードを書く
5. Plan Mode を終了して実装

### 実装後

1. AIレビュー（計画 vs 実装の比較）
2. 完了したplanを `docs/plans/completed/` に移動

### 計画ファイルの命名

```
docs/plans/YYYYMMDD_機能名.md
```

例:
- `20260115_user_authentication.md`
- `20260120_csv_export.md`

### コンテキストの復元

`/clear` 後やセッション開始時:

```
docs/plans/current/ にあるplanを読んで、続きから実装してください。
```

## ディレクトリ構成

```
docs/
├── plans/
│   ├── current/      # 進行中の計画（なければここに作成）
│   └── completed/    # 完了した計画
├── features/         # 機能仕様
├── architecture/     # アーキテクチャ設計
├── guides/           # 開発ガイド
└── templates/        # planとreviewのテンプレート
```

## ドキュメント

### アーキテクチャ

- [docs/architecture/README.md](docs/architecture/README.md) - 背景・設計・DB・実装状況

### 機能仕様

- [docs/features/shift_display.md](docs/features/shift_display.md) - シフト表示
- [docs/features/ai_suggestion.md](docs/features/ai_suggestion.md) - AI補填提案
- [docs/features/csv_import.md](docs/features/csv_import.md) - CSVインポート

### ガイド

- [docs/guides/development-workflow.md](docs/guides/development-workflow.md) - 開発フロー詳細
- [docs/guides/setup.md](docs/guides/setup.md) - 環境セットアップ

### テンプレート

- [docs/templates/plan-template.md](docs/templates/plan-template.md) - 計画テンプレート
- [docs/templates/review-template.md](docs/templates/review-template.md) - レビューテンプレート

## 技術スタック

| カテゴリ | 技術 |
|---------|------|
| 言語 | Ruby 3.2.2 |
| フレームワーク | Rails 7.1 |
| データベース | PostgreSQL |
| フロントエンド | TailwindCSS, Hotwire |
| AI | Claude API (Anthropic) |

## 主要モデル

- **Store** - 店舗
- **StoreRequirement** - 店舗必要人数（曜日タイプ別）
- **Staff** - スタッフ（薬剤師/事務）
- **Shift** - シフト

## 主要サービス

- **ShortageCalculatorService** - 過不足算出
- **AiSuggestionService** - AI補填提案
- **CsvImportService** - CSVインポート

## ルーティング概要

```
/              → shifts#index（日別シフト）
/shifts/weekly → 週間一覧
/shifts/suggestions → AI提案
/imports/new   → CSVインポート
/stores        → 店舗管理
/staffs        → スタッフ管理
```

## 環境変数

```bash
ANTHROPIC_API_KEY=sk-ant-xxxxx  # AI提案機能に必要
```
