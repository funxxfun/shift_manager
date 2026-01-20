# app/controllers/staffs_controller.rb
class StaffsController < ApplicationController
  before_action :require_admin!
  before_action :set_staff, only: [:show, :edit, :update, :destroy]

  def index
    @staffs = Staff.includes(:base_store).order(:code)
  end

  def show
  end

  def new
    @staff = Staff.new
  end

  def create
    @staff = Staff.new(staff_params)

    if @staff.save
      redirect_to staffs_path, notice: 'スタッフを登録しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @staff.update(staff_params)
      redirect_to staffs_path, notice: 'スタッフを更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @staff.destroy
    redirect_to staffs_path, notice: 'スタッフを削除しました'
  end

  private

  def set_staff
    @staff = Staff.find(params[:id])
  end

  def staff_params
    params.require(:staff).permit(:code, :name, :role, :base_store_id, :permission_level)
  end
end
