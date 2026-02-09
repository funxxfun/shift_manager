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

  def monthly
    @period = parse_period(params[:period])
    @monthly_data = ShortageCalculatorService.calculate_range(
      @period[:start_date],
      @period[:end_date]
    )
    @stores = Store.order(:code).all
  end

  def suggestions
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    @shortage_data = ShortageCalculatorService.calculate_all(@date)
    @suggestions = AiSuggestionService.new.suggest(@date)
  end

  private

  def parse_period(period_param)
    if period_param.present?
      year, month = period_param.split('-').map(&:to_i)
      helpers.period_for(year, month)
    else
      helpers.current_period
    end
  end
end
