# spec/support/authentication_helper.rb
module AuthenticationHelper
  def login_as(staff)
    post login_path, params: { code: staff.code, password: 'password123' }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request
end
