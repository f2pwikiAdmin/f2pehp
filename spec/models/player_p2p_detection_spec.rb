require 'rails_helper'

RSpec.describe Player, type: :model do
  describe '#check_p2p_stats' do
    let(:player) { Player.new(player_name: "TestPlayer", player_acc_type: "Reg") }
    
    context 'when player has F2P boss kill counts but no P2P skills' do
      it 'does not flag player as P2P based on Obor KC' do
        stats = {
          "overall_lvl" => 750,
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
          :potential_p2p => 0  # Parser correctly identified as F2P
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
        stats = {
          "overall_lvl" => 750,
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
          :potential_p2p => 0  # Parser correctly identified as F2P
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
        stats = {
          "overall_lvl" => 750,
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
          :potential_p2p => 0  # Parser correctly identified as F2P
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
        stats = {
          "overall_lvl" => 850,
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
          :potential_p2p => 100000  # Parser detected P2P (e.g., Fletching XP)
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
    
    context 'when player has impossible F2P stats' do
      it 'flags player as P2P when overall level exceeds F2P maximum' do
        stats = {
          "overall_lvl" => 1500,  # Exceeds F2P max of 1494
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
          :potential_p2p => 0  # Parser might not detect if it's just level discrepancy
        }
        
        # Save player first
        player.save(validate: false)
        
        # Call check_p2p_stats
        player.check_p2p_stats(stats)
        
        # Reload to get updated value
        player.reload
        
        # Player SHOULD be flagged as P2P due to impossible stats
        expect(player.potential_p2p).to eq(1)
      end
    end
  end
  
  describe '.initial_p2p_check' do
    context 'when player has F2P boss kill counts but no P2P skills' do
      it 'returns false for F2P player with Obor KC' do
        stats = {
          "overall_lvl" => 750,
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
          :potential_p2p => 0
        }
        
        result = Player.initial_p2p_check(stats)
        expect(result).to eq(false)
      end
    end
    
    context 'when player has trained P2P skills' do
      it 'returns true when parser detects P2P skills' do
        stats = {
          "overall_lvl" => 850,
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
          :potential_p2p => 100000
        }
        
        result = Player.initial_p2p_check(stats)
        expect(result).to eq(true)
      end
    end
  end
end
