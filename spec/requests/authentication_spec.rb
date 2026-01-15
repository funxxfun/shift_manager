# spec/requests/authentication_spec.rb
require 'rails_helper'

RSpec.describe '認証アクセス制御', type: :request do
  let!(:staff) { create(:staff, code: 'TEST001', password: 'password123') }

  describe '未ログイン時' do
    it 'シフト一覧にアクセスするとログイン画面にリダイレクトされる' do
      get shifts_path
      expect(response).to redirect_to(login_path)
    end

    it 'CSVインポート画面にアクセスするとログイン画面にリダイレクトされる' do
      get new_import_path
      expect(response).to redirect_to(login_path)
    end

    it 'ログイン画面は認証なしでアクセスできる' do
      get login_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'ログイン時' do
    before do
      post login_path, params: { code: 'TEST001', password: 'password123' }
    end

    it 'シフト一覧にアクセスできる' do
      get shifts_path
      expect(response).to have_http_status(:success)
    end

    it 'CSVインポート画面にアクセスできる' do
      get new_import_path
      expect(response).to have_http_status(:success)
    end

    it 'ナビゲーションバーにユーザー名が表示される' do
      get shifts_path
      expect(response.body).to include(staff.name)
      expect(response.body).to include('ログアウト')
    end
  end
end
