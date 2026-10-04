require 'rails_helper'

RSpec.describe Player, type: :model do
  describe 'supporters' do
    it 'preserves Tohno1612 with a numeric placeholder amount and its flair' do
      expect(Player::SUPPORTERS.find { |supporter| supporter[:name] == 'Tohno1612' })
        .to eq(name: 'Tohno1612', amount: 0, flair_after: 'flairs/addy_helm.png')
      expect(Player.supporters).to include('Tohno1612')
      expect(Player.contributors).to eq(Player::CONTRIBUTORS.map { |contributor| contributor[:name] })
    end
  end

  describe '#f2p_rank' do
    it 'appends filter binds after all rank criteria binds, keeping name arrays intact' do
      player = Player.create!(
        player_name: 'Rank Target', player_acc_type: 'Reg', overall_ehp: 300, overall_xp: 1000
      )
      supporter = Player.create!(
        player_name: "O'Brien", player_acc_type: 'Reg', overall_ehp: 300, overall_xp: 1100
      )
      Player.create!(
        player_name: 'Other Player', player_acc_type: 'Reg', overall_ehp: 400, overall_xp: 1200
      )
      names = [supporter.player_name, 'Tohno1612']

      expect(Player).to receive(:where).with(
        a_string_matching(/AND \(player_name IN \(\?\) AND player_acc_type = \?\)\z/),
        300, 300, 1000, names, 'Reg'
      ).and_call_original

      expect(player.f2p_rank(
        [['overall_ehp', :DESC], ['overall_xp', :DESC]],
        'player_name IN (?) AND player_acc_type = ?', names, 'Reg'
      )).to eq(2)
    end
  end

  [:f2p_gains_rank, :f2p_record_rank].each do |rank_method|
    describe "##{rank_method}" do
      def create_rank_player(name, attributes = {})
        Player.create!({
          player_name: name, player_acc_type: 'Reg', potential_p2p: 0,
          overall_ehp: 300, overall_xp: 1000,
          overall_ehp_day_start: 250, overall_xp_day_start: 500,
          overall_ehp_day_max: 50, overall_xp_day_max: 500
        }.merge(attributes))
      end

      ['Tohno1612', "O'Brien", "x') OR 1=1 --"].each do |supporter_name|
        it "matches #{supporter_name.inspect} literally and preserves rank tie-breaks and eligibility" do
          allow(Player).to receive(:supporters).and_return([supporter_name, 'Another Supporter'])
          supporter = create_rank_player(supporter_name,
            overall_ehp: 200, overall_ehp_day_start: 100, overall_ehp_day_max: 100)
          veteran = create_rank_player('Rank Veteran',
            overall_ehp: 310, overall_ehp_day_max: 60)
          xp_tie = create_rank_player('XP Tie',
            overall_xp: 1100, overall_xp_day_max: 600)
          id_tie = create_rank_player('ID Tie')
          target = create_rank_player('Rank Target')
          lower = create_rank_player('Lower Rank',
            overall_ehp_day_start: 260, overall_ehp_day_max: 40)
          create_rank_player('Not a Supporter',
            overall_ehp: 200, overall_ehp_day_start: 100, overall_ehp_day_max: 100)
          create_rank_player('No Tracking',
            overall_ehp: 500, overall_ehp_day_start: 0, overall_ehp_day_max: 0)
          create_rank_player('P2P Player',
            overall_ehp: 500, overall_ehp_day_max: 100, potential_p2p: 1)

          expect([supporter, veteran, xp_tie, id_tie, target, lower].map do |player|
            player.public_send(rank_method, 'overall', 'day')
          end).to eq([1, 2, 3, 4, 5, 6])
          expect(Player.count).to eq(9)
        end
      end

      it 'still ranks high-EHP players when the supporter list is empty' do
        allow(Player).to receive(:supporters).and_return([])
        veteran = create_rank_player('Rank Veteran',
          overall_ehp: 310, overall_ehp_day_max: 60)
        target = create_rank_player('Rank Target')
        create_rank_player('Not a Supporter',
          overall_ehp: 200, overall_ehp_day_start: 100, overall_ehp_day_max: 100)

        expect(veteran.public_send(rank_method, 'overall', 'day')).to eq(1)
        expect(target.public_send(rank_method, 'overall', 'day')).to eq(2)
      end
    end
  end

  describe '.find_player' do
    let!(:player) { Player.create!(player_name: 'Test Player', player_acc_type: 'Reg') }

    it 'finds a player by name case-insensitively' do
      expect(Player.find_player('tEsT pLaYeR')).to eq(player)
    end

    ['Test_Player', 'Test-Player', "Test\u00a0Player"].each do |name|
      it "normalizes #{name} for lookup" do
        expect(Player.find_player(name)).to eq(player)
      end
    end

    it 'preserves the single-character wildcard for name separators' do
      player.update!(player_name: 'TestXPlayer')

      expect(Player.find_player('Test Player')).to eq(player)
    end

    it 'does not match a substring of a longer player name' do
      expect(Player.find_player('Test')).to be(false)
    end

    ["' OR '1'='1", "'); DROP TABLE players; --"].each do |payload|
      it "rejects #{payload.inspect} without a SQL error or damaging the table" do
        expect { expect(Player.find_player(payload)).to be(false) }.not_to raise_error

        expect(Player.count).to eq(1)
        expect(player.reload.player_name).to eq('Test Player')
      end
    end

    it 'binds the search term even if name normalization allows SQL metacharacters' do
      payload = "' OR '1'='1"
      allow(Player).to receive(:sanitize_name).with(payload).and_return(payload)

      expect { expect(Player.find_player(payload)).to be(false) }.not_to raise_error
      expect(player.reload.player_name).to eq('Test Player')
    end

    it 'falls back to looking up a numeric ID' do
      expect(Player.find_player(player.id.to_s)).to eq(player)
    end

    it 'returns false for a missing numeric ID' do
      expect(Player.find_player((Player.maximum(:id) + 1).to_s)).to be(false)
    end
  end
end
