require 'rails_helper'

RSpec.describe 'Player listing filter lifecycle', type: :request do
  let!(:clan) { Clan.create!(name: 'Filter Clan', symbol_link: 'f2pwiki.png') }
  let!(:other_clan) { Clan.create!(name: 'Other Clan', symbol_link: 'f2pwiki.png') }
  let(:player_attributes) do
    {
      overall_lvl: 500, overall_ehp: 400, overall_xp: 1000,
      overall_ehp_day_start: 1, overall_ehp_week_start: 100,
      overall_ehp_month_start: 100, overall_xp_week_start: 100,
      overall_xp_month_start: 100, overall_ehp_week_max: 50,
      overall_xp_week_max: 100, overall_ehp_month_max: 50,
      overall_xp_month_max: 100, combat_lvl: 20, defence_lvl: 1,
      attack_lvl: 50, attack_xp: 100, attack_ehp: 10,
      attack_ehp_week_start: 1, attack_xp_week_start: 10,
      attack_ehp_month_start: 1, attack_xp_month_start: 10,
      attack_ehp_month_max: 5, attack_xp_month_max: 50
    }
  end
  let!(:regular) { Player.create!(player_attributes.merge(player_name: 'Filter Reg', player_acc_type: 'Reg')) }
  let!(:ironman) { Player.create!(player_attributes.merge(player_name: 'Filter Iron', player_acc_type: 'IM')) }
  let!(:outsider) do
    Player.create!(player_attributes.merge(
      player_name: 'Filter Other', player_acc_type: 'Reg', defence_lvl: 2, overall_ehp: 600
    ))
  end

  before do
    clan.add_player(regular)
    clan.add_player(ironman)
    other_clan.add_player(outsider)
  end

  def listing_get(path, params = {})
    get path, params: params
    expect(response).to have_http_status(:ok)
  end

  def checked_values(prefix)
    Nokogiri::HTML(response.body).css('input[type="checkbox"][checked]')
      .select { |input| input['name'].start_with?("#{prefix}[") }
      .map { |input| input['name'][/\[(.*)\]/, 1] }
  end

  def expect_players(*players)
    names = Nokogiri::HTML(response.body).css('tbody a').map(&:text)
    expect(names & [regular.player_name, ironman.player_name, outsider.player_name])
      .to match_array(players.map(&:player_name))
  end

  ['/ranks', '/tracking'].each do |path|
    describe path do
      it 'retains a restriction through header sorting and page requests' do
        listing_get(path, restrictions: '1 defence')
        expect_players(regular, ironman)

        listing_get(path, sort_by: 'xp')
        expect_players(regular, ironman)
        expect(request.session[:restrictions].keys).to eq(['1 defence'])

        listing_get(path, page: 1)
        expect_players(regular, ironman)
        expect(request.session[:restrictions].keys).to eq(['1 defence'])
      end

      it 'retains an account subset when the next request omits the form' do
        listing_get(path, filters_present: '1', filters_: { 'IM' => '1' })
        expect_players(ironman)

        listing_get(path, sort_by: 'xp')
        expect_players(ironman)
        expect(checked_values('filters_')).to eq(['IM'])
        expect(request.session[:filters_].keys).to eq(['IM'])
      end

      it 'keeps the restriction and page size when following a later page' do
        listing_get(path, restrictions: '1 defence', show_limit: '1')
        expect_players(regular)

        listing_get(path, page: 2)
        expect_players(ironman)
        expect(request.session[:restrictions].keys).to eq(['1 defence'])
        expect(request.session[:show_limit].to_i).to eq(1)
      end

      it 'persists no accounts when a browser submits all checkboxes unchecked' do
        listing_get(path, filters_present: '1', filters_: { 'IM' => '1' })
        listing_get(path, filters_present: '1')
        expect_players
        expect(checked_values('filters_')).to be_empty
        expect(request.session[:filters_]).to eq({})

        listing_get(path, page: 1)
        expect_players
        expect(checked_values('filters_')).to be_empty
        expect(request.session[:filters_]).to eq({})
      end

      it 'renders all account defaults on a cold request and after a round trip' do
        listing_get(path)
        expect(checked_values('filters_')).to match_array(%w[Reg IM UIM HCIM])
        expect_players(regular, ironman, outsider)

        listing_get(path, sort_by: 'xp')
        expect(checked_values('filters_')).to match_array(%w[Reg IM UIM HCIM])
        expect(request.session[:filters_].keys).to match_array(%w[Reg IM UIM HCIM])
      end
    end
  end

  it 'renders all clan defaults on a cold request and after a round trip' do
    listing_get('/ranks')
    expect(checked_values('clans_')).to match_array(['Filter Clan', 'Other Clan', 'None'])

    listing_get('/ranks', sort_by: 'xp')
    expect(checked_values('clans_')).to match_array(['Filter Clan', 'Other Clan', 'None'])
  end

  it 'retains a clan subset when the next request omits the form' do
    listing_get('/ranks', clans_present: '1', clans_: { clan.name => '1' })
    expect_players(regular, ironman)

    listing_get('/ranks', page: 1)
    expect_players(regular, ironman)
    expect(checked_values('clans_')).to eq([clan.name])
    expect(request.session[:clans_].keys).to eq([clan.name])
  end

  it 'persists no clans when a browser submits all clan checkboxes unchecked' do
    listing_get('/ranks', clans_present: '1', clans_: { clan.name => '1' })
    listing_get('/ranks', clans_present: '1')
    expect_players
    expect(checked_values('clans_')).to be_empty
    expect(request.session[:clans_]).to eq({})

    listing_get('/ranks', sort_by: 'xp')
    expect_players
    expect(checked_values('clans_')).to be_empty
    expect(request.session[:clans_]).to eq({})
  end

  it 'shares account, clan and restriction selections globally between listing pages' do
    listing_get('/ranks', filters_present: '1', filters_: { 'Reg' => '1' },
                clans_present: '1', clans_: { clan.name => '1' }, restrictions: '1 defence')
    expect_players(regular)

    listing_get('/tracking')
    expect_players(regular)
    expect(request.session[:clans_].keys).to eq([clan.name])

    listing_get('/ranks')
    expect_players(regular)
    expect(checked_values('filters_')).to eq(['Reg'])
    expect(checked_values('clans_')).to eq([clan.name])
  end

  it 'still ignores stored clan filtering in tracking, including an explicitly empty selection' do
    listing_get('/ranks', clans_present: '1', clans_: { clan.name => '1' })
    listing_get('/tracking')
    expect_players(regular, ironman, outsider)

    listing_get('/ranks', clans_present: '1')
    expect_players
    listing_get('/tracking')
    expect_players(regular, ironman, outsider)
    expect(request.session[:clans_]).to eq({})
  end

  it 'shares the ranks time selection with tracking and clan listings' do
    listing_get('/ranks', time: 'month')
    expect(request.session[:time]).to eq('month')

    listing_get('/tracking')
    expect(response.body).to include('Top Month')
    expect(request.session[:time]).to eq('month')

    listing_get('/clans/Filter_Clan', display: 'gains')
    expect(request.session[:time]).to eq('month')
    expect(response.body).to include('Month')
  end

  ['/ranks', '/tracking', '/clans/Filter_Clan'].each do |path|
    it "resets filters without resetting the shared time or display on #{path}" do
      listing_get('/clans/Filter_Clan', display: 'gains', time: 'month')
      listing_get('/ranks', skill: 'attack', sort_by: 'xp', show_limit: '25',
                  filters_present: '1', filters_: { 'IM' => '1' },
                  clans_present: '1', clans_: { clan.name => '1' },
                  restrictions: '1 defence', filter_inactive: 'true')

      listing_get(path, clear_filters: 'true')
      expect(request.session[:time]).to eq('month')
      expect(request.session[:display]).to eq('gains')
      expect(request.session[:skill]).to eq('overall')
      expect(request.session[:sort_by]).to eq('ehp')
      expect(request.session[:filter_inactive]).to eq('false') unless path == '/tracking'
      unless path.start_with?('/clans')
        expect(request.session[:show_limit].to_i).to eq(100)
        expect(request.session[:filters_].keys).to match_array(%w[Reg IM UIM HCIM])
        expect(request.session[:clans_].keys).to match_array(['Filter Clan', 'Other Clan', 'None'])
        expect(request.session[:restrictions]).to eq({})
      end
    end
  end

  %w[gains records].each do |display|
    it "persists level-sort coercion through clan #{display} back to stats" do
      listing_get('/clans/Filter_Clan', display: 'stats', sort_by: 'lvl')
      expect(request.session[:sort_by]).to eq('lvl')

      listing_get('/clans/Filter_Clan', display: display)
      expect(request.session[:sort_by]).to eq('ehp')

      listing_get('/clans/Filter_Clan', display: 'stats')
      expect(request.session[:sort_by]).to eq('ehp')
      expect(Nokogiri::HTML(response.body).at_css('#player_ehp_header').parent['class']).to include('hilite')
    end
  end

  it 'leaves the global records endpoint disabled without changing shared filters' do
    listing_get('/ranks', filters_present: '1', filters_: { 'IM' => '1' }, time: 'month')

    get '/records', params: { clear_filters: 'true', filters_present: '1', time: 'day' }

    expect(response).to redirect_to(ranks_path)
    expect(flash[:notice]).to include('Records are temporarily unavailable')
    expect(request.session[:filters_].keys).to eq(['IM'])
    expect(request.session[:time]).to eq('month')
  end
end
