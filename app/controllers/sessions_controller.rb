# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  skip_before_action :authenticate_staff!, only: [:new, :create]

  def new
  end

  def create
    staff = Staff.find_by(code: params[:code])

    if staff&.authenticate(params[:password])
      session[:staff_id] = staff.id
      redirect_to root_path, notice: 'ログインしました'
    else
      flash.now[:alert] = '社員コードまたはパスワードが正しくありません'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:staff_id] = nil
    redirect_to login_path, notice: 'ログアウトしました'
  end
end
