require 'rails_helper'

RSpec.describe Shift, type: :model do
  describe 'validations' do
    subject { build(:shift) }

    it { is_expected.to be_valid }

    it 'dateが必須' do
      subject.date = nil
      expect(subject).not_to be_valid
    end

    it '同日に同じスタッフの重複シフトは不可' do
      staff = create(:staff)
      store = create(:store)
      date = Date.current

      create(:shift, staff: staff, store: store, date: date)
      duplicate = build(:shift, staff: staff, store: store, date: date)
      expect(duplicate).not_to be_valid
    end
  end

  describe 'scopes' do
    let(:store) { create(:store) }
    let(:date) { Date.current }

    before do
      @pharmacist = create(:staff, :pharmacist, base_store: store)
      @clerk = create(:staff, :clerk, base_store: store)
      create(:shift, staff: @pharmacist, store: store, date: date)
      create(:shift, staff: @clerk, store: store, date: date)
    end

    it '.on_date' do
      expect(Shift.on_date(date).count).to eq(2)
      expect(Shift.on_date(date + 1.day).count).to eq(0)
    end

    it '.for_store' do
      other_store = create(:store)
      other_staff = create(:staff, base_store: other_store)
      create(:shift, staff: other_staff, store: other_store, date: date)

      expect(Shift.for_store(store).count).to eq(2)
    end

    it '.pharmacists' do
      expect(Shift.pharmacists.count).to eq(1)
    end

    it '.clerks' do
      expect(Shift.clerks.count).to eq(1)
    end
  end

  describe '#working_hours' do
    it '勤務時間を計算する' do
      shift = build(:shift,
        start_time: Time.zone.parse('09:00'),
        end_time: Time.zone.parse('18:00'),
        break_minutes: 60
      )
      expect(shift.working_hours).to eq(8.0) # 9時間 - 1時間休憩
    end

    it '時間がnilの場合は0を返す' do
      shift = build(:shift, start_time: nil, end_time: nil)
      expect(shift.working_hours).to eq(0)
    end
  end
end
