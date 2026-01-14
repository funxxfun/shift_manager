# 応援シフト管理システム

調剤薬局チェーン向けの応援スタッフシフト管理システム

## 機能

- 勤次郎CSVからシフトデータをインポート
- 店舗ごとの必要人数と実際の配置を比較し、過不足を自動算出
- AIによる最適な補填提案

## 技術スタック

- Ruby on Rails 7.x
- PostgreSQL
- Claude API（AI提案機能）
- Tailwind CSS

## セットアップ

```bash
# リポジトリをクローン
git clone [repository_url]
cd shift_manager

# 依存関係インストール
bundle install

# データベース作成
rails db:create db:migrate db:seed

# サーバー起動
rails server
```

## 環境変数

```
ANTHROPIC_API_KEY=your_claude_api_key
```

## モデル構成

```
Store（店舗）
├── code: 店舗コード
├── name: 店舗名
└── store_requirements（必要人数）
    ├── day_type: 平日/土曜/日祝
    ├── pharmacist_count: 必要薬剤師数
    └── clerk_count: 必要事務数

Staff（スタッフ）
├── code: 社員コード
├── name: 氏名
├── role: 薬剤師/事務
└── base_store: 所属店舗

Shift（シフト）
├── date: 勤務日
├── staff: スタッフ
├── store: 店舗
├── start_time: 出勤時間
└── end_time: 退勤時間
```

## 使い方

1. 店舗マスタを登録（必要人数を設定）
2. 勤次郎からCSVをエクスポート
3. システムにCSVをアップロード
4. 過不足を確認
5. AI提案を確認し、補填を決定
