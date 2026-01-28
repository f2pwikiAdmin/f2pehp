require 'rails_helper'

RSpec.describe Player, type: :model do
  describe 'rank normalization' do
    describe '.normalize_rank_value' do
      it 'returns sentinel value for -1' do
        expect(Player.normalize_rank_value(-1)).to eq(Player::UNRANKED_SENTINEL)
      end

      it 'returns unchanged value for positive ranks' do
        expect(Player.normalize_rank_value(1)).to eq(1)
        expect(Player.normalize_rank_value(100)).to eq(100)
        expect(Player.normalize_rank_value(999999)).to eq(999999)
      end

      it 'returns unchanged value for 0' do
        expect(Player.normalize_rank_value(0)).to eq(0)
      end
    end

    describe '.normalize_rank_column' do
      it 'generates correct CASE expression for rank columns' do
        result = Player.normalize_rank_column('attack_rank')
        expect(result).to include('CASE WHEN')
        expect(result).to include('attack_rank = -1')
        expect(result).to include('THEN')
        expect(result).to include(Player::UNRANKED_SENTINEL.to_s)
        expect(result).to include('ELSE attack_rank END')
      end
    end

    describe '#f2p_skill_rank with unranked players' do
      before do
        # Clean up any existing test data
        Player.where(player_name: ["RankedPlayer", "UnrankedPlayer", "BetterRankedPlayer"]).destroy_all
        
        # Create a player with a valid rank
        @ranked_player = Player.create!(
          player_name: "RankedPlayer",
          player_acc_type: "Reg",
          potential_p2p: 0,
          attack_ehp: 100.0,
          attack_lvl: 80,
          attack_xp: 2000000,
          attack_rank: 500,  # Has a real OSRS rank
          overall_ehp: 500.0
        )

        # Create a player with -1 rank (unranked on OSRS hiscores)
        @unranked_player = Player.create!(
          player_name: "UnrankedPlayer", 
          player_acc_type: "Reg",
          potential_p2p: 0,
          attack_ehp: 50.0,  # Lower EHP than ranked player
          attack_lvl: 70,
          attack_xp: 800000,
          attack_rank: -1,   # Unranked on OSRS
          overall_ehp: 250.0
        )

        # Create another ranked player with better stats
        @better_ranked_player = Player.create!(
          player_name: "BetterRankedPlayer",
          player_acc_type: "Reg",
          potential_p2p: 0,
          attack_ehp: 150.0,  # Highest EHP
          attack_lvl: 90,
          attack_xp: 5000000,
          attack_rank: 100,   # Better OSRS rank
          overall_ehp: 750.0
        )
      end

      after do
        Player.where(player_name: ["RankedPlayer", "UnrankedPlayer", "BetterRankedPlayer"]).destroy_all
      end

      it 'ranks unranked (-1) players worse than ranked players even with higher stats' do
        # BetterRankedPlayer should be rank 1 (highest EHP)
        better_rank = @better_ranked_player.f2p_skill_rank('attack')
        expect(better_rank).to eq(1)

        # RankedPlayer should be rank 2 (middle EHP, but has a valid rank)
        ranked_rank = @ranked_player.f2p_skill_rank('attack')
        expect(ranked_rank).to eq(2)

        # UnrankedPlayer should be rank 3 (lowest EHP, and -1 rank should be treated as worst)
        # Even though attack_rank is -1, normalization should prevent it from ranking first
        unranked_rank = @unranked_player.f2p_skill_rank('attack')
        expect(unranked_rank).to eq(3)
      end

      it 'compares two unranked players by other criteria' do
        # Create another unranked player with lower EHP
        worse_unranked = Player.create!(
          player_name: "WorseUnrankedPlayer",
          player_acc_type: "Reg",
          potential_p2p: 0,
          attack_ehp: 25.0,  # Lower EHP than UnrankedPlayer
          attack_lvl: 60,
          attack_xp: 300000,
          attack_rank: -1,   # Also unranked
          overall_ehp: 125.0
        )

        begin
          # When both have -1 ranks, should still rank by EHP/lvl/xp
          unranked_rank = @unranked_player.f2p_skill_rank('attack')
          worse_rank = worse_unranked.f2p_skill_rank('attack')
          
          # UnrankedPlayer has higher EHP, so should rank better than WorseUnrankedPlayer
          expect(unranked_rank).to be < worse_rank
        ensure
          worse_unranked.destroy
        end
      end
    end
  end
end
