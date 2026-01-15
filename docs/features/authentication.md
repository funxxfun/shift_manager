# ユーザー認証機能

## 概要

スタッフ（Staff）が社員コードでログインできる認証機能。
内部システムのため、パスワードは使用しない。

---

## 認証方式

| 項目 | 内容 |
|------|------|
| ログインID | 社員コード（staffs.code） |
| セッション管理 | Rails標準session |

---

## 画面

### ログイン画面 `/login`

- 社員コード入力フィールド
- ログインボタン
- エラーメッセージ表示

---

## ルーティング

| パス | メソッド | アクション | 説明 |
|------|----------|-----------|------|
| /login | GET | sessions#new | ログイン画面表示 |
| /login | POST | sessions#create | ログイン処理 |
| /logout | DELETE | sessions#destroy | ログアウト処理 |

---

## 認証フロー

```text
ユーザー → /login（GET）
        → 社員コード入力
        → /login（POST）
        → Staff.find_by(code:)
        → 成功: session[:staff_id] = staff.id → リダイレクト
        → 失敗: エラーメッセージ表示
```

---

## アクセス制御

### ApplicationController

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_staff!

  private

  def authenticate_staff!
    redirect_to login_path unless current_staff
  end

  def current_staff
    @current_staff ||= Staff.find_by(id: session[:staff_id])
  end

  helper_method :current_staff
end
```

### 認証不要なアクション

- SessionsController（ログイン画面自体）

---

## 実装ファイル

| ファイル | 説明 |
|---------|------|
| app/controllers/sessions_controller.rb | ログイン/ログアウト |
| app/controllers/application_controller.rb | 認証ヘルパー |
| app/views/sessions/new.html.erb | ログイン画面 |
| config/routes.rb | ルーティング追加 |

---

## テストアカウント

シードデータで作成されるテスト用アカウント。

| 社員コード | 名前 | 職種 | 所属店舗 |
|-----------|------|------|---------|
| E001 | 山田太郎 | 薬剤師 | 博多駅前店 |
| E002 | 佐藤花子 | 薬剤師 | 博多駅前店 |
| E003 | 鈴木一郎 | 事務 | 博多駅前店 |
| E004 | 田中美咲 | 薬剤師 | 天神店 |
| E005 | 高橋健太 | 薬剤師 | 天神店 |
| E006 | 伊藤さくら | 事務 | 天神店 |

**セットアップ:**

```bash
rails db:seed
```
