require 'rails_helper'

RSpec.describe CsvImportService, type: :service do
  let(:service) { described_class.new }

  describe '#import_kinjiro' do
    let(:csv_content) do
      <<~CSV
        店舗コード,店舗名,社員コード,社員名,職種,勤務日,出勤時間,退勤時間,休憩時間
        STORE001,テスト薬局,EMP001,山田太郎,薬剤師,2026-01-12,09:00,18:00,60
        STORE001,テスト薬局,EMP002,鈴木花子,事務,2026-01-12,09:00,17:00,60
        STORE002,別店舗,EMP003,佐藤次郎,薬剤師,2026-01-12,10:00,19:00,60
      CSV
    end

    let(:temp_file) do
      file = Tempfile.new(['test', '.csv'])
      file.write(csv_content)
      file.rewind
      file
    end

    after do
      temp_file.close
      temp_file.unlink
    end

    it 'CSVを正常にインポート' do
      result = service.import_kinjiro(temp_file)

      expect(result[:success]).to be true
      expect(result[:imported]).to eq(3)
      expect(result[:errors]).to be_empty
    end

    it '店舗を作成する' do
      expect {
        service.import_kinjiro(temp_file)
      }.to change(Store, :count).by(2)

      expect(Store.find_by(code: 'STORE001').name).to eq('テスト薬局')
    end

    it 'スタッフを作成する' do
      expect {
        service.import_kinjiro(temp_file)
      }.to change(Staff, :count).by(3)

      staff = Staff.find_by(code: 'EMP001')
      expect(staff.name).to eq('山田太郎')
      expect(staff.pharmacist?).to be true
    end

    it 'シフトを作成する' do
      expect {
        service.import_kinjiro(temp_file)
      }.to change(Shift, :count).by(3)
    end

    it '重複インポートで既存データを使用' do
      service.import_kinjiro(temp_file)

      temp_file.rewind
      new_service = described_class.new
      result = new_service.import_kinjiro(temp_file)

      expect(result[:success]).to be true
      expect(Store.count).to eq(2)  # 増えない
      expect(Staff.count).to eq(3)  # 増えない
    end

    context '不正なCSV' do
      let(:invalid_csv_content) do
        <<~CSV
          店舗コード,店舗名,社員コード,社員名,職種,勤務日,出勤時間,退勤時間,休憩時間
          ,,,,,invalid-date,,
        CSV
      end

      let(:invalid_temp_file) do
        file = Tempfile.new(['invalid', '.csv'])
        file.write(invalid_csv_content)
        file.rewind
        file
      end

      after do
        invalid_temp_file.close
        invalid_temp_file.unlink
      end

      it 'エラーを記録する' do
        result = service.import_kinjiro(invalid_temp_file)
        expect(result[:errors]).not_to be_empty
      end
    end
  end
end
