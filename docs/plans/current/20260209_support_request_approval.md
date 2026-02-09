# 応援要請の承認機能

## 概要
AI補填提案の「適用」を2段階フロー（要請→承認）に変更し、余剰側店舗の管理者が承認できるようにする。

## フロー
```
現状: AI提案 → [適用] → シフト即変更

変更後:
AI提案 → [応援要請] → SupportRequest作成(pending)
                ↓
余剰側店舗管理者 → 承認待ち一覧で確認
                ↓
        [承認] → シフト変更 / [却下] → 要請却下
```

## 実装ステップ

### Step 1: マイグレーション作成
```ruby
# db/migrate/XXXXXXXX_create_support_requests.rb
create_table :support_requests do |t|
  t.references :shift, null: false, foreign_key: true
  t.references :requesting_store, null: false, foreign_key: { to_table: :stores }
  t.references :requested_by, null: false, foreign_key: { to_table: :staffs }
  t.references :responded_by, foreign_key: { to_table: :staffs }
  t.integer :status, default: 0, null: false  # pending/approved/rejected
  t.text :reason
  t.text :response_note
  t.datetime :responded_at
  t.timestamps
end
```

### Step 2: SupportRequestモデル作成
- `app/models/support_request.rb`
- ステータス: `{ pending: 0, approved: 1, rejected: 2 }`
- `approve!(responder)`: シフトを応援先に変更
- `reject!(responder)`: ステータスのみ変更

### Step 3: 関連モデル修正
- `app/models/shift.rb`: `has_many :support_requests`
- `app/models/store.rb`: `pending_support_requests`スコープ
- `app/models/staff.rb`: support_requests関連

### Step 4: コントローラ作成
- `app/controllers/support_requests_controller.rb`
  - `index`: 承認待ち一覧
  - `create`: 応援要請作成
  - `approve`: 承認
  - `reject`: 却下

### Step 5: ルーティング追加
```ruby
# config/routes.rb
resources :support_requests, only: [:index, :create] do
  member do
    post :approve
    post :reject
  end
end
# apply_suggestionは削除
```

### Step 6: ビュー作成・修正
- `app/views/support_requests/index.html.erb`: 承認待ち一覧画面（新規）
- `app/views/layouts/application.html.erb`: ナビにバッジ追加
- `app/views/shifts/suggestions.html.erb`: 「適用」→「応援要請」ボタン

### Step 7: AiSuggestionService修正
- 提案に`shift_id`を含める

### Step 8: ApplicationController修正
- `pending_support_requests_count`ヘルパー追加

### Step 9: テスト・動作確認

## 権限設計

| 操作 | store_manager | area_manager | admin |
|------|---------------|--------------|-------|
| 応援要請送信 | O（自店舗不足時） | O | O |
| 承認待ち一覧 | O（自店舗宛） | O（全件） | O |
| 承認/却下 | O（自店舗スタッフ） | O | O |

## 修正ファイル一覧

### 新規作成
- `db/migrate/XXXXXXXX_create_support_requests.rb`
- `app/models/support_request.rb`
- `app/controllers/support_requests_controller.rb`
- `app/views/support_requests/index.html.erb`

### 修正
- `app/models/shift.rb`
- `app/models/store.rb`
- `app/models/staff.rb`
- `config/routes.rb`
- `app/controllers/application_controller.rb`
- `app/views/layouts/application.html.erb`
- `app/views/shifts/suggestions.html.erb`
- `app/services/ai_suggestion_service.rb`
- `app/controllers/shifts_controller.rb`（apply_suggestion削除）
