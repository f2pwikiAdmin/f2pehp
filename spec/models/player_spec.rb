require 'rails_helper'

RSpec.describe Player, type: :model do
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
