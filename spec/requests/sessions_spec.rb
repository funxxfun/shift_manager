# spec/requests/sessions_spec.rb
require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  let!(:staff) { create(:staff, code: 'TEST001', password: 'password123') }

  describe 'GET /login' do
    it 'ログイン画面が表示される' do
      get login_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('ログイン')
      expect(response.body).to include('社員コード')
    end
  end

  describe 'POST /login' do
    context '正しい認証情報の場合' do
      it 'ログインしてリダイレクトされる' do
        post login_path, params: { code: 'TEST001', password: 'password123' }
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include('ログインしました')
      end

      it 'セッションにstaff_idが保存される' do
        post login_path, params: { code: 'TEST001', password: 'password123' }
        expect(session[:staff_id]).to eq(staff.id)
      end
    end

    context '社員コードが間違っている場合' do
      it 'ログイン画面に戻りエラーが表示される' do
        post login_path, params: { code: 'WRONG', password: 'password123' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('社員コードまたはパスワードが正しくありません')
      end
    end

    context 'パスワードが間違っている場合' do
      it 'ログイン画面に戻りエラーが表示される' do
        post login_path, params: { code: 'TEST001', password: 'wrongpassword' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('社員コードまたはパスワードが正しくありません')
      end
    end
  end

  describe 'DELETE /logout' do
    before do
      post login_path, params: { code: 'TEST001', password: 'password123' }
    end

    it 'ログアウトしてログイン画面にリダイレクトされる' do
      delete logout_path
      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(response.body).to include('ログアウトしました')
    end

    it 'セッションがクリアされる' do
      delete logout_path
      expect(session[:staff_id]).to be_nil
    end
  end
end
