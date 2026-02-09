# app/controllers/support_requests_controller.rb
class SupportRequestsController < ApplicationController
  before_action :require_store_manager_or_above!
  before_action :set_support_request, only: [:approve, :reject]
  before_action :authorize_response!, only: [:approve, :reject]

  # 承認待ち一覧
  def index
    @support_requests = visible_pending_requests
                          .includes(shift: [:staff, :store])
                          .order(created_at: :desc)
  end

  # 応援要請作成
  def create
    @support_request = SupportRequest.new(support_request_params)
    @support_request.requested_by = current_staff

    if @support_request.save
      redirect_to suggestions_shifts_path(date: @support_request.date),
                  notice: '応援要請を送信しました'
    else
      redirect_to suggestions_shifts_path(date: params[:date]),
                  alert: @support_request.errors.full_messages.join(', ')
    end
  end

  # 承認
  def approve
    @support_request.approve!(current_staff, params[:note])
    redirect_to support_requests_path,
                notice: "#{@support_request.staff.name}の応援を承認しました"
  rescue => e
    redirect_to support_requests_path, alert: "承認に失敗しました: #{e.message}"
  end

  # 却下
  def reject
    @support_request.reject!(current_staff, params[:note])
    redirect_to support_requests_path,
                notice: "#{@support_request.staff.name}の応援要請を却下しました"
  end

  private

  def set_support_request
    @support_request = SupportRequest.find(params[:id])
  end

  # 承認/却下権限チェック
  # - 余剰側（from_store）の店舗管理者
  # - またはエリアマネージャー以上
  def authorize_response!
    from_store = @support_request.from_store

    unless current_staff.manager_or_above? ||
           current_staff.can_manage_store?(from_store)
      redirect_to support_requests_path, alert: '権限がありません'
    end
  end

  # 表示対象の承認待ち要請
  def visible_pending_requests
    if current_staff.manager_or_above?
      # エリアマネージャー以上は全件
      SupportRequest.pending
    else
      # 店舗管理者は自店舗スタッフへの要請のみ
      SupportRequest.pending_for_store(current_staff.base_store)
    end
  end

  def support_request_params
    params.require(:support_request).permit(:shift_id, :requesting_store_id, :reason)
  end
end
