# app/services/shortage_calculator_service.rb
class ShortageCalculatorService
  # 指定日の全店舗の過不足を算出
  def self.calculate_all(date)
    stores = Store.includes(:store_requirements, shifts: :staff).all
    
    result = {
      date: date,
      stores: [],
      summary: {
        shortage_stores: 0,
        surplus_stores: 0,
        ok_stores: 0,
        total_pharmacist_shortage: 0,
        total_clerk_shortage: 0
      }
    }

    stores.each do |store|
      shortage = store.shortage_on(date)
      status = determine_status(shortage)
      
      store_data = {
        id: store.id,
        code: store.code,
        name: store.name,
        status: status,
        pharmacist: {
          current: shortage[:pharmacist_current],
          required: shortage[:pharmacist_required],
          diff: shortage[:pharmacist]
        },
        clerk: {
          current: shortage[:clerk_current],
          required: shortage[:clerk_required],
          diff: shortage[:clerk]
        },
        staff_list: build_staff_list(store, date)
      }
      
      result[:stores] << store_data
      update_summary(result[:summary], status, shortage)
    end

    result
  end

  # 期間の過不足を算出
  def self.calculate_range(start_date, end_date)
    (start_date..end_date).map do |date|
      calculate_all(date)
    end
  end

  private

  def self.determine_status(shortage)
    if shortage[:pharmacist] < 0 || shortage[:clerk] < 0
      :shortage
    elsif shortage[:pharmacist] > 0 || shortage[:clerk] > 0
      :surplus
    else
      :ok
    end
  end

  def self.build_staff_list(store, date)
    shifts = store.shifts_on(date).includes(:staff)
    
    {
      pharmacists: shifts.select { |s| s.staff.pharmacist? }.map { |s| s.staff.name },
      clerks: shifts.select { |s| s.staff.clerk? }.map { |s| s.staff.name }
    }
  end

  def self.update_summary(summary, status, shortage)
    case status
    when :shortage
      summary[:shortage_stores] += 1
      summary[:total_pharmacist_shortage] += [shortage[:pharmacist], 0].min.abs
      summary[:total_clerk_shortage] += [shortage[:clerk], 0].min.abs
    when :surplus
      summary[:surplus_stores] += 1
    else
      summary[:ok_stores] += 1
    end
  end
end
