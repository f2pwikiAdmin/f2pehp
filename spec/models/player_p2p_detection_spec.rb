require 'rails_helper'

RSpec.describe Player, type: :model do
  describe '#check_p2p_stats' do
    let(:player) { Player.new(player_name: "TestPlayer", player_acc_type: "Reg") }
    
    context 'when player has F2P boss kill counts but no P2P skills' do
      it 'does not flag player as P2P based on Obor KC' do
        # Realistic test data from Jagex API:
        # F2P skills sum: 60+60+60+60+60+45+55+70+60+65+50+40+40+60+44 = 829
        # P2P skills (all at base level 1): 9 × 1 = 9
        # Overall from Jagex: 829 + 9 = 838
        stats = {
          "overall_lvl" => 838,  # Includes 9 base P2P skill levels
          "attack_lvl" => 60,
          "strength_lvl" => 60,
          "defence_lvl" => 60,
          "hitpoints_lvl" => 60,
          "ranged_lvl" => 60,
          "prayer_lvl" => 45,
          "magic_lvl" => 55,
          "cooking_lvl" => 70,
          "woodcutting_lvl" => 60,
          "fishing_lvl" => 65,
          "firemaking_lvl" => 50,
          "crafting_lvl" => 40,
          "smithing_lvl" => 40,
          "mining_lvl" => 60,
          "runecraft_lvl" => 44,
          :obor_kc => 50,
          :obor_kc_rank => 1000,
          :potential_p2p => 0,  # Parser correctly identified as F2P
          # Helper fields from parser
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 9,  # All at base level 1
          :p2p_minigame_score_sum => 0,
          :overall_lvl => 838
        }
        
        # Save player first
        player.save(validate: false)
        
        # Call check_p2p_stats
        player.check_p2p_stats(stats)
        
        # Reload to get updated value
        player.reload
        
        # Player should NOT be flagged as P2P
        expect(player.potential_p2p).to eq(0)
      end
      
      it 'does not flag player as P2P based on Bryophyta KC' do
        # Realistic test data from Jagex API
        stats = {
          "overall_lvl" => 838,  # F2P skills (829) + base P2P (9)
          "attack_lvl" => 60,
          "strength_lvl" => 60,
          "defence_lvl" => 60,
          "hitpoints_lvl" => 60,
          "ranged_lvl" => 60,
          "prayer_lvl" => 45,
          "magic_lvl" => 55,
          "cooking_lvl" => 70,
          "woodcutting_lvl" => 60,
          "fishing_lvl" => 65,
          "firemaking_lvl" => 50,
          "crafting_lvl" => 40,
          "smithing_lvl" => 40,
          "mining_lvl" => 60,
          "runecraft_lvl" => 44,
          :bryo_kc => 25,
          :bryo_kc_rank => 500,
          :potential_p2p => 0,  # Parser correctly identified as F2P
          # Helper fields from parser
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :p2p_minigame_score_sum => 0,
          :overall_lvl => 838
        }
        
        # Save player first
        player.save(validate: false)
        
        # Call check_p2p_stats
        player.check_p2p_stats(stats)
        
        # Reload to get updated value
        player.reload
        
        # Player should NOT be flagged as P2P
        expect(player.potential_p2p).to eq(0)
      end
      
      it 'does not flag player as P2P based on both Obor and Bryophyta KCs' do
        # Realistic test data from Jagex API
        stats = {
          "overall_lvl" => 838,  # F2P skills (829) + base P2P (9)
          "attack_lvl" => 60,
          "strength_lvl" => 60,
          "defence_lvl" => 60,
          "hitpoints_lvl" => 60,
          "ranged_lvl" => 60,
          "prayer_lvl" => 45,
          "magic_lvl" => 55,
          "cooking_lvl" => 70,
          "woodcutting_lvl" => 60,
          "fishing_lvl" => 65,
          "firemaking_lvl" => 50,
          "crafting_lvl" => 40,
          "smithing_lvl" => 40,
          "mining_lvl" => 60,
          "runecraft_lvl" => 44,
          :obor_kc => 50,
          :obor_kc_rank => 1000,
          :bryo_kc => 25,
          :bryo_kc_rank => 500,
          :potential_p2p => 0,  # Parser correctly identified as F2P
          # Helper fields from parser
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :p2p_minigame_score_sum => 0,
          :overall_lvl => 838
        }
        
        # Save player first
        player.save(validate: false)
        
        # Call check_p2p_stats
        player.check_p2p_stats(stats)
        
        # Reload to get updated value
        player.reload
        
        # Player should NOT be flagged as P2P
        expect(player.potential_p2p).to eq(0)
      end
    end
    
    context 'when player has trained P2P skills' do
      it 'flags player as P2P when parser detects P2P skills' do
        # Player with trained P2P: F2P (829) + 8 base P2P at lvl 1 (8) + Fletching (50) = 887
        # Note: There are 9 P2P skills total, but one (Fletching) is trained to 50
        stats = {
          "overall_lvl" => 887,  # F2P (829) + 8 base P2P (8) + Fletching (50)
          "attack_lvl" => 60,
          "strength_lvl" => 60,
          "defence_lvl" => 60,
          "hitpoints_lvl" => 60,
          "ranged_lvl" => 60,
          "prayer_lvl" => 45,
          "magic_lvl" => 55,
          "cooking_lvl" => 70,
          "woodcutting_lvl" => 60,
          "fishing_lvl" => 65,
          "firemaking_lvl" => 50,
          "crafting_lvl" => 40,
          "smithing_lvl" => 40,
          "mining_lvl" => 60,
          "runecraft_lvl" => 44,
          :potential_p2p => 49,  # Parser detected P2P (Fletching level 50 - 1 = 49)
          # Helper fields from parser
          :f2p_levels_sum => 829,
          :members_skill_count => 9,  # All 9 P2P skills counted
          :members_levels_sum => 58,  # 8 at level 1 (=8) + Fletching at 50 (=50) = 58
          :p2p_minigame_score_sum => 0,
          :overall_lvl => 887
        }
        
        # Save player first
        player.save(validate: false)
        
        # Call check_p2p_stats
        player.check_p2p_stats(stats)
        
        # Reload to get updated value
        player.reload
        
        # Player SHOULD be flagged as P2P
        expect(player.potential_p2p).to eq(1)
      end
    end
    
    context 'when player has maxed F2P account' do
      it 'does not flag maxed F2P player as P2P' do
        # Maxed F2P: all 15 F2P skills at 99 = 1485
        # Plus base P2P skills: 9 × 1 = 9
        # Total from Jagex: 1485 + 9 = 1494
        stats = {
          "overall_lvl" => 1494,  # Exactly at F2P maximum
          "attack_lvl" => 99,
          "strength_lvl" => 99,
          "defence_lvl" => 99,
          "hitpoints_lvl" => 99,
          "ranged_lvl" => 99,
          "prayer_lvl" => 99,
          "magic_lvl" => 99,
          "cooking_lvl" => 99,
          "woodcutting_lvl" => 99,
          "fishing_lvl" => 99,
          "firemaking_lvl" => 99,
          "crafting_lvl" => 99,
          "smithing_lvl" => 99,
          "mining_lvl" => 99,
          "runecraft_lvl" => 99,
          :potential_p2p => 0,  # Parser correctly says F2P
          # Helper fields from parser
          :f2p_levels_sum => 1485,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :p2p_minigame_score_sum => 0,
          :overall_lvl => 1494
        }
        
        # Save player first
        player.save(validate: false)
        
        # Call check_p2p_stats
        player.check_p2p_stats(stats)
        
        # Reload to get updated value
        player.reload
        
        # Maxed F2P player should NOT be flagged as P2P
        expect(player.potential_p2p).to eq(0)
      end
    end
    
    context 'when player has impossible F2P stats' do
      it 'flags player as P2P when overall level exceeds F2P maximum' do
        # F2P max: 15 skills × 99 = 1485, plus base P2P (9) = 1494
        # Any overall_lvl > 1494 means P2P skills trained
        stats = {
          "overall_lvl" => 1510,  # Exceeds max (1494)
          "attack_lvl" => 99,
          "strength_lvl" => 99,
          "defence_lvl" => 99,
          "hitpoints_lvl" => 99,
          "ranged_lvl" => 99,
          "prayer_lvl" => 99,
          "magic_lvl" => 99,
          "cooking_lvl" => 99,
          "woodcutting_lvl" => 99,
          "fishing_lvl" => 99,
          "firemaking_lvl" => 99,
          "crafting_lvl" => 99,
          "smithing_lvl" => 99,
          "mining_lvl" => 99,
          "runecraft_lvl" => 99,
          :potential_p2p => 0,  # Parser might not detect if it's just level discrepancy
          # Helper fields from parser
          :f2p_levels_sum => 1485,
          :members_skill_count => 9,
          :members_levels_sum => 9,  # But some must be higher to reach 1510
          :p2p_minigame_score_sum => 0,
          :overall_lvl => 1510
        }
        
        # Save player first
        player.save(validate: false)
        
        # Call check_p2p_stats
        player.check_p2p_stats(stats)
        
        # Reload to get updated value
        player.reload
        
        # Player SHOULD be flagged as P2P due to impossible stats
        # overall (1510) > f2p_sum (1485) + members_count (9) = 1494
        expect(player.potential_p2p).to eq(1)
      end
    end
  end
  
  describe '.initial_p2p_check' do
    context 'when player has F2P boss kill counts but no P2P skills' do
      it 'returns false for F2P player with Obor KC' do
        # Realistic test data from Jagex API
        stats = {
          "overall_lvl" => 838,  # F2P skills (829) + base P2P (9)
          "attack_lvl" => 60,
          "strength_lvl" => 60,
          "defence_lvl" => 60,
          "hitpoints_lvl" => 60,
          "ranged_lvl" => 60,
          "prayer_lvl" => 45,
          "magic_lvl" => 55,
          "cooking_lvl" => 70,
          "woodcutting_lvl" => 60,
          "fishing_lvl" => 65,
          "firemaking_lvl" => 50,
          "crafting_lvl" => 40,
          "smithing_lvl" => 40,
          "mining_lvl" => 60,
          "runecraft_lvl" => 44,
          :obor_kc => 50,
          :potential_p2p => 0,
          # Helper fields
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :p2p_minigame_score_sum => 0,
          :overall_lvl => 838
        }
        
        result = Player.initial_p2p_check(stats)
        expect(result).to eq(false)
      end
    end
    
    context 'when player has trained P2P skills' do
      it 'returns true when parser detects P2P skills' do
        # Player with trained P2P skills
        # 9 P2P skills total: 8 at level 1 + Fletching at 50
        stats = {
          "overall_lvl" => 887,  # F2P (829) + 8 base P2P (8) + Fletching (50)
          "attack_lvl" => 60,
          "strength_lvl" => 60,
          "defence_lvl" => 60,
          "hitpoints_lvl" => 60,
          "ranged_lvl" => 60,
          "prayer_lvl" => 45,
          "magic_lvl" => 55,
          "cooking_lvl" => 70,
          "woodcutting_lvl" => 60,
          "fishing_lvl" => 65,
          "firemaking_lvl" => 50,
          "crafting_lvl" => 40,
          "smithing_lvl" => 40,
          "mining_lvl" => 60,
          "runecraft_lvl" => 44,
          :potential_p2p => 49  # Fletching level 50 - 1 base = 49
        }
        
        result = Player.initial_p2p_check(stats)
        expect(result).to eq(true)
      end
    end
  end

  describe '#check_p2p_stats with false_p2p_flagged list' do
    let(:player) { Player.new(player_name: "FalseFlaggedPlayer", player_acc_type: "Reg") }

    before do
      # Mock the configuration to include our test player in the false_p2p_flagged list
      allow(F2POSRSRanks::Application.config).to receive(:downcase_false_p2p_flagged)
        .and_return(['falseflaggedplayer'])
    end

    it 'marks player in false_p2p_flagged list as F2P regardless of stats' do
      # Stats that would normally flag as P2P
      stats = {
        "overall_lvl" => 1510,  # Exceeds max F2P
        "attack_lvl" => 99,
        "strength_lvl" => 99,
        "defence_lvl" => 99,
        "hitpoints_lvl" => 99,
        "ranged_lvl" => 99,
        "prayer_lvl" => 99,
        "magic_lvl" => 99,
        "cooking_lvl" => 99,
        "woodcutting_lvl" => 99,
        "fishing_lvl" => 99,
        "firemaking_lvl" => 99,
        "crafting_lvl" => 99,
        "smithing_lvl" => 99,
        "mining_lvl" => 99,
        "runecraft_lvl" => 99,
        :potential_p2p => 0,
        :f2p_levels_sum => 1485,
        :members_skill_count => 9,
        :members_levels_sum => 9,
        :overall_lvl => 1510
      }

      # Save player first
      player.save(validate: false)

      # Call check_p2p_stats
      player.check_p2p_stats(stats)

      # Reload to get updated value
      player.reload

      # Player should NOT be flagged as P2P due to being in false_p2p_flagged list
      expect(player.potential_p2p).to eq(0)
    end
  end

  describe 'F2P ranking with false_p2p_flagged list' do
    before do
      # Create test players
      @f2p_player = Player.create!(
        player_name: "F2PPlayer",
        player_acc_type: "Reg",
        potential_p2p: 0,
        attack_ehp: 100,
        attack_lvl: 80,
        attack_xp: 2000000,
        attack_rank: 100
      )
      
      @p2p_player = Player.create!(
        player_name: "P2PPlayer",
        player_acc_type: "Reg",
        potential_p2p: 1,
        attack_ehp: 150,
        attack_lvl: 90,
        attack_xp: 5000000,
        attack_rank: 50
      )
      
      @false_flagged_player = Player.create!(
        player_name: "FalseFlaggedPlayer",
        player_acc_type: "Reg",
        potential_p2p: 1,  # Still flagged as P2P in DB
        attack_ehp: 120,
        attack_lvl: 85,
        attack_xp: 3000000,
        attack_rank: 75
      )

      # Mock the configuration to include FalseFlaggedPlayer in the false_p2p_flagged list
      allow(F2POSRSRanks::Application.config).to receive(:downcase_false_p2p_flagged)
        .and_return(['falseflaggedplayer'])
    end

    after do
      # Clean up test data
      Player.where(player_name: ["F2PPlayer", "P2PPlayer", "FalseFlaggedPlayer"]).destroy_all
    end

    it 'includes false_p2p_flagged players in F2P rankings' do
      # F2PPlayer should be ranked 2 (below false_flagged_player who has higher EHP)
      f2p_rank = @f2p_player.f2p_skill_rank('attack')
      expect(f2p_rank).to be > 1  # Not rank 1 since false_flagged_player has better stats

      # FalseFlaggedPlayer should be included in rankings despite potential_p2p = 1
      false_flagged_rank = @false_flagged_player.f2p_skill_rank('attack')
      expect(false_flagged_rank).to be > 0  # Should have a valid rank
      expect(false_flagged_rank).to be < f2p_rank  # Should rank better than f2p_player

      # P2PPlayer should NOT be included in rankings (very high rank)
      p2p_rank = @p2p_player.f2p_skill_rank('attack')
      # P2P player should rank worse than both F2P players since they're excluded
      expect(p2p_rank).to be > false_flagged_rank
      expect(p2p_rank).to be > f2p_rank
    end

    it 'sql_f2p_filter includes false_p2p_flagged players' do
      # Query should return both F2PPlayer and FalseFlaggedPlayer, but not P2PPlayer
      f2p_players = Player.where(Player.sql_f2p_filter)
      
      expect(f2p_players).to include(@f2p_player)
      expect(f2p_players).to include(@false_flagged_player)
      expect(f2p_players).not_to include(@p2p_player)
    end

    it 'sql_false_p2p_flagged returns correct SQL fragment' do
      sql_fragment = Player.sql_false_p2p_flagged
      expect(sql_fragment).to include('falseflaggedplayer')
      expect(sql_fragment).to match(/\(.*\)/)  # Should be wrapped in parentheses
    end
  end
end
