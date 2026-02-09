# app/controllers/stores_controller.rb
class StoresController < ApplicationController
  before_action :set_store, only: [:show, :edit, :update, :destroy]
  before_action :require_admin!, only: [:new, :create, :destroy]
  before_action :authorize_store_edit!, only: [:edit, :update]

  def index
    @stores = Store.includes(:store_requirements).order(:code)
  end

  def show
  end

  def new
    @store = Store.new
    build_requirements(@store)
  end

  def create
    @store = Store.new(store_params)
    
    if @store.save
      redirect_to stores_path, notice: '店舗を登録しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @store.store_requirements.load
    build_requirements(@store)
  end

  def update
    if @store.update(store_params)
      redirect_to stores_path, notice: '店舗を更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @store.destroy
    redirect_to stores_path, notice: '店舗を削除しました'
  end

  private

  def set_store
    @store = Store.find(params[:id])
  end

  def authorize_store_edit!
    unless current_staff.can_manage_store?(@store)
      redirect_to stores_path, alert: '権限がありません'
    end
  end

  def store_params
    params.require(:store).permit(
      :code, :name, :address, :nearest_station,
      store_requirements_attributes: [:id, :day_of_week, :shift_period, :pharmacist_count, :clerk_count, :_destroy]
    )
  end

  def build_requirements(store)
    # 7曜日 × 2時間帯（AM/PM）= 14レコード
    (0..6).each do |day|
      [:am, :pm].each do |period|
        unless store.store_requirements.any? { |r| r.day_of_week == day && r.shift_period == period.to_s }
          store.store_requirements.build(day_of_week: day, shift_period: period)
        end
      end
    end
  end
end
