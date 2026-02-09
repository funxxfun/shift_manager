# app/services/shortage_calculator_service.rb
class ShortageCalculatorService
  # 指定日の全店舗の過不足を算出（AM/PM別）
  def self.calculate_all(date)
    stores = Store.includes(:store_requirements, shifts: :staff).all

    result = {
      date: date,
      stores: [],
      summary: {
        am: build_empty_summary,
        pm: build_empty_summary,
        combined: build_empty_summary
      }
    }

    stores.each do |store|
      shortage_am = store.shortage_on(date, :am)
      shortage_pm = store.shortage_on(date, :pm)

      status_am = determine_status(shortage_am)
      status_pm = determine_status(shortage_pm)
      combined_status = determine_combined_status(status_am, status_pm)

      store_data = {
        id: store.id,
        code: store.code,
        name: store.name,
        am: build_period_data(shortage_am, status_am, store, date, :am),
        pm: build_period_data(shortage_pm, status_pm, store, date, :pm),
        combined_status: combined_status
      }

      result[:stores] << store_data
      update_summary(result[:summary][:am], status_am, shortage_am)
      update_summary(result[:summary][:pm], status_pm, shortage_pm)
      update_combined_summary(result[:summary][:combined], combined_status, shortage_am, shortage_pm)
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

  def self.build_empty_summary
    {
      shortage_stores: 0,
      surplus_stores: 0,
      ok_stores: 0,
      total_pharmacist_shortage: 0,
      total_clerk_shortage: 0
    }
  end

  def self.build_period_data(shortage, status, store, date, period)
    {
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
      staff_list: build_staff_list(store, date, period)
    }
  end

  def self.build_staff_list(store, date, period = nil)
    shifts = store.shifts_on(date, period).includes(:staff)

    {
      pharmacists: shifts.select { |s| s.staff.pharmacist? }.map { |s| s.staff.name },
      clerks: shifts.select { |s| s.staff.clerk? }.map { |s| s.staff.name }
    }
  end

  def self.determine_status(shortage)
    return :closed if shortage[:closed]

    if shortage[:pharmacist] < 0 || shortage[:clerk] < 0
      :shortage
    elsif shortage[:pharmacist] > 0 || shortage[:clerk] > 0
      :surplus
    else
      :ok
    end
  end

  def self.determine_combined_status(status_am, status_pm)
    # 両方closedなら閉店
    return :closed if status_am == :closed && status_pm == :closed

    # closedでない方のステータスを優先
    statuses = [status_am, status_pm].reject { |s| s == :closed }
    return :closed if statuses.empty?

    if statuses.include?(:shortage)
      :shortage
    elsif statuses.include?(:surplus)
      :surplus
    else
      :ok
    end
  end

  def self.update_summary(summary, status, shortage)
    case status
    when :shortage
      summary[:shortage_stores] += 1
      summary[:total_pharmacist_shortage] += [shortage[:pharmacist], 0].min.abs
      summary[:total_clerk_shortage] += [shortage[:clerk], 0].min.abs
    when :surplus
      summary[:surplus_stores] += 1
    when :closed
      # 休業店舗はカウントしない
    else
      summary[:ok_stores] += 1
    end
  end

  def self.update_combined_summary(summary, status, shortage_am, shortage_pm)
    case status
    when :shortage
      summary[:shortage_stores] += 1
      summary[:total_pharmacist_shortage] += [shortage_am[:pharmacist], 0].min.abs unless shortage_am[:closed]
      summary[:total_pharmacist_shortage] += [shortage_pm[:pharmacist], 0].min.abs unless shortage_pm[:closed]
      summary[:total_clerk_shortage] += [shortage_am[:clerk], 0].min.abs unless shortage_am[:closed]
      summary[:total_clerk_shortage] += [shortage_pm[:clerk], 0].min.abs unless shortage_pm[:closed]
    when :surplus
      summary[:surplus_stores] += 1
    when :closed
      # 完全休業店舗はカウントしない
    else
      summary[:ok_stores] += 1
    end
  end
end
