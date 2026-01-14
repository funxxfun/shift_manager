# app/controllers/shifts_controller.rb
class ShiftsController < ApplicationController
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
end
