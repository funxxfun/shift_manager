# CSVインポート機能

## 概要

勤次郎（勤怠管理システム）からエクスポートしたCSVファイルをインポートし、
店舗・スタッフ・シフトデータを自動作成する。

## 画面

### インポート画面 (`/imports/new`)

- ファイル選択フォーム
- インポート実行ボタン

## ルーティング

```ruby
resources :imports, only: [:new, :create]
```

## コントローラー

```ruby
# ImportsController

def new
end

def create
  unless params[:file].present?
    redirect_to new_import_path, alert: 'ファイルを選択してください'
    return
  end

  service = CsvImportService.new
  result = service.import_kinjiro(params[:file])

  if result[:success]
    redirect_to shifts_path, notice: "#{result[:imported]}件のシフトをインポートしました"
  else
    redirect_to new_import_path, alert: "エラーが発生しました: #{result[:errors].join(', ')}"
  end
end
```

## サービス

### CsvImportService

**import_kinjiro(file):**
1. CSVを1行ずつ読み込み
2. 店舗を find_or_create
3. スタッフを find_or_create
4. シフトを find_or_create
5. エラーがあれば配列に追加
6. 結果を返す

**返り値:**
```ruby
{
  success: Boolean,
  imported: Integer,
  errors: [String]
}
```

## CSVフォーマット

**必須カラム:**

| カラム名 | 説明 | 例 |
|---------|------|-----|
| 店舗コード | 店舗の一意識別子 | S001 |
| 店舗名 | 店舗名 | 本店 |
| 社員コード | スタッフの一意識別子 | E001 |
| 社員名 | スタッフ名 | 山田太郎 |
| 職種 | 薬剤師 or 事務 | 薬剤師 |
| 勤務日 | YYYY-MM-DD形式 | 2025-01-15 |
| 出勤時間 | HH:MM形式 | 09:00 |
| 退勤時間 | HH:MM形式 | 18:00 |
| 休憩時間 | 分（整数） | 60 |

**サンプルCSV:**
```csv
店舗コード,店舗名,社員コード,社員名,職種,勤務日,出勤時間,退勤時間,休憩時間
S001,本店,E001,山田太郎,薬剤師,2025-01-15,09:00,18:00,60
S001,本店,E002,鈴木花子,事務,2025-01-15,09:00,17:00,60
S002,駅前店,E003,佐藤一郎,薬剤師,2025-01-15,10:00,19:00,60
```

## データ作成ロジック

### 店舗
```ruby
Store.find_or_create_by!(code: row['店舗コード']) do |store|
  store.name = row['店舗名']
end
```
- コードで既存チェック
- なければ新規作成

### スタッフ
```ruby
Staff.find_or_create_by!(code: row['社員コード']) do |staff|
  staff.name = row['社員名']
  staff.role = row['職種'] == '薬剤師' ? :pharmacist : :clerk
  staff.base_store = store
end
```
- コードで既存チェック
- なければ新規作成、所属店舗を設定

### シフト
```ruby
Shift.find_or_create_by!(date: date, staff: staff) do |shift|
  shift.store = store
  shift.start_time = row['出勤時間']
  shift.end_time = row['退勤時間']
  shift.break_minutes = row['休憩時間'].to_i
end
```
- 日付+スタッフで既存チェック（1人1日1シフト制約）
- なければ新規作成

## エラーハンドリング

- 各行でエラーが発生しても処理を継続
- エラーは配列に蓄積し、最後にまとめて表示
- エラーメッセージに行番号を含める

## 関連ファイル

- [app/controllers/imports_controller.rb](../../app/controllers/imports_controller.rb)
- [app/services/csv_import_service.rb](../../app/services/csv_import_service.rb)
- [app/views/imports/new.html.erb](../../app/views/imports/new.html.erb)
