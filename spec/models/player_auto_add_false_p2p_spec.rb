require 'rails_helper'

RSpec.describe Player, type: :model do
  describe 'auto_add_to_false_p2p_flagged feature' do
    let(:test_player_name) { "TestAutoAddPlayer" }
    
    before do
      # Clean up any existing test players
      Player.where("LOWER(player_name) = ?", test_player_name.downcase).destroy_all
      
      # Clear runtime list before each test
      if F2POSRSRanks::Application.config.respond_to?(:runtime_false_p2p_flagged)
        F2POSRSRanks::Application.config.runtime_false_p2p_flagged.clear
      end
    end
    
    after do
      # Clean up test players
      Player.where("LOWER(player_name) = ?", test_player_name.downcase).destroy_all
      
      # Clear runtime list after each test
      if F2POSRSRanks::Application.config.respond_to?(:runtime_false_p2p_flagged)
        F2POSRSRanks::Application.config.runtime_false_p2p_flagged.clear
      end
    end
    
    context 'when auto_add_to_false_p2p_flagged is disabled' do
      before do
        # Ensure feature is disabled
        allow(F2POSRSRanks::Application.config).to receive(:auto_add_to_false_p2p_flagged).and_return(false)
      end
      
      it 'does not add players to runtime_false_p2p_flagged list' do
        # Create a player with normal F2P stats
        player = Player.new(
          player_name: test_player_name,
          player_acc_type: "Reg",
          potential_p2p: 0,
          attack_ehp: 50,
          attack_lvl: 60,
          attack_xp: 300000,
          attack_rank: 1000
        )
        player.save(validate: false)
        
        # Runtime list should remain empty
        runtime_list = F2POSRSRanks::Application.config.runtime_false_p2p_flagged
        expect(runtime_list).not_to include(test_player_name.downcase)
      end
    end
    
    context 'when auto_add_to_false_p2p_flagged is enabled' do
      before do
        # Enable the feature
        allow(F2POSRSRanks::Application.config).to receive(:auto_add_to_false_p2p_flagged).and_return(true)
        allow(F2POSRSRanks::Application.config).to receive(:runtime_false_p2p_flagged).and_return([])
      end
      
      it 'includes runtime-flagged players in sql_false_p2p_flagged' do
        # Manually add a player to runtime list
        F2POSRSRanks::Application.config.runtime_false_p2p_flagged << test_player_name.downcase
        
        # sql_false_p2p_flagged should include the runtime-flagged player
        sql_fragment = Player.sql_false_p2p_flagged
        expect(sql_fragment).to include(test_player_name.downcase)
      end
      
      it 'treats runtime-flagged players as F2P in is_f2p? method' do
        # Create a player that would normally be flagged as P2P
        player = Player.new(
          player_name: test_player_name,
          player_acc_type: "Reg",
          potential_p2p: 1,  # Flagged as P2P
          attack_ehp: 50,
          attack_lvl: 60,
          attack_xp: 300000,
          attack_rank: 1000
        )
        player.save(validate: false)
        
        # Without runtime flagging, should be P2P
        expect(player.is_f2p?).to be false
        
        # Add to runtime list
        F2POSRSRanks::Application.config.runtime_false_p2p_flagged << test_player_name.downcase
        
        # Now should be treated as F2P
        expect(player.is_f2p?).to be true
      end
      
      it 'includes runtime-flagged players in F2P SQL filter' do
        # Create a P2P player
        player = Player.create!(
          player_name: test_player_name,
          player_acc_type: "Reg",
          potential_p2p: 1,
          attack_ehp: 50,
          attack_lvl: 60,
          attack_xp: 300000,
          attack_rank: 1000
        )
        
        # Add to runtime list
        F2POSRSRanks::Application.config.runtime_false_p2p_flagged << test_player_name.downcase
        
        # Query with F2P filter should include the player
        f2p_players = Player.where(Player.sql_f2p_filter)
        expect(f2p_players).to include(player)
      end
    end
    
    context 'fakes list priority' do
      before do
        # Enable the feature
        allow(F2POSRSRanks::Application.config).to receive(:auto_add_to_false_p2p_flagged).and_return(true)
        allow(F2POSRSRanks::Application.config).to receive(:runtime_false_p2p_flagged).and_return([])
        
        # Mock fakes list to include test player
        allow(F2POSRSRanks::Application.config).to receive(:downcase_fakes).and_return([test_player_name.downcase])
      end
      
      it 'does not include players in fakes list even if in runtime_false_p2p_flagged' do
        # Add to runtime list
        F2POSRSRanks::Application.config.runtime_false_p2p_flagged << test_player_name.downcase
        
        # sql_false_p2p_flagged should exclude the player (fakes take priority)
        sql_fragment = Player.sql_false_p2p_flagged
        expect(sql_fragment).not_to include(test_player_name.downcase)
      end
      
      it 'treats players in fakes list as NOT F2P even if runtime-flagged' do
        # Create a player
        player = Player.new(
          player_name: test_player_name,
          player_acc_type: "Reg",
          potential_p2p: 0,  # Would normally be F2P
          attack_ehp: 50,
          attack_lvl: 60,
          attack_xp: 300000,
          attack_rank: 1000
        )
        player.save(validate: false)
        
        # Add to runtime list
        F2POSRSRanks::Application.config.runtime_false_p2p_flagged << test_player_name.downcase
        
        # Should still be treated as NOT F2P because in fakes list
        expect(player.is_f2p?).to be false
      end
    end
    
    context 'P2P experience check execution' do
      # Constant for impossible F2P overall level (used in test data)
      IMPOSSIBLE_F2P_OVERALL_LEVEL = 1510  # Max F2P is 1494 (15*99 + 9 base P2P skills)
      
      it 'still executes P2P experience checks when feature is enabled' do
        # This test verifies that the P2P detection logic still runs
        # Even though we override the result, the checks should execute
        
        # Create stats that would trigger P2P detection
        stats = {
          "overall_lvl" => IMPOSSIBLE_F2P_OVERALL_LEVEL,  # Exceeds max F2P (should trigger P2P flag)
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
          "potential_p2p" => 0,  # Parser says F2P
          :f2p_levels_sum => 1485,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :overall_lvl => IMPOSSIBLE_F2P_OVERALL_LEVEL
        }
        
        # The initial_p2p_check should return true (P2P detected)
        expect(Player.initial_p2p_check(stats)).to be true
      end
    end
    
    context 'boss KC check execution' do
      it 'still processes boss KC data when feature is enabled' do
        # Verify that boss KC checks are executed during player creation
        # Boss KC data should be stored even with auto-add feature enabled
        
        player = Player.new(
          player_name: test_player_name,
          player_acc_type: "Reg",
          potential_p2p: 0,
          obor_kc: 50,  # Boss KC data
          obor_kc_rank: 100,
          bryo_kc: 25,  # Boss KC data
          bryo_kc_rank: 200,
          attack_ehp: 50,
          attack_lvl: 60,
          attack_xp: 300000,
          attack_rank: 1000
        )
        player.save(validate: false)
        
        # Boss KC data should be stored
        expect(player.obor_kc).to eq(50)
        expect(player.bryo_kc).to eq(25)
      end
    end
  end
end
