# シフト表示機能

## 概要

日別・週別でシフトを表示し、各店舗の過不足状況を可視化する。

## 画面

### 日別ビュー (`/shifts`)

**サマリーカード:**
- 不足店舗数
- 余剰店舗数
- 要調整（薬剤師）
- 要調整（事務）

**店舗カード:**
- 店舗名
- ステータス（不足/余剰/充足）
- 薬剤師: 現在人数 / 必要人数 (差分)
- 事務: 現在人数 / 必要人数 (差分)
- 勤務スタッフ一覧
- 不足時は補填必要の警告表示

**ナビゲーション:**
- 前日/翌日ボタン
- 週間一覧へのリンク
- AI提案へのリンク
- CSVインポートへのリンク

### 週間一覧 (`/shifts/weekly`)

- 1週間分の過不足を一覧表示
- 各日の状況を俯瞰できる

## ルーティング

```ruby
resources :shifts, only: [:index] do
  collection do
    get :weekly
    get :suggestions
    post :apply_suggestion
  end
end
```

## コントローラー

```ruby
# ShiftsController

def index
  @date = params[:date] ? Date.parse(params[:date]) : Date.today
  @shortage_data = ShortageCalculatorService.calculate_all(@date)
end

def weekly
  @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_week
  @end_date = @start_date + 6.days
  @weekly_data = ShortageCalculatorService.calculate_range(@start_date, @end_date)
end
```

## サービス

### ShortageCalculatorService

**calculate_all(date):**
- 指定日の全店舗の過不足を算出
- 返り値:
  ```ruby
  {
    date: Date,
    stores: [
      {
        id: Integer,
        code: String,
        name: String,
        status: :shortage | :surplus | :ok,
        pharmacist: { current: Integer, required: Integer, diff: Integer },
        clerk: { current: Integer, required: Integer, diff: Integer },
        staff_list: { pharmacists: [String], clerks: [String] }
      }
    ],
    summary: {
      shortage_stores: Integer,
      surplus_stores: Integer,
      ok_stores: Integer,
      total_pharmacist_shortage: Integer,
      total_clerk_shortage: Integer
    }
  }
  ```

**calculate_range(start_date, end_date):**
- 期間内の各日のデータを配列で返す

## 曜日タイプ判定

`Store.day_type_for(date)` で判定:
- 祝日 → :holiday
- 日曜 → :holiday
- 土曜 → :saturday
- 平日 → :weekday

祝日判定は `holiday_jp` gem を使用。

## 関連ファイル

- [app/controllers/shifts_controller.rb](../../app/controllers/shifts_controller.rb)
- [app/services/shortage_calculator_service.rb](../../app/services/shortage_calculator_service.rb)
- [app/views/shifts/index.html.erb](../../app/views/shifts/index.html.erb)
- [app/models/store.rb](../../app/models/store.rb)
