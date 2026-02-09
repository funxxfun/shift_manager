# アーキテクチャ

## システム概要

調剤薬局チェーン向けのシフト管理システム。
複数店舗間の人員過不足を可視化し、AIによる補填提案を行う。

---

## 1. プロジェクト背景

### 現在のシフト管理フロー

```
┌─────────────────────────────────────────────────────────────┐
│                    現在のワークフロー                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [勤次郎] ──→ 翌月シフトを店舗ごとに入力                      │
│      │                                                      │
│      ▼                                                      │
│  [Googleドライブ] ──→ 不足枠を店舗間で共有                   │
│      │                                                      │
│      ├──→ 一次対応：各店舗が補填可能なら枠を埋める            │
│      │                                                      │
│      └──→ 二次対応：埋まらない場合                           │
│              │                                              │
│              ▼                                              │
│          エリアマネージャー・本部役員が                       │
│          勤次郎を確認し、各店舗に電話で依頼                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 問題点

| 問題 | 詳細 | 影響 |
|------|------|------|
| 消極的な補填対応 | 店舗からの積極的な立候補が少ない | 本部・マネージャーの負担増 |
| 電話での調整 | 直接電話で応援可能か確認している | 約 **7時間/週**（1時間 × 7人）|
| 交渉の困難さ | あらゆる口実で断られる | 時間と労力の浪費 |
| 労働力の偏り | 店舗間で労働力に偏りがある | 適正人数の判断が困難 |

### 工数の内訳

- エリアマネージャー・本部役員 **7名**
- 週あたり **約1時間/人**
- 月換算: **約28時間/月**
- 年換算: **約336時間/年**

### 実現したいこと

1. **過不足の自動算出** - 勤次郎のシフトデータ × 各店舗の必要人数
2. **店舗間共有機能の維持** - Googleドライブでの運用を踏襲
3. **管理者による自動補填** - 過剰店舗から不足店舗への自動補填

### 期待される効果

| 効果 | 説明 |
|------|------|
| 工数削減 | 本部・マネージャーのシフト調整時間を削減 |
| コスト把握 | 人件費を正確に把握 |
| 労働力の平準化 | 店舗間の偏りを解消 |
| 客観的基準 | 「自動算出」という不動の基準で応援業務を断れなくする |
| 緊急対応 | 急遽の人員不足にも対応可能 |

### 外部システム連携

- **勤次郎** (<https://www.kinjiro-e.com/>)
  - 勤怠管理システム
  - CSVエクスポート → 本システムにインポート

---

## 2. 技術スタック

| カテゴリ | 技術 |
|---------|------|
| 言語 | Ruby 3.2.2 |
| フレームワーク | Rails 7.1 |
| データベース | PostgreSQL |
| フロントエンド | TailwindCSS, Hotwire (Turbo/Stimulus) |
| JavaScript | Importmap |
| AI | Claude API (Anthropic) |
| 祝日判定 | holiday_jp |

---

## 3. ディレクトリ構造

```
app/
├── controllers/
│   ├── shifts_controller.rb           # シフト表示
│   ├── support_requests_controller.rb # 応援要請管理
│   ├── imports_controller.rb          # CSVインポート
│   └── stores_controller.rb           # 店舗管理
├── models/
│   ├── shift.rb                  # シフト
│   ├── staff.rb                  # スタッフ（薬剤師/事務）
│   ├── store.rb                  # 店舗
│   ├── store_requirement.rb      # 店舗必要人数
│   └── support_request.rb        # 応援要請
├── services/
│   ├── ai_suggestion_service.rb      # AI補填提案
│   ├── csv_import_service.rb         # CSVインポート
│   └── shortage_calculator_service.rb # 過不足算出
└── views/
    ├── shifts/
    │   ├── index.html.erb        # 日別ビュー
    │   ├── monthly.html.erb      # 月間一覧
    │   └── suggestions.html.erb  # AI提案画面
    ├── support_requests/
    │   └── index.html.erb        # 承認待ち一覧
    ├── imports/
    │   └── new.html.erb          # CSVインポート画面
    └── stores/
        ├── index.html.erb        # 店舗一覧
        ├── show.html.erb         # 店舗詳細
        ├── new.html.erb          # 店舗登録
        ├── edit.html.erb         # 店舗編集
        └── _form.html.erb        # 共通フォーム
```

---

## 4. データベース設計

### ER図

```
stores ─────────< store_requirements
   │
   │ base_store_id
   ▼
