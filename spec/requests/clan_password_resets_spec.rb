require 'rails_helper'

RSpec.describe 'Clan password recovery', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:clan) { Clan.create!(name: 'Recovery Clan', password: 'original-password', pass: Digest::MD5.hexdigest('legacy-password')) }
  let(:admin_headers) { { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('admin-test', 'admin-test-password') } }

  around do |example|
    original_user = ENV['HTTP_AUTH_USER']
    original_pass = ENV['HTTP_AUTH_PASS']
    ENV['HTTP_AUTH_USER'] = 'admin-test'
    ENV['HTTP_AUTH_PASS'] = 'admin-test-password'
    example.run
  ensure
    ENV['HTTP_AUTH_USER'] = original_user
    ENV['HTTP_AUTH_PASS'] = original_pass
  end

  it 'requires administrator authentication on the very first issuance request' do
    post admin_clan_password_resets_path, params: { clan_id: clan.id }

    expect(response).to have_http_status(:unauthorized)
    expect(clan.reload.password_reset_digest).to be_nil

    post admin_clan_password_resets_path, params: { clan_id: clan.id },
      headers: { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('admin-test', 'wrong') }
    expect(response).to have_http_status(:unauthorized)
    expect(clan.reload.password_reset_digest).to be_nil
  end

  it 'fails closed when administrator credentials are missing' do
    ENV.delete('HTTP_AUTH_PASS')
    post admin_clan_password_resets_path, params: { clan_id: clan.id }, headers: admin_headers
    expect(response).to have_http_status(:service_unavailable)
    expect(clan.reload.password_reset_digest).to be_nil
  end

  it 'requires CSRF protection for issuing and redeeming reset links' do
    allow_any_instance_of(AdminController).to receive(:protect_against_forgery?).and_return(true)
    expect {
      post admin_clan_password_resets_path, params: { clan_id: clan.id }, headers: admin_headers
    }.to raise_error(ActionController::InvalidAuthenticityToken)
    expect(clan.reload.password_reset_digest).to be_nil

    token = clan.issue_password_reset!
    allow_any_instance_of(ClanPasswordResetsController).to receive(:protect_against_forgery?).and_return(true)
    expect {
      patch clan_password_reset_path(id: clan.id), params: {
        reset_token: token, password: 'replacement-password', password_confirmation: 'replacement-password'
      }
    }.to raise_error(ActionController::InvalidAuthenticityToken)
    expect(clan.reload.valid_password_reset?(token)).to be(true)
    expect(clan.authenticate_pass('original-password')).to eq(clan)
  end

  it 'issues a private link, resets the password, and rejects reuse without changing membership' do
    player = Player.create!(player_name: 'Recovery Player', player_acc_type: 'Reg')
    clan.add_player(player)
    post admin_clan_password_resets_path, params: { clan_id: clan.id }, headers: admin_headers

    expect(response).to have_http_status(:ok)
    expect(response.headers['Cache-Control']).to include('no-store')
    link = Nokogiri::HTML(response.body).at_css('a[href*="reset_token="]')['href']
    token = Rack::Utils.parse_query(URI.parse(link).query)['reset_token']
    expect(clan.reload.password_reset_digest).not_to eq(token)
    expect(clan.authenticate_pass('original-password')).to eq(clan)

    get link
    expect(response).to have_http_status(:ok)
    expect(response.headers['Cache-Control']).to include('no-store')
    expect(response.headers['Referrer-Policy']).to eq('no-referrer')
    expect(response.body).not_to include('og:url', 'twitter:url')
    expect(Nokogiri::HTML(response.body).at_css('input[name="password"]')['value']).to be_nil

    patch clan_password_reset_path(id: clan.id), params: {
      reset_token: token, password: 'replacement-password', password_confirmation: 'replacement-password'
    }

    expect(response).to redirect_to(clan_admin_path(id: clan.id))
    expect(clan.reload.authenticate_pass('replacement-password')).to eq(clan)
    expect(clan.authenticate_pass('original-password')).to be(false)
    expect(clan.authenticate_pass('legacy-password')).to be(false)
    expect(clan.pass).to be_nil
    expect(clan.password_reset_digest).to be_nil
    expect(clan.password_reset_sent_at).to be_nil
    expect(clan.players).to contain_exactly(player)

    get link
    expect(response).to have_http_status(:unprocessable_entity)
    patch clan_password_reset_path(id: clan.id), params: {
      reset_token: token, password: 'another-password', password_confirmation: 'another-password'
    }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(clan.reload.authenticate_pass('replacement-password')).to eq(clan)
  end

  it 'rejects expired links, wrong-clan links, and replacement links' do
    token = clan.issue_password_reset!
    other = Clan.create!(name: 'Other Clan', password: 'other-password')
    get clan_password_reset_path(id: other.id, reset_token: token)
    expect(response).to have_http_status(:unprocessable_entity)

    clan.issue_password_reset!
    get clan_password_reset_path(id: clan.id, reset_token: token)
    expect(response).to have_http_status(:unprocessable_entity)

    fresh_token = clan.issue_password_reset!
    travel 30.minutes + 1.second do
      patch clan_password_reset_path(id: clan.id), params: {
        reset_token: fresh_token, password: 'replacement-password', password_confirmation: 'replacement-password'
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(clan.reload.authenticate_pass('original-password')).to eq(clan)
    end
  end

  it 'keeps the link usable after password validation failures without echoing passwords' do
    token = clan.issue_password_reset!
    [
      ['short', 'short'],
      ['replacement-password', 'mismatched-password'],
      ['a' * 73, 'a' * 73],
      ["\u00e9" * 37, "\u00e9" * 37],
      [nil, nil],
      [{ unexpected: 'shape' }, 'replacement-password']
    ].each do |password, confirmation|
      patch clan_password_reset_path(id: clan.id), params: {
        reset_token: token, password: password, password_confirmation: confirmation
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(clan.reload.valid_password_reset?(token)).to be(true)
      expect(clan.authenticate_pass('original-password')).to eq(clan)
      expect(Nokogiri::HTML(response.body).css('input[type="password"]').map { |input| input['value'] }.compact).to be_empty
    end
  end

  it 'supports resetting a legacy-only clan at the bcrypt byte limit' do
    clan.update!(password_digest: nil)
    token = clan.issue_password_reset!
    password = 'a' * 72

    patch clan_password_reset_path(id: clan.id), params: {
      reset_token: token, password: password, password_confirmation: password
    }

    expect(response).to redirect_to(clan_admin_path(id: clan.id))
    expect(clan.reload.authenticate_pass(password)).to eq(clan)
    expect(clan.pass).to be_nil
  end

  it 'rejects missing and malformed reset tokens and unknown clans' do
    [nil, '', 'wrong', { unexpected: 'shape' }].each do |token|
      get clan_password_reset_path(id: clan.id), params: { reset_token: token }
      expect(response).to have_http_status(:unprocessable_entity)
    end
    get clan_password_reset_path(id: Clan.maximum(:id) + 1, reset_token: 'a' * 43)
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'filters reset tokens and passwords from application parameters and URLs' do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    expect(filter.filter('reset_token' => 'private-token', 'pass' => 'legacy-secret',
      'password' => 'new-secret', 'password_confirmation' => 'new-secret').values)
      .to all(eq('[FILTERED]'))

    request = ActionDispatch::TestRequest.create
    request.env['action_dispatch.parameter_filter'] = Rails.application.config.filter_parameters
    request.env['PATH_INFO'] = "/clan_password_resets/#{clan.id}"
    request.env['QUERY_STRING'] = 'reset_token=private-token'
    expect(request.filtered_path).not_to include('private-token')
  end
end
