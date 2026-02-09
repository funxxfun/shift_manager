# AM/PM単位シフト管理への変更

## 概要
- AM/PMの境界: 12:00（正午）
- 同一人物が1日にAMとPM両方勤務可能
- 必要人数設定: AM/PM別々に設定
- 既存データは「終日(full_day)」として扱う

---

## データベース変更

### shifts テーブル
```ruby
add_column :shifts, :shift_period, :integer, default: 2  # 0:am, 1:pm, 2:full_day
remove_index :shifts, [:date, :staff_id]
add_index :shifts, [:date, :staff_id, :shift_period], unique: true
```

### store_requirements テーブル
```ruby
add_column :store_requirements, :shift_period, :integer, default: 2
remove_index :store_requirements, [:store_id, :day_type]
add_index :store_requirements, [:store_id, :day_type, :shift_period], unique: true
```

---

## 実装ステップ

### Step 1: マイグレーション作成
- `add_shift_period_to_shifts.rb`
- `add_shift_period_to_store_requirements.rb`

### Step 2: モデル変更
| ファイル | 変更内容 |
|---------|---------|
| `app/models/shift.rb` | enum追加、スコープ追加、バリデーション変更 |
| `app/models/store_requirement.rb` | enum追加 |
| `app/models/store.rb` | `shortage_on(date, period)` 対応 |
| `app/models/staff.rb` | `shift_on(date, period)` 対応 |

### Step 3: サービス変更
| ファイル | 変更内容 |
|---------|---------|
| `app/services/shortage_calculator_service.rb` | AM/PM別計算、レスポンス構造変更 |
| `app/services/ai_suggestion_service.rb` | AM/PM別提案 |
| `app/services/csv_import_service.rb` | shift_period自動判定 |

### Step 4: コントローラー・ビュー変更
| ファイル | 変更内容 |
|---------|---------|
| `app/controllers/shifts_controller.rb` | shift_periodパラメータ対応 |
| `app/views/shifts/monthly.html.erb` | セルをAM/PM上下分割 |
| `app/views/shifts/index.html.erb` | AM/PM別表示 |
| `app/views/shifts/suggestions.html.erb` | AM/PMラベル追加 |
| `app/helpers/shifts_helper.rb` | ツールチップ追加 |

---

## レスポンス構造（変更後）

```ruby
{
  date: Date,
  stores: [
    {
      id: 1, code: "S001", name: "本店",
      am: { status: :shortage, pharmacist: {...}, clerk: {...}, staff_list: {...} },
      pm: { status: :surplus, pharmacist: {...}, clerk: {...}, staff_list: {...} },
      combined_status: :shortage
    }
  ],
  summary: {
    am: { shortage_stores: 2, surplus_stores: 1, ... },
    pm: { shortage_stores: 1, surplus_stores: 2, ... },
    combined: { ... }
  }
}
```

---

## 月間カレンダー表示

各セルをAM/PM上下分割:
```
┌───┐
│ AM│ ← 赤/緑/灰
├───┤
│ PM│ ← 赤/緑/灰
└───┘
```

---

## 後方互換性
- 既存シフト: 全て`full_day`（終日）として動作
- 既存必要人数設定: 全て`full_day`として動作
- `full_day`シフトがある日は、AM/PMシフト作成不可（バリデーション）

---

## 承認
- [ ] 人間の承認を得た
