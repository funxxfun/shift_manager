require 'rails_helper'

RSpec.describe Store, type: :model do
  describe 'validations' do
    subject { build(:store) }

    it { is_expected.to be_valid }

    it 'codeが必須' do
      subject.code = nil
      expect(subject).not_to be_valid
    end

    it 'codeが一意' do
      create(:store, code: 'STORE001')
      subject.code = 'STORE001'
      expect(subject).not_to be_valid
    end

    it 'nameが必須' do
      subject.name = nil
      expect(subject).not_to be_valid
    end
  end

  describe 'associations' do
    it 'store_requirementsを持つ' do
      store = create(:store)
      create(:store_requirement, store: store, day_type: :weekday)
      expect(store.store_requirements.count).to eq(1)
    end

    it 'shiftsを持つ' do
      store = create(:store)
      staff = create(:staff, base_store: store)
      create(:shift, store: store, staff: staff)
      expect(store.shifts.count).to eq(1)
    end
  end

  describe '.day_type_for' do
    it '平日を判定' do
      tuesday = Date.new(2026, 1, 13) # 火曜日
      expect(Store.day_type_for(tuesday)).to eq(:weekday)
    end

    it '土曜を判定' do
      saturday = Date.new(2026, 1, 17) # 土曜日
      expect(Store.day_type_for(saturday)).to eq(:saturday)
    end

    it '日曜を休日と判定' do
      sunday = Date.new(2026, 1, 18) # 日曜日
      expect(Store.day_type_for(sunday)).to eq(:holiday)
    end
  end

  describe '#shortage_on' do
    let(:store) { create(:store) }
    let(:date) { Date.new(2026, 1, 13) } # 火曜日（平日）

    before do
      create(:store_requirement, store: store, day_type: :weekday, pharmacist_count: 2, clerk_count: 1)
    end

    it '必要人数なしの場合はゼロを返す' do
      store_without_req = create(:store)
      result = store_without_req.shortage_on(date)
      expect(result[:pharmacist]).to eq(0)
      expect(result[:clerk]).to eq(0)
    end

    it '不足を正しく算出' do
      # 薬剤師1名、事務0名のシフト（必要: 薬剤師2, 事務1）
      pharmacist = create(:staff, :pharmacist, base_store: store)
      create(:shift, store: store, staff: pharmacist, date: date)

      result = store.shortage_on(date)
      expect(result[:pharmacist]).to eq(-1)  # 1 - 2 = -1
      expect(result[:clerk]).to eq(-1)       # 0 - 1 = -1
    end

    it '余剰を正しく算出' do
      # 薬剤師3名のシフト（必要: 薬剤師2）
      3.times do
        pharmacist = create(:staff, :pharmacist, base_store: store)
        create(:shift, store: store, staff: pharmacist, date: date)
      end
      # 事務2名のシフト（必要: 事務1）
      2.times do
        clerk = create(:staff, :clerk, base_store: store)
        create(:shift, store: store, staff: clerk, date: date)
      end

      result = store.shortage_on(date)
      expect(result[:pharmacist]).to eq(1)  # 3 - 2 = 1
      expect(result[:clerk]).to eq(1)       # 2 - 1 = 1
    end
  end
end
