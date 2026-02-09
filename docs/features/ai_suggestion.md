# AI補填提案機能

## 概要

人員不足の店舗に対し、余剰店舗からの補填を提案する。
Claude APIが設定されていればAI提案、なければルールベースで提案。
AM/PM別に提案を行い、応援要請→承認のフローで適用する。

## 画面

### AI提案画面 (`/shifts/suggestions`)

- 当日の過不足サマリー（AM/PM統合）
- AM提案リスト / PM提案リスト
  - 移動元スタッフ名
  - 移動元店舗
  - 移動先店舗
  - 提案理由
  - 応援要請ボタン（エリアマネージャー以上のみ表示）

### 応援要請承認画面 (`/support_requests`)

- 承認待ちの応援要請一覧
- 各要請に対して承認ボタン
- 承認すると対象シフトが要請元店舗に移動

## ルーティング

```ruby
resources :shifts, only: [:index] do
  collection do
    get :suggestions
  end
end

resources :support_requests, only: [:index, :create] do
  member do
    post :approve
  end
end
```

## コントローラー

```ruby
# ShiftsController
def suggestions
  @date = params[:date] ? Date.parse(params[:date]) : Date.today
  @shortage_data = ShortageCalculatorService.calculate_all(@date)
  @suggestions = AiSuggestionService.new.suggest(@date)
end

# SupportRequestsController
def create
  shift = Shift.find(params[:shift_id])
  to_store = Store.find(params[:to_store_id])

  SupportRequest.create!(
    shift: shift,
    requesting_store: to_store,
    requested_by: current_staff,
    reason: params[:reason]
  )
  redirect_to suggestions_shifts_path(date: shift.date)
end

def approve
  @support_request = SupportRequest.find(params[:id])
  @support_request.approve!(current_staff)
  redirect_to support_requests_path
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
# AM/PMそれぞれで余剰店舗を特定
[:am, :pm].each do |period|
  surplus_stores = shortage_data[:stores].select { |s| s[period][:status] == :surplus }

  # 各余剰店舗のシフトをチェック
  # 薬剤師余剰なら薬剤師を候補に
  # 事務余剰なら事務を候補に

  # 余剰数が多い店舗を優先（降順ソート）
  candidates.sort_by { |c| -c[:surplus] }
end
```

**ルールベース提案:**
- 余剰数が多い店舗から優先的に割り当て
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
  shift: Shift,
  from_store: Store,
  to_store: Store,
  role: :pharmacist | :clerk,
  shift_period: :am | :pm,
  reason: String,
  date: Date
}
```

**応援要請（SupportRequest）:**
```ruby
{
  shift: Shift,              # 対象シフト
  requesting_store: Store,    # 要請元（不足店舗）
  requested_by: Staff,        # 要請者
  responded_by: Staff,        # 承認者（承認後）
  status: :pending | :approved | :rejected,
  reason: String,             # 要請理由
  response_note: String,      # 承認時コメント
  responded_at: DateTime      # 承認日時
}
```

## 権限

| 操作 | staff | store_manager | area_manager | admin |
|------|-------|---------------|--------------|-------|
| AI提案閲覧 | O | O | O | O |
| 応援要請送信 | - | - | O | O |
| 承認待ち一覧閲覧 | - | O（自店舗宛） | O | O |
| 応援要請承認 | - | O（自店舗スタッフ） | O | O |

## エラーハンドリング

- API呼び出し失敗 → ルールベースにフォールバック
- JSONパースエラー → ルールベースにフォールバック
- 候補者なし → 空配列を返す

## 環境変数

```bash
ANTHROPIC_API_KEY=sk-ant-xxxxx
```

## ルールベース vs AI API 比較

### 機能比較

| 項目 | ルールベース | AI API |
|------|-------------|--------|
| **マッチング** | 余剰数が多い店舗を優先して割り当て | 最適な組み合わせを判断 |
| **理由説明** | 定型文（「○○店は薬剤師が△名余剰のため」） | 状況に応じた自然な説明 |
| **考慮要素** | 職種の一致のみ | 複数要素を総合判断可能 |
| **API費用** | 無料 | 従量課金 |
| **レスポンス速度** | 高速 | やや遅い（API呼び出し） |

### AI APIで可能になること

#### 1. インテリジェントなマッチング

```
例: 3店舗で薬剤師不足、2店舗で余剰がある場合

ルールベース → 余剰数が多い店舗を優先して割り当て
AI → 「A店はB店に近いのでAさんを、C店は混雑時間帯が違うのでDさんを」
```

#### 2. コンテキストを考慮した提案理由

```
ルールベース: 「駅前店は薬剤師が1名余剰のため」
AI: 「駅前店は午後の患者数が少なく余裕があるため、
      混雑が予想される中央店への応援が効果的です」
```

#### 3. 制約条件の柔軟な解釈

プロンプトで指示した制約をAIが理解して判断：
- 同職種のみ（薬剤師→薬剤師、事務→事務）
- 1人のスタッフは1日1店舗のみ
- 余剰店舗からのみ補填可能

### 使い分けの目安

| シーン | 推奨 |
|--------|------|
| 店舗数が少ない（5店舗以下） | ルールベースで十分 |
| 店舗数が多く組み合わせが複雑 | AI API推奨 |
| 提案理由を人間が読んで納得したい | AI API推奨 |
| コストを抑えたい | ルールベース |
| 将来的に距離・勤務時間などの条件を追加したい | AI API推奨 |

### 切り替え方法

コード変更なしで、環境変数の設定のみで切り替わる：

```bash
# AI APIを使用する場合
export ANTHROPIC_API_KEY=sk-ant-xxxxx

# ルールベースを使用する場合（APIキーを設定しない）
unset ANTHROPIC_API_KEY
```

### コード上の分岐点

`app/services/ai_suggestion_service.rb` の `suggest` メソッド（18-22行目）:

```ruby
if @api_key.present?
  ai_suggestions(date, shortage_data, candidates)
else
  rule_based_suggestions(date, shortage_data, candidates)
end
```

## 関連ファイル

- [app/controllers/shifts_controller.rb](../../app/controllers/shifts_controller.rb)
- [app/controllers/support_requests_controller.rb](../../app/controllers/support_requests_controller.rb)
- [app/models/support_request.rb](../../app/models/support_request.rb)
- [app/services/ai_suggestion_service.rb](../../app/services/ai_suggestion_service.rb)
- [app/views/shifts/suggestions.html.erb](../../app/views/shifts/suggestions.html.erb)
- [app/views/support_requests/index.html.erb](../../app/views/support_requests/index.html.erb)
