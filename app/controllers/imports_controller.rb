# app/controllers/imports_controller.rb
class ImportsController < ApplicationController
  def new
  end

  def create
    unless params[:file].present?
      redirect_to new_import_path, alert: 'ファイルを選択してください'
      return
    end

    service = CsvImportService.new
    result = service.import_kinjiro(params[:file])

    if result[:success]
      redirect_to shifts_path, notice: "#{result[:imported]}件のシフトをインポートしました"
    else
      redirect_to new_import_path, alert: "エラーが発生しました: #{result[:errors].join(', ')}"
    end
  end
end
