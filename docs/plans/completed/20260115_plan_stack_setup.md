# Plan Stack導入・ドキュメント整備 - 実装計画

## タスク概要

- **目的**: Plan Stack方法論の導入とプロジェクトドキュメントの整備
- **背景**: AI開発において計画を成果物として蓄積し、コンテキストを保持する仕組みを構築
- **スコープ**: ディレクトリ構造作成、テンプレート作成、既存実装のドキュメント化

## 調査結果

### 関連する過去のplan

- なし（初回導入）

### 現在のプロジェクト状態

- Rails 7.1 + PostgreSQL
- 実装済み機能:
  - CSVインポート（勤次郎形式）
  - 過不足算出・表示（日別/週間）
  - AI補填提案（Claude API / ルールベース）
- 未実装機能:
  - ユーザー認証・権限
  - 店舗間共有

### ヒアリング内容

- 現状: Googleドライブ + 勤次郎 + 電話調整（約7時間/週）
- 課題: 消極的な補填対応、電話交渉の困難さ、労働力の偏り
- 目標: 過不足自動算出、店舗間共有、管理者による自動補填

## 実装方針

### 選択したアプローチ

Plan Stackのベストプラクティスに従い、以下の構造を採用:

```
docs/
├── plans/
│   ├── current/      # 進行中の計画
│   └── completed/    # 完了した計画
├── features/         # 機能仕様
├── architecture/     # アーキテクチャ（1ファイルに統合）
├── guides/           # 開発ガイド
└── templates/        # テンプレート
```

## 修正ファイル一覧

### 新規作成

| ファイル | 内容 |
|---------|------|
| CLAUDE.md | エントリーポイント、Plan Stackワークフロー |
| docs/architecture/README.md | 背景・設計・DB・実装状況（統合版） |
| docs/features/shift_display.md | シフト表示機能仕様 |
| docs/features/ai_suggestion.md | AI補填提案機能仕様 |
| docs/features/csv_import.md | CSVインポート機能仕様 |
| docs/guides/development-workflow.md | 開発フロー詳細 |
| docs/guides/setup.md | 環境セットアップ |
| docs/templates/plan-template.md | 計画テンプレート |
| docs/templates/review-template.md | レビューテンプレート |

### 削除（統合のため）

| ファイル | 理由 |
|---------|------|
| docs/architecture/overview.md | README.mdに統合 |
| docs/architecture/database.md | README.mdに統合 |
| docs/architecture/background.md | README.mdに統合 |
| docs/architecture/requirements.md | README.mdに統合 |

## 実装ステップ

1. [x] ディレクトリ構造の作成
2. [x] CLAUDE.mdの作成
3. [x] アーキテクチャドキュメント作成
4. [x] 機能仕様ドキュメント作成
5. [x] テンプレート作成
6. [x] ガイド作成
7. [x] ヒアリング内容の反映
8. [x] アーキテクチャファイルの統合

## 考慮事項

### ドキュメント構造

- architectureは1ファイル（README.md）に統合し、見通しを良くする
- featuresは機能ごとに分割（将来の拡張性）
- plansは時系列で蓄積

## 完了

- 実装日: 2026-01-15
- 所要時間: 1セッション
