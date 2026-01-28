require 'rails_helper'

RSpec.describe Player, type: :model do
  describe '.rank_sort_sql' do
    it 'generates SQL that treats negative ranks as high values' do
      sql = Player.rank_sort_sql('attack_rank')
      expect(sql).to eq("CASE WHEN attack_rank < 0 THEN #{Player::UNRANKED_SORT_VALUE} ELSE attack_rank END ASC")
    end

    it 'works with different rank column names' do
      sql = Player.rank_sort_sql('lms_rank')
      expect(sql).to eq("CASE WHEN lms_rank < 0 THEN #{Player::UNRANKED_SORT_VALUE} ELSE lms_rank END ASC")
    end

    it 'works with boss KC rank columns' do
      sql = Player.rank_sort_sql('obor_kc_rank')
      expect(sql).to eq("CASE WHEN obor_kc_rank < 0 THEN #{Player::UNRANKED_SORT_VALUE} ELSE obor_kc_rank END ASC")
    end

    it 'raises ArgumentError for invalid column names with SQL injection attempts' do
      expect { Player.rank_sort_sql("attack_rank; DROP TABLE players;") }.to raise_error(ArgumentError, /Invalid rank column name/)
    end

    it 'raises ArgumentError for column names with special characters' do
      expect { Player.rank_sort_sql("attack_rank OR 1=1") }.to raise_error(ArgumentError, /Invalid rank column name/)
    end

    it 'raises ArgumentError for column names with quotes' do
      expect { Player.rank_sort_sql("attack_rank'") }.to raise_error(ArgumentError, /Invalid rank column name/)
    end

    it 'accepts valid column names with underscores and numbers' do
      expect { Player.rank_sort_sql('obor_kc_rank') }.not_to raise_error
      expect { Player.rank_sort_sql('bryo_kc_rank') }.not_to raise_error
      expect { Player.rank_sort_sql('clues_beginner_rank') }.not_to raise_error
    end
  end

  describe 'rank sorting behavior' do
    before(:each) do
      # Clean up any existing test players
      Player.where("player_name LIKE 'test_player_%'").destroy_all
    end

    it 'sorts players with -1 rank after players with valid ranks' do
      # Create test players with different ranks
      player1 = Player.create!(
        player_name: 'test_player_1',
        player_acc_type: 'Reg',
        attack_rank: 1,
        attack_lvl: 99,
        attack_xp: 13034431
      )
      player2 = Player.create!(
        player_name: 'test_player_2',
        player_acc_type: 'Reg',
        attack_rank: -1,  # Unranked
        attack_lvl: 99,
        attack_xp: 13034431
      )
      player3 = Player.create!(
        player_name: 'test_player_3',
        player_acc_type: 'Reg',
        attack_rank: 5,
        attack_lvl: 99,
        attack_xp: 13034431
      )

      # Sort using the new rank_sort_sql method
      sorted_players = Player
        .where("player_name LIKE 'test_player_%'")
        .order(Arel.sql(Player.rank_sort_sql('attack_rank')))
        .to_a

      # Player with rank 1 should be first, then rank 5, then rank -1 (unranked) last
      expect(sorted_players.map(&:player_name)).to eq(['test_player_1', 'test_player_3', 'test_player_2'])
      expect(sorted_players[0].attack_rank).to eq(1)
      expect(sorted_players[1].attack_rank).to eq(5)
      expect(sorted_players[2].attack_rank).to eq(-1)
    end

    it 'handles multiple unranked players consistently' do
      # Create multiple unranked players
      player1 = Player.create!(
        player_name: 'test_player_a',
        player_acc_type: 'Reg',
        lms_rank: -1,
        lms_score: 100
      )
      player2 = Player.create!(
        player_name: 'test_player_b',
        player_acc_type: 'Reg',
        lms_rank: -1,
        lms_score: 200
      )
      player3 = Player.create!(
        player_name: 'test_player_c',
        player_acc_type: 'Reg',
        lms_rank: 1,
        lms_score: 300
      )

      # Sort by score DESC, then rank (using rank_sort_sql)
      sorted_players = Player
        .where("player_name LIKE 'test_player_%'")
        .order(Arel.sql("lms_score DESC, #{Player.rank_sort_sql('lms_rank')}"))
        .to_a

      # Should be sorted by score DESC, with all unranked (-1) coming after ranked
      expect(sorted_players.map(&:player_name)).to eq(['test_player_c', 'test_player_b', 'test_player_a'])
    end

    after(:each) do
      # Clean up test players
      Player.where("player_name LIKE 'test_player_%'").destroy_all
    end
  end
end
