# app/controllers/shifts_controller.rb
class ShiftsController < ApplicationController
  before_action :require_store_manager_or_above!, only: [:apply_suggestion]
  before_action :authorize_suggestion!, only: [:apply_suggestion]

  def index
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    @shortage_data = ShortageCalculatorService.calculate_all(@date)
  end

  def weekly
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_week
    @end_date = @start_date + 6.days
    @weekly_data = ShortageCalculatorService.calculate_range(@start_date, @end_date)
  end

  def suggestions
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    @shortage_data = ShortageCalculatorService.calculate_all(@date)
    @suggestions = AiSuggestionService.new.suggest(@date)
  end

  def apply_suggestion
    staff = Staff.find(params[:staff_id])
    to_store = Store.find(params[:to_store_id])
    date = Date.parse(params[:date])

    shift = staff.shift_on(date)

    if shift
      shift.update!(store: to_store, status: :support)
      redirect_to shifts_path(date: date), notice: "#{staff.name}を#{to_store.name}に移動しました"
    else
      redirect_to suggestions_shifts_path(date: date), alert: "シフトが見つかりません"
    end
  end

  private

  def authorize_suggestion!
    return if current_staff.manager_or_above?

    # 店舗管理者は自店舗のスタッフのみ補填可能
    staff = Staff.find(params[:staff_id])
    date = Date.parse(params[:date])
    shift = staff.shift_on(date)

    unless shift && shift.store_id == current_staff.base_store_id
      redirect_to suggestions_shifts_path(date: date), alert: '自店舗のスタッフのみ補填できます'
    end
  end
end
