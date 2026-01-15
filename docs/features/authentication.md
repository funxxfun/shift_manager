# ユーザー認証機能

## 概要

スタッフ（Staff）が社員コードとパスワードでログインできる認証機能。

---

## 認証方式

| 項目 | 内容 |
|------|------|
| ログインID | 社員コード（staffs.code） |
| パスワード | bcrypt + has_secure_password |
| セッション管理 | Rails標準session |

---

## データベース

### staffsテーブル（既存 + 追加）

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| code | string | NOT NULL, UNIQUE | 社員コード（ログインID） |
| password_digest | string | NOT NULL | パスワードハッシュ（**追加**） |

---

## 画面

### ログイン画面 `/login`

- 社員コード入力フィールド
- パスワード入力フィールド
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

```
ユーザー → /login（GET）
        → 社員コード・パスワード入力
        → /login（POST）
        → Staff.find_by(code:).authenticate(password)
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
| db/migrate/XXXXXX_add_password_digest_to_staffs.rb | マイグレーション |
| app/models/staff.rb | has_secure_password追加 |
| app/controllers/sessions_controller.rb | ログイン/ログアウト |
| app/controllers/application_controller.rb | 認証ヘルパー |
| app/views/sessions/new.html.erb | ログイン画面 |
| config/routes.rb | ルーティング追加 |

---

## 実装手順

1. マイグレーション作成・実行（password_digest追加）
2. Staffモデルに`has_secure_password`追加
3. SessionsController作成
4. ApplicationControllerに認証ヘルパー追加
5. ログイン画面作成
6. ルーティング追加
7. 各コントローラーにアクセス制御追加
