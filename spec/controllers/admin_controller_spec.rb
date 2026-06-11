require "rails_helper"

RSpec.describe AdminController, type: :controller do
  around do |example|
    original_user = ENV["HTTP_AUTH_USER"]
    original_pass = ENV["HTTP_AUTH_PASS"]
    example.run
  ensure
    original_user.nil? ? ENV.delete("HTTP_AUTH_USER") : ENV["HTTP_AUTH_USER"] = original_user
    original_pass.nil? ? ENV.delete("HTTP_AUTH_PASS") : ENV["HTTP_AUTH_PASS"] = original_pass
  end

  describe "GET #index" do
    it "allows access with matching basic auth when credentials are configured" do
      ENV["HTTP_AUTH_USER"] = "secure-user"
      ENV["HTTP_AUTH_PASS"] = "secure-pass"
      request.env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials("secure-user", "secure-pass")

      get :index

      expect(response).to have_http_status(:ok)
    end

    it "fails closed when credentials are not configured" do
      ENV.delete("HTTP_AUTH_USER")
      ENV.delete("HTTP_AUTH_PASS")
      request.env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials("admin", "admin")

      get :index

      expect(response).to have_http_status(:forbidden)
    end
  end
end
