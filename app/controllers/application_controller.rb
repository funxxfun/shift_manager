# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_staff!

  private

  def authenticate_staff!
    redirect_to login_path, alert: 'ログインしてください' unless current_staff
  end

  def current_staff
    @current_staff ||= Staff.find_by(id: session[:staff_id])
  end

  helper_method :current_staff

  # 権限チェックメソッド
  def require_admin!
    unless current_staff&.admin?
      redirect_to root_path, alert: '権限がありません'
    end
  end

  def require_manager_or_above!
    unless current_staff&.manager_or_above?
      redirect_to root_path, alert: '権限がありません'
    end
  end

  def require_store_manager_or_above!
    unless current_staff&.store_manager_or_above?
      redirect_to root_path, alert: '権限がありません'
    end
  end
end
