require 'rails_helper'

RSpec.describe ShortageCalculatorService, type: :service do
  describe '.calculate_all' do
    let(:date) { Date.new(2026, 1, 13) } # 火曜日（平日）

    context '店舗が存在しない場合' do
      it '空の結果を返す' do
        result = described_class.calculate_all(date)
        expect(result[:stores]).to be_empty
        expect(result[:summary][:shortage_stores]).to eq(0)
      end
    end

    context '店舗が存在する場合' do
      let!(:store1) { create(:store, name: '店舗A') }
      let!(:store2) { create(:store, name: '店舗B') }

      before do
        # 店舗A: 薬剤師2名、事務1名必要
        create(:store_requirement, store: store1, day_type: :weekday, pharmacist_count: 2, clerk_count: 1)
        # 店舗B: 薬剤師1名、事務1名必要
        create(:store_requirement, store: store2, day_type: :weekday, pharmacist_count: 1, clerk_count: 1)
      end

      it '不足店舗を正しくカウント' do
        # 店舗Aに薬剤師1名（不足）
        pharmacist_a = create(:staff, :pharmacist, base_store: store1)
        create(:shift, store: store1, staff: pharmacist_a, date: date)

        result = described_class.calculate_all(date)
        expect(result[:summary][:shortage_stores]).to eq(2) # 両店舗とも不足
      end

      it '余剰店舗を正しくカウント' do
        # 店舗Aに薬剤師3名、事務2名（余剰）
        3.times do
          staff = create(:staff, :pharmacist, base_store: store1)
          create(:shift, store: store1, staff: staff, date: date)
        end
        2.times do
          staff = create(:staff, :clerk, base_store: store1)
          create(:shift, store: store1, staff: staff, date: date)
        end

        result = described_class.calculate_all(date)
        store1_data = result[:stores].find { |s| s[:id] == store1.id }
        expect(store1_data[:status]).to eq(:surplus)
      end

      it 'OK店舗を正しくカウント' do
        # 店舗Bに薬剤師1名、事務1名（ちょうど）
        pharmacist = create(:staff, :pharmacist, base_store: store2)
        clerk = create(:staff, :clerk, base_store: store2)
        create(:shift, store: store2, staff: pharmacist, date: date)
        create(:shift, store: store2, staff: clerk, date: date)

        result = described_class.calculate_all(date)
        store2_data = result[:stores].find { |s| s[:id] == store2.id }
        expect(store2_data[:status]).to eq(:ok)
      end
    end
  end

  describe '.calculate_range' do
    it '複数日の結果を返す' do
      start_date = Date.new(2026, 1, 13)
      end_date = Date.new(2026, 1, 15)

      result = described_class.calculate_range(start_date, end_date)
      expect(result.length).to eq(3)
      expect(result.map { |r| r[:date] }).to eq([start_date, start_date + 1.day, end_date])
    end
  end
end
