# app/models/support_request.rb
class SupportRequest < ApplicationRecord
  belongs_to :shift
  belongs_to :requesting_store, class_name: 'Store'
  belongs_to :requested_by, class_name: 'Staff'
  belongs_to :responded_by, class_name: 'Staff', optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2 }

  validates :shift_id, presence: true
  validates :requesting_store_id, presence: true
  validates :requested_by_id, presence: true
  validate :shift_not_already_requested, on: :create
  validate :different_stores

  scope :for_store, ->(store) {
    joins(shift: :store).where(shifts: { store_id: store.id })
  }
  scope :pending_for_store, ->(store) {
    pending.for_store(store)
  }

  # 承認処理
  def approve!(responder, note = nil)
    transaction do
      update!(
        status: :approved,
        responded_by: responder,
        response_note: note,
        responded_at: Time.current
      )
      # シフトを応援先に変更
      shift.update!(store: requesting_store, status: :support)
    end
  end

  # 却下処理
  def reject!(responder, note = nil)
    update!(
      status: :rejected,
      responded_by: responder,
      response_note: note,
      responded_at: Time.current
    )
  end

  # 元店舗（余剰側、スタッフを送り出す店舗）
  def from_store
    shift.store
  end

  # 対象スタッフ
  def staff
    shift.staff
  end

  # 対象日
  def date
    shift.date
  end

  # 時間帯ラベル
  def shift_period_label
    shift.shift_period_label
  end

  private

  def shift_not_already_requested
    return unless shift_id && requesting_store_id

    if SupportRequest.pending.exists?(shift_id: shift_id, requesting_store_id: requesting_store_id)
      errors.add(:base, '同じシフトへの応援要請が既に存在します')
    end
  end

  def different_stores
    return unless shift && requesting_store_id

    if shift.store_id == requesting_store_id
      errors.add(:requesting_store, 'は送り出し元店舗と同じにできません')
    end
  end
end
