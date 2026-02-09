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

  helper_method :current_staff, :pending_support_requests_count

  # 承認待ち件数
  def pending_support_requests_count
    return 0 unless current_staff&.store_manager_or_above?

    @pending_support_requests_count ||=
      if current_staff.manager_or_above?
        SupportRequest.pending.count
      else
        SupportRequest.pending_for_store(current_staff.base_store).count
      end
  end

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
