# 権限管理機能 実装計画

## 概要

Staffモデルに権限レベルを追加し、機能ごとにアクセス制御を実装する。

## 権限レベル

| レベル | 値 | できること |
|--------|-----|-----------|
| staff | 0 | シフト確認のみ |
| store_manager | 1 | 自店舗の必要人数設定 |
| area_manager | 2 | 全店舗の補填実行 |
| admin | 3 | 全機能（店舗作成/削除、CSVインポート、スタッフ管理） |

※エリアマネージャーは全店舗にアクセス可能（エリア区分なし）

## 実装内容

### 1. マイグレーション

- `permission_level` カラム追加（integer, default: 0, null: false）

### 2. Staffモデル

- `permission_level` enum追加
- 権限ヘルパーメソッド追加（admin?, manager_or_above?, can_manage_store?等）

### 3. ApplicationController

- 権限チェックメソッド追加（require_admin!, require_manager_or_above!等）

### 4. 各コントローラの権限制限

- StoresController: new/create/destroy → admin, edit/update → can_manage_store?
- ImportsController: 全アクション → admin
- ShiftsController: apply_suggestion → manager_or_above

### 5. ビューの権限分岐

- ナビゲーション: インポート・スタッフ管理は管理者のみ表示
- 店舗一覧: 新規ボタンは管理者のみ、編集ボタンは権限に応じて表示

### 6. シードデータ

- 管理者アカウント（ADMIN）追加
- エリアマネージャー（M001）追加
- 店舗管理者（E001, E004）設定

## 権限マトリクス

| 機能 | staff | store_manager | area_manager | admin |
|------|-------|---------------|--------------|-------|
| シフト確認 | ○ | ○ | ○ | ○ |
| AI提案表示 | ○ | ○ | ○ | ○ |
| 提案適用 | × | × | ○ | ○ |
| 店舗一覧表示 | ○ | ○ | ○ | ○ |
| 自店舗の編集 | × | ○ | ○ | ○ |
| 他店舗の編集 | × | × | ○ | ○ |
| 店舗作成/削除 | × | × | × | ○ |
| CSVインポート | × | × | × | ○ |
| スタッフ管理 | × | × | × | ○ |

## テストアカウント

| コード | 名前 | 権限 |
|--------|------|------|
| ADMIN | 管理者 | 本部管理者 |
| M001 | 斉藤マネージャー | エリアマネージャー |
| E001 | 山田太郎 | 店舗管理者（博多駅前店） |
| E004 | 田中美咲 | 店舗管理者（天神店） |
| E002〜 | その他 | 一般スタッフ |

## 実装状況

- [x] マイグレーション作成
- [x] Staffモデル修正
- [x] ApplicationController修正
- [x] StoresController修正
- [x] ImportsController修正
- [x] ShiftsController修正
- [x] ビューの権限分岐
- [x] シードデータ更新
- [x] テスト更新・通過
