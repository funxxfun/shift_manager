require 'rails_helper'

RSpec.describe Staff, type: :model do
  describe 'validations' do
    subject { build(:staff) }

    it { is_expected.to be_valid }

    it 'codeが必須' do
      subject.code = nil
      expect(subject).not_to be_valid
    end

    it 'codeが一意' do
      create(:staff, code: 'EMP0001')
      subject.code = 'EMP0001'
      expect(subject).not_to be_valid
    end

    it 'nameが必須' do
      subject.name = nil
      expect(subject).not_to be_valid
    end

    it 'roleが必須' do
      subject.role = nil
      expect(subject).not_to be_valid
    end
  end

  describe 'enums' do
    it 'pharmacistを設定できる' do
      staff = build(:staff, role: :pharmacist)
      expect(staff.pharmacist?).to be true
    end

    it 'clerkを設定できる' do
      staff = build(:staff, role: :clerk)
      expect(staff.clerk?).to be true
    end
  end

  describe '#role_label' do
    it '薬剤師のラベルを返す' do
      staff = build(:staff, :pharmacist)
      expect(staff.role_label).to eq('薬剤師')
    end

    it '事務のラベルを返す' do
      staff = build(:staff, :clerk)
      expect(staff.role_label).to eq('事務')
    end
  end

  describe '#working_on?' do
    let(:staff) { create(:staff) }
    let(:date) { Date.current }

    it 'シフトがある場合はtrue' do
      create(:shift, staff: staff, date: date)
      expect(staff.working_on?(date)).to be true
    end

    it 'シフトがない場合はfalse' do
      expect(staff.working_on?(date)).to be false
    end
  end
end
