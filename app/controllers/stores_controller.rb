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
    @store.store_requirements.build(day_type: :weekday)
    @store.store_requirements.build(day_type: :saturday)
    @store.store_requirements.build(day_type: :holiday)
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
    # 関連を明示的にロード
    @store.store_requirements.load

    # 不足している曜日タイプがあれば追加
    %i[weekday saturday holiday].each do |day_type|
      unless @store.store_requirements.any? { |r| r.day_type == day_type.to_s }
        @store.store_requirements.build(day_type: day_type)
      end
    end
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
      store_requirements_attributes: [:id, :day_type, :pharmacist_count, :clerk_count, :_destroy]
    )
  end
end
