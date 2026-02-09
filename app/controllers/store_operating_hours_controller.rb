# app/controllers/store_operating_hours_controller.rb
class StoreOperatingHoursController < ApplicationController
  before_action :set_store
  before_action :authorize_store_edit!

  def edit
    # 全曜日分のレコードを確保
    (0..6).each do |day|
      unless @store.store_operating_hours.any? { |oh| oh.day_of_week == day }
        @store.store_operating_hours.build(day_of_week: day)
      end
    end

    # 曜日順にソート
    @operating_hours = @store.store_operating_hours.sort_by(&:day_of_week)
  end

  def update
    if @store.update(store_params)
      redirect_to stores_path, notice: "#{@store.name}の営業時間を更新しました"
    else
      @operating_hours = @store.store_operating_hours.sort_by(&:day_of_week)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_store
    @store = Store.find(params[:store_id])
  end

  def authorize_store_edit!
    unless current_staff.can_manage_store?(@store)
      redirect_to stores_path, alert: '権限がありません'
    end
  end

  def store_params
    params.require(:store).permit(
      store_operating_hours_attributes: [
        :id, :day_of_week, :is_closed, :open_time, :close_time
      ]
    )
  end
end
