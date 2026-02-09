# 月間シフト表示機能

## タスク概要

### 目的
20日締めのシフト周期（21日〜翌20日）で、全店舗のシフト過不足をカレンダー形式で一覧表示する機能を追加する。

### 背景
現在は日別・週間表示のみで、1ヶ月単位でのシフト過不足を俯瞰できない。

### スコープ
- 月間ビュー（`/shifts/monthly`）の新規追加
- 20日締め周期の計算ロジック
- 既存の日別・週間表示は変更しない

---

## 20日締め周期の計算ロジック

```ruby
# 例: 2026年1月周期
# 開始日: 2025/12/21
# 終了日: 2026/1/20

def period_for(year, month)
  end_date = Date.new(year, month, 20)
  start_date = (end_date << 1) + 1  # 前月21日
  { start_date: start_date, end_date: end_date }
end
```

URLパラメータ: `?period=2026-01`（年-月形式）

---

## 修正ファイル一覧

### 新規作成
| ファイル | 内容 |
|---------|------|
| `app/views/shifts/monthly.html.erb` | 月間カレンダービュー |
| `app/helpers/shifts_helper.rb` | 周期計算ヘルパー |

### 修正
| ファイル | 変更内容 |
|---------|---------|
| `app/controllers/shifts_controller.rb` | `monthly` アクション追加 |
| `config/routes.rb` | `get :monthly` ルート追加 |
| `app/views/shifts/index.html.erb` | ナビゲーションに月間リンク追加 |

---

## 実装ステップ

### Step 1: ヘルパー作成
`app/helpers/shifts_helper.rb`

```ruby
module ShiftsHelper
  def period_for(year, month)
    end_date = Date.new(year, month, 20)
    start_date = (end_date << 1) + 1
    { start_date: start_date, end_date: end_date, year: year, month: month }
  end

  def current_period(date = Date.today)
    if date.day <= 20
      period_for(date.year, date.month)
    else
      next_month = date.next_month
      period_for(next_month.year, next_month.month)
    end
  end

  def period_label(year, month)
    "#{year}年#{month}月度"
  end
end
```

### Step 2: ルーティング追加
`config/routes.rb` に `get :monthly` を追加

### Step 3: コントローラーアクション追加
```ruby
def monthly
  @period = parse_period(params[:period])
  @monthly_data = ShortageCalculatorService.calculate_range(
    @period[:start_date],
    @period[:end_date]
  )
  @stores = Store.order(:code).all
end
```

### Step 4: ビュー作成
カレンダー形式（縦軸: 店舗、横軸: 日付）

```
|        | 12/21 | 12/22 | ... | 1/20 |
|--------|-------|-------|-----|------|
| 博多駅前 |  🔴   |  🟢   | ... |  🔴  |
| 天神    |  ⚪   |  🔴   | ... |  ⚪  |
```

ステータス: 🔴不足 / 🟢余剰 / ⚪充足

### Step 5: ナビゲーション更新
日別/週間/月間の切り替えリンクを追加

---

## 承認

- [ ] 人間の承認を得た
