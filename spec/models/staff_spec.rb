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

  describe '認証（has_secure_password）' do
    let(:staff) { create(:staff, password: 'password123') }

    it 'パスワードが必須' do
      new_staff = build(:staff, password: nil)
      expect(new_staff).not_to be_valid
      expect(new_staff.errors[:password]).to include("can't be blank")
    end

    it '正しいパスワードで認証成功' do
      expect(staff.authenticate('password123')).to eq(staff)
    end

    it '間違ったパスワードで認証失敗' do
      expect(staff.authenticate('wrongpassword')).to be false
    end

    it 'パスワードがハッシュ化されて保存される' do
      expect(staff.password_digest).to be_present
      expect(staff.password_digest).not_to eq('password123')
    end
  end
end
