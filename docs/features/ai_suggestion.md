# AI補填提案機能

## 概要

人員不足の店舗に対し、余剰店舗からの補填を提案する。
Claude APIが設定されていればAI提案、なければルールベースで提案。

## 画面

### AI提案画面 (`/shifts/suggestions`)

- 当日の過不足サマリー
- 補填提案リスト
  - 移動元スタッフ名
  - 移動元店舗
  - 移動先店舗
  - 提案理由
  - 適用ボタン

## ルーティング

```ruby
get :suggestions
post :apply_suggestion
```

## コントローラー

```ruby
def suggestions
  @date = params[:date] ? Date.parse(params[:date]) : Date.today
  @shortage_data = ShortageCalculatorService.calculate_all(@date)
  @suggestions = AiSuggestionService.new.suggest(@date)
end

def apply_suggestion
  staff = Staff.find(params[:staff_id])
  to_store = Store.find(params[:to_store_id])
  date = Date.parse(params[:date])

  shift = staff.shift_on(date)
  shift.update!(store: to_store, status: :support)
  redirect_to shifts_path(date: date)
end
```

## サービス

### AiSuggestionService

**初期化:**
- 環境変数 `ANTHROPIC_API_KEY` からAPIキーを取得

**suggest(date):**
1. `ShortageCalculatorService` で過不足データ取得
2. 不足がなければ空配列を返す
3. 補填候補（余剰店舗のスタッフ）を抽出
4. API設定あり → `ai_suggestions`
5. API設定なし → `rule_based_suggestions`

**補填候補の抽出ロジック:**
```ruby
# 余剰店舗を特定
surplus_stores = shortage_data[:stores].select { |s| s[:status] == :surplus }

# 各余剰店舗のシフトをチェック
# 薬剤師余剰なら薬剤師を候補に
# 事務余剰なら事務を候補に
```

**ルールベース提案:**
- 単純に不足店舗に対し、候補者を先頭から割り当て
- 理由: 「〇〇店は薬剤師がX名余剰のため」

**AI提案:**
1. プロンプトを構築（状況・候補者・制約条件）
2. Claude API呼び出し
3. レスポンスからJSON抽出
4. 提案オブジェクトに変換

**プロンプト構成:**
```
役割: 調剤薬局チェーンのシフト管理AIアシスタント
入力: 日付、各店舗の状況、補填候補者
制約: 余剰店舗からのみ、同職種のみ、1人1日1店舗
出力: JSON形式の提案
```

## データ構造

**提案オブジェクト:**
```ruby
{
  staff: Staff,
  from_store: Store,
  to_store: Store,
  role: :pharmacist | :clerk,
  reason: String,
  date: Date
}
```

## エラーハンドリング

- API呼び出し失敗 → ルールベースにフォールバック
- JSONパースエラー → ルールベースにフォールバック
- 候補者なし → 空配列を返す

## 環境変数

```bash
ANTHROPIC_API_KEY=sk-ant-xxxxx
```

## 関連ファイル

- [app/controllers/shifts_controller.rb](../../app/controllers/shifts_controller.rb)
- [app/services/ai_suggestion_service.rb](../../app/services/ai_suggestion_service.rb)
- [app/views/shifts/suggestions.html.erb](../../app/views/shifts/suggestions.html.erb)