staffs ─────────< shifts >───────── stores
```

### テーブル定義

#### stores（店舗）

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | |
| code | string | NOT NULL, UNIQUE | 店舗コード |
| name | string | NOT NULL | 店舗名 |
| address | string | | 住所 |
| nearest_station | string | | 最寄り駅 |

#### store_requirements（店舗必要人数）

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | |
| store_id | bigint | FK, NOT NULL | 店舗 |
| day_of_week | integer | NOT NULL | 曜日（0:日〜6:土） |
| shift_period | string | NOT NULL | 時間帯（am/pm） |
| pharmacist_count | integer | NOT NULL | 必要薬剤師数 |
| clerk_count | integer | NOT NULL | 必要事務数 |

制約: UNIQUE(store_id, day_of_week, shift_period)

#### staffs（スタッフ）

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | |
| code | string | NOT NULL, UNIQUE | 社員コード |
| name | string | NOT NULL | 氏名 |
| role | integer | NOT NULL | 職種（0:薬剤師, 1:事務） |
| base_store_id | bigint | FK | 所属店舗 |

#### shifts（シフト）

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | |
| date | date | NOT NULL | 勤務日 |
| staff_id | bigint | FK, NOT NULL | スタッフ |
| store_id | bigint | FK, NOT NULL | 勤務店舗 |
| shift_period | string | NOT NULL | 時間帯（am/pm/full） |
| start_time | time | | 出勤時間 |
| end_time | time | | 退勤時間 |
| break_minutes | integer | DEFAULT 60 | 休憩時間（分） |
| status | integer | DEFAULT 0 | 0:予定, 1:確定, 2:応援 |

制約: UNIQUE(date, staff_id, shift_period) - 1人1日1時間帯1シフト

#### support_requests（応援要請）

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | |
| shift_id | bigint | FK, NOT NULL | 対象シフト |
| requesting_store_id | bigint | FK, NOT NULL | 要請元店舗（不足店舗） |
| requested_by_id | bigint | FK, NOT NULL | 要請者 |
| responded_by_id | bigint | FK | 承認者 |
| status | integer | DEFAULT 0 | 0:pending, 1:approved, 2:rejected |
| reason | text | | 要請理由 |
| response_note | text | | 承認/却下時のコメント |
| responded_at | datetime | | 承認/却下日時 |

---

## 5. サービス層設計

### ShortageCalculatorService

- 日付を受け取り、全店舗の過不足を算出
- 曜日タイプ（平日/土曜/日祝）に応じた必要人数を参照
- 薬剤師・事務それぞれの過不足を計算

### AiSuggestionService

- 過不足データから補填候補を抽出
- Claude APIがあればAI提案、なければルールベース提案
- 余剰店舗→不足店舗への移動を提案

### CsvImportService

- 勤次郎形式のCSVを解析
- 店舗・スタッフ・シフトを自動作成/更新

---

## 6. 主要なフロー

### シフト確認フロー

```
ユーザー → ShiftsController#index
         → ShortageCalculatorService.calculate_all
         → 過不足データをビューに表示
```

### AI提案・応援要請フロー

```
管理者 → ShiftsController#suggestions
       → AiSuggestionService.suggest
       → (Claude API or ルールベース)
       → 提案をビューに表示
       → SupportRequestsController#create で応援要請作成

余剰店舗管理者 → SupportRequestsController#index
              → 承認待ち一覧を表示
              → approve で承認 → シフトを移動先店舗に変更
```

### CSVインポートフロー

```
ユーザー → ImportsController#create
         → CsvImportService.import_kinjiro
         → 店舗/スタッフ/シフト作成
         → 結果表示
```

---

## 7. 実装状況

| カテゴリ | 機能 | 状態 |
|---------|------|------|
| データ管理 | CSVインポート | 実装済み |
| データ管理 | 店舗必要人数設定（曜日×AM/PM） | 実装済み |
| 過不足算出 | 日別表示（AM/PM別） | 実装済み |
| 過不足算出 | 月間一覧 | 実装済み |
| 補填 | 店舗間共有 | 未実装 |
| 補填 | AI提案 | 実装済み |
| 補填 | 応援要請・承認フロー | 実装済み |
| 権限 | ユーザー認証 | 実装済み |
| 権限 | 権限管理 | 実装済み |

---

## 8. 今後の開発優先度

### Phase 1（必須）

1. ユーザー認証
2. 権限管理
3. 店舗必要人数設定UI

### Phase 2（重要）

1. 店舗間共有機能
2. 自動補填の一括適用
3. 通知機能

### Phase 3（あると便利）

1. レポート・分析機能
2. 勤次郎との自動連携
3. モバイル対応

---

## 9. 権限設計

| 権限 | できること |
|------|-----------|
| 店舗スタッフ | 自店舗のシフト確認 |
| 店舗管理者 | 自店舗のシフト確認、自店舗スタッフへの応援要請の承認 |
| エリアマネージャー | 全店舗閲覧、必要人数設定、AI提案からの応援要請送信、全店舗の応援要請承認 |
| 本部管理者 | 全権限（店舗CRUD含む） |

### 機能別権限マトリクス

| 機能 | staff | store_manager | area_manager | admin |
|------|-------|---------------|--------------|-------|
| シフト閲覧 | 自店舗 | 自店舗 | 全店舗 | 全店舗 |
| 月間一覧閲覧 | O | O | O | O |
| 必要人数設定 | - | - | O | O |
| AI提案閲覧 | O | O | O | O |
| 応援要請送信 | - | - | O | O |
| 応援要請承認 | - | 自店舗スタッフ | O | O |
| 店舗登録・削除 | - | - | - | O |
| スタッフ管理 | - | 自店舗 | 担当エリア | O |
