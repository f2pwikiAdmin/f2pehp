require 'rails_helper'

RSpec.describe AdminController, type: :controller do
  describe "GET #index" do
    around do |example|
      original_user = ENV['HTTP_AUTH_USER']
      original_pass = ENV['HTTP_AUTH_PASS']
      ENV.delete('HTTP_AUTH_USER')
      ENV.delete('HTTP_AUTH_PASS')
      example.run
      ENV['HTTP_AUTH_USER'] = original_user
      ENV['HTTP_AUTH_PASS'] = original_pass
    end

    it "returns 503 when admin credentials are not configured" do
      get :index

      expect(response).to have_http_status(:service_unavailable)
      expect(response.body).to include("Admin access is not configured")
    end
  end
end
