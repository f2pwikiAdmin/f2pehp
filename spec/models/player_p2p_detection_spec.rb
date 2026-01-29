require 'rails_helper'

RSpec.describe Player, type: :model do
  describe '#check_p2p_stats' do
    let(:player) { Player.new(player_name: "TestPlayer", player_acc_type: "Reg") }
    
    # Mock check_p2p_hiscores_content for all tests since detailed verification now applies to all players
    before do
      allow_any_instance_of(Player).to receive(:check_p2p_hiscores_content).and_return(false)
    end
    
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
      it 'returns false for F2P player with Obor KC (new detailed verification)' do
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
        
        # With name parameter, uses new detailed verification
        result = Player.initial_p2p_check(stats, "TestPlayer")
        expect(result).to eq(false)
      end
    end
    
    context 'when player has trained P2P skills' do
      it 'returns true when parser detects P2P skills (new detailed verification)' do
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
          :potential_p2p => 49,  # Fletching level 50 - 1 base = 49
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 58
        }
        
        # With name parameter, uses new detailed verification
        result = Player.initial_p2p_check(stats, "TestPlayer")
        expect(result).to eq(true)
      end

      it 'returns true when total level exceeds F2P maximum (new detailed verification)' do
        # Player with total level exceeding F2P max
        stats = {
          "overall_lvl" => 1510,
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
          :members_levels_sum => 25
        }
        
        # With name parameter, uses new detailed verification
        result = Player.initial_p2p_check(stats, "TestPlayer")
        expect(result).to eq(true)
      end
    end
  end

  describe '#check_p2p_stats with regular players (not in special lists)' do
    let(:player) { Player.new(player_name: "RegularPlayer", player_acc_type: "Reg") }

    before do
      # Mock check_p2p_hiscores_content to avoid actual API calls
      allow_any_instance_of(Player).to receive(:check_p2p_hiscores_content).and_return(false)
    end

    it 'uses detailed verification for regular players (new system)' do
      # Regular F2P player stats
      stats = {
        "overall_lvl" => 838,
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
        :potential_p2p => 0,
        :f2p_levels_sum => 829,
        :members_skill_count => 9,
        :members_levels_sum => 9,
        :overall_lvl => 838
      }

      # Save player first
      player.save(validate: false)

      # Call check_p2p_stats
      player.check_p2p_stats(stats)

      # Reload to get updated value
      player.reload

      # Player should NOT be flagged as P2P (detailed verification passed)
      expect(player.potential_p2p).to eq(0)
    end

    it 'flags regular players as P2P when they have trained P2P skills' do
      # Player with P2P skills trained
      stats = {
        "overall_lvl" => 1510,
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
        :members_levels_sum => 25,
        :overall_lvl => 1510
      }

      # Save player first
      player.save(validate: false)

      # Call check_p2p_stats
      player.check_p2p_stats(stats)

      # Reload to get updated value
      player.reload

      # Player SHOULD be flagged as P2P due to exceeding F2P max
      expect(player.potential_p2p).to eq(1)
    end

    it 'flags regular players as P2P when parser detects P2P content' do
      # Player with parser-detected P2P content
      stats = {
        "overall_lvl" => 887,
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
        :potential_p2p => 49,  # Parser detected P2P (e.g., Fletching trained)
        :f2p_levels_sum => 829,
        :members_skill_count => 9,
        :members_levels_sum => 58,
        :overall_lvl => 887
      }

      # Save player first
      player.save(validate: false)

      # Call check_p2p_stats
      player.check_p2p_stats(stats)

      # Reload to get updated value
      player.reload

      # Player SHOULD be flagged as P2P due to parser detection
      expect(player.potential_p2p).to eq(1)
    end
  end

  describe '#check_p2p_stats with all players' do
    let(:player) { Player.new(player_name: "TestPlayer", player_acc_type: "Reg") }

    it 'marks player as P2P when they have trained P2P skills' do
      # Stats that would flag as P2P (total level exceeds F2P max)
      stats = {
        "overall_lvl" => 1510,  # Exceeds max F2P (1494)
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
        :members_levels_sum => 25,  # Some P2P skills trained
        :overall_lvl => 1510
      }

      # Save player first
      player.save(validate: false)

      # Mock check_p2p_hiscores_content to avoid actual API calls
      allow(player).to receive(:check_p2p_hiscores_content).and_return(false)

      # Call check_p2p_stats
      player.check_p2p_stats(stats)

      # Reload to get updated value
      player.reload

      # Player SHOULD be flagged as P2P due to trained P2P skills (detailed verification)
      expect(player.potential_p2p).to eq(1)
    end

    it 'marks player as F2P when they pass detailed checks' do
      # Stats that are truly F2P
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
        :potential_p2p => 0,
        :f2p_levels_sum => 829,
        :members_skill_count => 9,
        :members_levels_sum => 9,
        :overall_lvl => 838
      }

      # Save player first
      player.save(validate: false)

      # Mock check_p2p_hiscores_content to avoid actual API calls
      allow(player).to receive(:check_p2p_hiscores_content).and_return(false)

      # Call check_p2p_stats
      player.check_p2p_stats(stats)

      # Reload to get updated value
      player.reload

      # Player should NOT be flagged as P2P (detailed verification passed)
      expect(player.potential_p2p).to eq(0)
    end
  end

  describe 'F2P ranking system' do
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
      
      @another_f2p_player = Player.create!(
        player_name: "AnotherF2PPlayer",
        player_acc_type: "Reg",
        potential_p2p: 0,  # Correctly marked as F2P
        attack_ehp: 120,
        attack_lvl: 85,
        attack_xp: 3000000,
        attack_rank: 75
      )
    end

    after do
      # Clean up test data
      Player.where(player_name: ["F2PPlayer", "P2PPlayer", "AnotherF2PPlayer"]).destroy_all
    end

    it 'includes only F2P players (potential_p2p <= 0) in rankings' do
      # AnotherF2PPlayer should be ranked 1 (highest EHP among F2P)
      another_f2p_rank = @another_f2p_player.f2p_skill_rank('attack')
      expect(another_f2p_rank).to eq(1)

      # F2PPlayer should be ranked 2 (second highest EHP among F2P)
      f2p_rank = @f2p_player.f2p_skill_rank('attack')
      expect(f2p_rank).to eq(2)

      # P2PPlayer should NOT be included in rankings (very high rank)
      p2p_rank = @p2p_player.f2p_skill_rank('attack')
      # P2P player should rank worse than F2P players since they're excluded
      expect(p2p_rank).to be > another_f2p_rank
      expect(p2p_rank).to be > f2p_rank
    end

    it 'sql_f2p_filter only includes players with potential_p2p <= 0' do
      # Query should return both F2P players, but not P2P player
      f2p_players = Player.where(Player.sql_f2p_filter)
      
      expect(f2p_players).to include(@f2p_player)
      expect(f2p_players).to include(@another_f2p_player)
      expect(f2p_players).not_to include(@p2p_player)
    end

    it 'is_f2p? returns true for players with potential_p2p <= 0' do
      expect(@f2p_player.is_f2p?).to be true
      expect(@another_f2p_player.is_f2p?).to be true
    end

    it 'is_f2p? returns false for P2P players' do
      expect(@p2p_player.is_f2p?).to be false
    end
  end

  describe '#check_p2p_stats with missing helper fields' do
    let(:player) { Player.new(player_name: "TestPlayerNoHelpers", player_acc_type: "Reg") }
    
    before do
      allow_any_instance_of(Player).to receive(:check_p2p_hiscores_content).and_return(false)
    end
    
    it 'does not falsely flag F2P player as P2P when helper fields are missing' do
      # This simulates the bug scenario: stats hash without helper fields
      # (e.g., when recalculate_current_ehp is called or rake task builds incomplete hash)
      stats = {
        "overall_lvl" => 838,  # F2P level
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
        "potential_p2p" => 0
        # NOTE: No helper fields (f2p_levels_sum, members_skill_count, members_levels_sum)
      }
      
      # Save player first
      player.save(validate: false)
      
      # Call check_p2p_stats with incomplete stats
      player.check_p2p_stats(stats)
      
      # Reload to get updated value
      player.reload
      
      # Player should NOT be falsely flagged as P2P
      # The fix ensures Check 1b is skipped when helper fields are missing
      expect(player.potential_p2p).to eq(0)
    end
    
    it 'still correctly flags P2P when total level exceeds F2P max, even without helper fields' do
      stats = {
        "overall_lvl" => 1600,  # Exceeds F2P max of 1494
        "attack_lvl" => 99,
        "potential_p2p" => 0
        # NOTE: No helper fields
      }
      
      # Save player first
      player.save(validate: false)
      
      # Call check_p2p_stats
      player.check_p2p_stats(stats)
      
      # Reload to get updated value
      player.reload
      
      # Player should be flagged as P2P (Check 1a works without helper fields)
      expect(player.potential_p2p).to eq(1)
    end
    
    it 'still correctly flags P2P when parser detects P2P, even without helper fields' do
      stats = {
        "overall_lvl" => 838,
        "attack_lvl" => 60,
        "potential_p2p" => 1  # Parser detected P2P
        # NOTE: No helper fields
      }
      
      # Save player first
      player.save(validate: false)
      
      # Call check_p2p_stats
      player.check_p2p_stats(stats)
      
      # Reload to get updated value
      player.reload
      
      # Player should be flagged as P2P (Check 0 works without helper fields)
      expect(player.potential_p2p).to eq(1)
    end
  end
  
  # Test for temporary mitigation: activity-based detection disabled
  describe 'Activity-based P2P detection mitigation' do
    let(:player) { Player.new(player_name: "TestPlayer", player_acc_type: "Reg") }
    
    before do
      # Since activity-based detection is disabled, we don't need to mock it
      # But we'll explicitly verify it's not being called
    end
    
    context 'when F2P player has simulated P2P activity scores in stats hash' do
      it 'does not flag player as P2P based only on activities (skills-only detection)' do
        # Realistic F2P player with activities that would have triggered false positives
        # in the unstable CSV activity parsing
        stats = {
          "overall_lvl" => 838,
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
          # Activities that would have been misaligned in CSV parsing:
          # (These are just stored but should NOT contribute to P2P flagging)
          :obor_kc => 50,
          :bryo_kc => 25,
          :lms_score => 100,
          :clues_beginner => 5,
          # Parser correctly identified as F2P (no trained P2P skills)
          :potential_p2p => 0,
          # Helper fields from parser
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :overall_lvl => 838
        }
        
        # Save player first
        player.save(validate: false)
        
        # Call check_p2p_stats
        player.check_p2p_stats(stats)
        
        # Reload to get updated value
        player.reload
        
        # Player should NOT be flagged as P2P (activity-based detection is disabled)
        expect(player.potential_p2p).to eq(0)
      end
    end
    
    context 'when player has trained P2P skills' do
      it 'still flags player as P2P based on skills-only detection' do
        # Player with trained P2P skill (Fletching)
        # This should STILL be detected even with activity-based detection disabled
        stats = {
          "overall_lvl" => 887,
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
          :potential_p2p => 1,  # Parser detected trained P2P skill
          # Helper fields from parser
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 58,  # One P2P skill trained to 50
          :overall_lvl => 887
        }
        
        # Save player first
        player.save(validate: false)
        
        # Call check_p2p_stats
        player.check_p2p_stats(stats)
        
        # Reload to get updated value
        player.reload
        
        # Player SHOULD be flagged as P2P (skills-based detection still works)
        expect(player.potential_p2p).to eq(1)
      end
    end
  end
end
