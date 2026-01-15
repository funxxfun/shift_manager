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
end
