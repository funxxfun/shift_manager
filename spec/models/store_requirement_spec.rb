require 'rails_helper'

RSpec.describe StoreRequirement, type: :model do
  describe 'validations' do
    subject { build(:store_requirement) }

    it { is_expected.to be_valid }

    it 'day_typeが必須' do
      subject.day_type = nil
      expect(subject).not_to be_valid
    end

    it 'pharmacist_countが0以上' do
      subject.pharmacist_count = -1
      expect(subject).not_to be_valid
    end

    it 'clerk_countが0以上' do
      subject.clerk_count = -1
      expect(subject).not_to be_valid
    end

    it 'store_idとday_typeの組み合わせが一意' do
      store = create(:store)
      create(:store_requirement, store: store, day_type: :weekday)
      duplicate = build(:store_requirement, store: store, day_type: :weekday)
      expect(duplicate).not_to be_valid
    end
  end

  describe 'enums' do
    it 'weekdayを設定できる' do
      req = build(:store_requirement, day_type: :weekday)
      expect(req.weekday?).to be true
    end

    it 'saturdayを設定できる' do
      req = build(:store_requirement, day_type: :saturday)
      expect(req.saturday?).to be true
    end

    it 'holidayを設定できる' do
      req = build(:store_requirement, day_type: :holiday)
      expect(req.holiday?).to be true
    end
  end

  describe '#day_type_label' do
    it '平日のラベルを返す' do
      req = build(:store_requirement, :weekday)
      expect(req.day_type_label).to eq('平日')
    end

    it '土曜のラベルを返す' do
      req = build(:store_requirement, :saturday)
      expect(req.day_type_label).to eq('土曜')
    end

    it '日祝のラベルを返す' do
      req = build(:store_requirement, :holiday)
      expect(req.day_type_label).to eq('日祝')
    end
  end
end
