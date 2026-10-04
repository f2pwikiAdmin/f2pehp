require 'rails_helper'

RSpec.describe 'Player ordering', type: :request do
  let!(:clan) { Clan.create!(name: 'Ordering Clan', symbol_link: 'f2pwiki.png') }
  let!(:first_player) do
    Player.create!(
      player_name: 'Order Alpha', player_acc_type: 'Reg',
      overall_lvl: 500, overall_ehp: 400, overall_xp: 1000,
      overall_ehp_day_start: 1, overall_ehp_week_start: 100, overall_xp_week_start: 100,
      attack_lvl: 50, attack_ehp: 10, attack_xp: 100,
      attack_ehp_month_start: 1, attack_xp_month_start: 10,
      attack_ehp_month_max: 5, attack_xp_month_max: 50,
      magic_lvl: 50, magic_ehp: 0, magic_xp: 100, obor_kc: 10
    )
  end
  let!(:second_player) do
    Player.create!(
      player_name: 'Order Beta', player_acc_type: 'Reg',
      overall_lvl: 500, overall_ehp: 300, overall_xp: 900,
      overall_ehp_day_start: 1, overall_ehp_week_start: 100, overall_xp_week_start: 100,
      attack_lvl: 60, attack_ehp: 20, attack_xp: 200,
      attack_ehp_month_start: 1, attack_xp_month_start: 10,
      attack_ehp_month_max: 10, attack_xp_month_max: 100,
      magic_lvl: 60, magic_ehp: 0, magic_xp: 200, obor_kc: 20
    )
  end

  before do
    clan.add_player(first_player)
    clan.add_player(second_player)
  end

  def request_ordering(path, params)
    queries = []
    subscriber = lambda do |*args|
      sql = args.last[:sql]
      queries << sql if sql.match?(/\ASELECT .*FROM "players"/) && sql.include?('ORDER BY')
    end
    ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') do
      get path, params: params
    end
    expect(response).to have_http_status(:ok)
    expect(queries).not_to be_empty
    queries.last.split('ORDER BY ').last.split(' LIMIT').first
  end

  {
    ranks: '/ranks',
    tracking: '/tracking',
    clan_stats: '/clans/Ordering_Clan',
    clan_gains: '/clans/Ordering_Clan?display=gains',
    clan_records: '/clans/Ordering_Clan?display=records'
  }.each do |action, path|
    describe action do
      [
        { skill: 'overall_ehp); DROP TABLE players;--' },
        { time: 'week_start); DROP TABLE players;--' },
        { sort_by: 'ehp); DROP TABLE players;--' },
        { skill: 'unknown_kc' },
        { skill: ['attack'] },
        { time: ['month'] },
        { sort_by: ['xp'] }
      ].each do |invalid_params|
        it "falls back to safe defaults for #{invalid_params.inspect}" do
          ordering = request_ordering(path, { skill: 'overall', time: 'week', sort_by: 'ehp' }.merge(invalid_params))

          case action
          when :ranks, :clan_stats
            expect(ordering).to eq('overall_ehp DESC, overall_lvl DESC, overall_xp DESC, overall_rank ASC, players.id ASC')
          when :tracking
            expect(ordering).to eq('overall_ehp - overall_ehp_week_start DESC, overall_xp - overall_xp_week_start DESC, overall_ehp DESC, overall_xp DESC, players.id ASC')
          when :clan_gains
            expect(ordering).to eq('overall_ehp - COALESCE(overall_ehp_week_start, 100000) DESC, overall_xp - COALESCE(overall_xp_week_start, 1000000000) DESC, overall_ehp DESC, overall_xp DESC, players.id ASC')
          when :clan_records
            expect(ordering).to eq('COALESCE(overall_ehp_week_max, -100000) DESC, COALESCE(overall_xp_week_max, -1000000000) DESC, overall_ehp DESC, overall_xp DESC, players.id ASC')
          end
          expect(ordering).not_to match(/DROP|unknown_kc/)
          expect(ordering).not_to include('month')
          expect(Player.count).to eq(2)
        end
      end

      it 'preserves the XP ordering for a valid skill and time' do
        ordering = request_ordering(path, skill: 'attack', time: 'month', sort_by: 'xp')

        case action
        when :ranks, :clan_stats
          expect(ordering).to eq('attack_xp DESC, attack_rank ASC')
        when :tracking
          expect(ordering).to eq('attack_xp - attack_xp_month_start DESC, attack_ehp - attack_ehp_month_start DESC, attack_xp DESC')
        when :clan_gains
          expect(ordering).to eq('attack_xp - COALESCE(attack_xp_month_start, 1000000000) DESC, attack_ehp - COALESCE(attack_ehp_month_start, 100000) DESC, attack_xp DESC')
        when :clan_records
          expect(ordering).to eq('COALESCE(attack_xp_month_max, -1000000000) DESC, COALESCE(attack_ehp_month_max, -100000) DESC, attack_xp DESC')
        end
        expect(response.body.index('Order Beta')).to be < response.body.index('Order Alpha')
      end

      it 'falls back when a derived ordering column is missing' do
        allow(Player).to receive(:column_names).and_return(Player.column_names - ['attack_xp'])

        expect(request_ordering(path, skill: 'attack', time: 'month', sort_by: 'xp'))
          .to eq('overall_ehp DESC, players.id ASC')
      end
    end
  end

  it 'keeps the implicit XP default for magic in ranks and clan stats' do
    ['/ranks', '/clans/Ordering_Clan'].each do |path|
      expect(request_ordering(path, skill: 'magic')).to eq('magic_xp DESC, magic_rank ASC')
    end
  end

  it 'preserves alphabetical clan ordering' do
    expect(request_ordering('/clans/Ordering_Clan', skill: 'overall', time: 'week', sort_by: 'player_name'))
      .to eq('player_name ASC')
  end

  it 'preserves boss kill-count ordering' do
    expect(request_ordering('/clans/Ordering_Clan', skill: 'obor_kc', sort_by: 'ehp'))
      .to eq('obor_kc DESC, obor_kc_rank ASC')
  end

  it 'validates defaults after clearing filters' do
    expect(request_ordering('/tracking', clear_filters: 'true'))
      .to include('overall_ehp - overall_ehp_week_start DESC')
  end

  it 'leaves records disabled even with malicious ordering params' do
    get '/records', params: { skill: 'overall); DROP TABLE players;--', time: 'invalid', sort_by: 'invalid' }

    expect(response).to redirect_to(ranks_path)
    expect(flash[:notice]).to include('Records are temporarily unavailable')
  end
end
