# app/services/csv_import_service.rb
require 'csv'

class CsvImportService
  attr_reader :errors, :imported_count

  def initialize
    @errors = []
    @imported_count = 0
  end

  # 勤次郎CSVをインポート
  def import_kinjiro(file)
    CSV.foreach(file.path, headers: true, encoding: 'UTF-8') do |row|
      import_row(row)
    rescue => e
      @errors << "行 #{$.}: #{e.message}"
    end

    { success: @errors.empty?, imported: @imported_count, errors: @errors }
  end

  private

  def import_row(row)
    # 店舗を取得または作成
    store = find_or_create_store(row)
    
    # スタッフを取得または作成
    staff = find_or_create_staff(row, store)
    
    # シフトを作成
    create_shift(row, store, staff)
    
    @imported_count += 1
  end

  def find_or_create_store(row)
    Store.find_or_create_by!(code: row['店舗コード']) do |store|
      store.name = row['店舗名']
    end
  end

  def find_or_create_staff(row, store)
    role = row['職種'] == '薬剤師' ? :pharmacist : :clerk

    Staff.find_or_create_by!(code: row['社員コード']) do |staff|
      staff.name = row['社員名']
      staff.role = role
      staff.base_store = store
    end
  end

  def create_shift(row, store, staff)
    date = Date.parse(row['勤務日'])
    
    Shift.find_or_create_by!(date: date, staff: staff) do |shift|
      shift.store = store
      shift.start_time = row['出勤時間']
      shift.end_time = row['退勤時間']
      shift.break_minutes = row['休憩時間'].to_i
    end
  end
end
