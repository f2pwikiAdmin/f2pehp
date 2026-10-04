require 'rails_helper'

RSpec.describe 'Request throttling', type: :request do
  let!(:clan) { Clan.create!(name: 'Throttle Test Clan', password: 'correct-password') }

  before do
    @rack_attack_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = true
    Rack::Attack.cache.store.clear
  end

  after do
    Rack::Attack.cache.store.clear
    Rack::Attack.enabled = @rack_attack_enabled
  end

  it 'is disabled by default in the test environment' do
    expect(@rack_attack_enabled).to be(false)
  end

  describe 'clan admin posts' do
    it 'throttles after ten requests per IP and leaves other IPs unaffected' do
      10.times do
        post "/clans/#{clan.name.tr(' ', '_')}/add_player_to_clan",
             params: { player_name: 'Missing Player', pass: 'wrong-password' },
             headers: { 'REMOTE_ADDR' => '192.0.2.1' }

        expect(response).to redirect_to(clan_admin_path(id: clan.name.tr(' ', '_')))
        expect(flash[:notice]).to eq('Incorrect password. Please try again.')
      end

      post "/clans/#{clan.name.tr(' ', '_')}/add_player_to_clan",
           params: { player_name: 'Missing Player', pass: 'wrong-password' },
           headers: { 'REMOTE_ADDR' => '192.0.2.1' }

      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to eq('Too many requests. Please try again in a minute.')
      expect(response.headers['Retry-After']).to be_present

      post "/clans/#{clan.name.tr(' ', '_')}/add_player_to_clan",
           params: { player_name: 'Missing Player', pass: 'wrong-password' },
           headers: { 'REMOTE_ADDR' => '192.0.2.2' }

      expect(response).to redirect_to(clan_admin_path(id: clan.name.tr(' ', '_')))
    end
  end

  describe 'admin requests' do
    it 'throttles after five requests per IP' do
      original_user = ENV.delete('HTTP_AUTH_USER')
      original_pass = ENV.delete('HTTP_AUTH_PASS')

      5.times do
        get '/admin', headers: { 'REMOTE_ADDR' => '192.0.2.3' }
        expect(response).to have_http_status(:service_unavailable)
      end

      get '/admin', headers: { 'REMOTE_ADDR' => '192.0.2.3' }

      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to eq('Too many requests. Please try again in a minute.')
      expect(response.headers['Retry-After']).to be_present
    ensure
      ENV['HTTP_AUTH_USER'] = original_user
      ENV['HTTP_AUTH_PASS'] = original_pass
    end
  end
end
