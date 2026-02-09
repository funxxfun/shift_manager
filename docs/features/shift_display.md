# シフト表示機能

## 概要

日別・月別でシフトを表示し、各店舗のAM/PM別過不足状況を可視化する。

## 画面

### 日別ビュー (`/shifts`)

**サマリーカード:**
- 不足店舗数
- 余剰店舗数
- 要調整（薬剤師）
- 要調整（事務）

**店舗カード（AM/PM別）:**
- 店舗名
- AM/PMそれぞれのステータス（不足/余剰/充足/休業）
- 薬剤師: 現在人数 / 必要人数 (差分)
- 事務: 現在人数 / 必要人数 (差分)
- 勤務スタッフ一覧
- 不足時は補填必要の警告表示

**ナビゲーション:**
- 前日/翌日ボタン
- 月間一覧へのリンク
- AI提案へのリンク
- CSVインポートへのリンク

### 月間一覧 (`/shifts/monthly`)

- 1ヶ月分（16日〜翌月15日）の過不足を一覧表示
- 各日・各店舗のAM/PM別状況を俯瞰できる
- 凡例: 不足（赤）、余剰（緑）、充足（グレー）、休業（薄グレー）
- 月間サマリー（AM/PM別の不足・余剰件数）

## ルーティング

```ruby
resources :shifts, only: [:index] do
  collection do
    get :monthly
    get :suggestions
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

def monthly
  @period = parse_period(params[:period])
  @monthly_data = ShortageCalculatorService.calculate_range(
    @period[:start_date],
    @period[:end_date]
  )
  @stores = Store.order(:code).all
end
```

## サービス

### ShortageCalculatorService

**calculate_all(date):**
- 指定日の全店舗のAM/PM別過不足を算出
- 返り値:
  ```ruby
  {
    date: Date,
    stores: [
      {
        id: Integer,
        code: String,
        name: String,
        combined_status: :shortage | :surplus | :ok | :closed,
        am: {
          status: :shortage | :surplus | :ok | :closed,
          pharmacist: { current: Integer, required: Integer, diff: Integer },
          clerk: { current: Integer, required: Integer, diff: Integer },
          staff_list: { pharmacists: [String], clerks: [String] }
        },
        pm: {
          status: :shortage | :surplus | :ok | :closed,
          pharmacist: { current: Integer, required: Integer, diff: Integer },
          clerk: { current: Integer, required: Integer, diff: Integer },
          staff_list: { pharmacists: [String], clerks: [String] }
        }
      }
    ],
    summary: {
      am: { shortage_stores: Integer, surplus_stores: Integer, ... },
      pm: { shortage_stores: Integer, surplus_stores: Integer, ... },
      combined: {
        shortage_stores: Integer,
        surplus_stores: Integer,
        ok_stores: Integer,
        total_pharmacist_shortage: Integer,
        total_clerk_shortage: Integer
      }
    }
  }
  ```

**calculate_range(start_date, end_date):**
- 期間内の各日のAM/PM別データを配列で返す

## 曜日判定

曜日ごと（0:日〜6:土）× 時間帯（AM/PM）で必要人数を設定:
- `StoreRequirement` で曜日・時間帯別の必要人数を管理
- 必要人数が0の場合は「休業」として扱う

祝日判定は `holiday_jp` gem を使用。

## 関連ファイル

- [app/controllers/shifts_controller.rb](../../app/controllers/shifts_controller.rb)
- [app/services/shortage_calculator_service.rb](../../app/services/shortage_calculator_service.rb)
- [app/views/shifts/index.html.erb](../../app/views/shifts/index.html.erb)
- [app/views/shifts/monthly.html.erb](../../app/views/shifts/monthly.html.erb)
- [app/models/store.rb](../../app/models/store.rb)
- [app/models/store_requirement.rb](../../app/models/store_requirement.rb)
- [app/helpers/shifts_helper.rb](../../app/helpers/shifts_helper.rb)
