require 'rails_helper'

RSpec.describe Player, type: :model do
  describe 'F2P activity verification signals (Obor/Bryophyta KC and beginner clues)' do
    let(:player) { Player.new(player_name: "TestPlayer", player_acc_type: "Reg") }
    
    # Mock check_p2p_hiscores_content to avoid external API calls
    before do
      allow_any_instance_of(Player).to receive(:check_p2p_hiscores_content).and_return(false)
    end
    
    context 'player with F2P boss KC present' do
      it 'logs Obor KC as a positive F2P verification signal' do
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
          :obor_kc => 50,
          :obor_kc_rank => 1000,
          :potential_p2p => 0,
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :overall_lvl => 838
        }
        
        player.save(validate: false)
        
        # Check that the logging occurs
        expect(Rails.logger).to receive(:info).with(/Obor KC: 50/)
        
        player.check_p2p_stats(stats)
        player.reload
        
        # Player should NOT be flagged as P2P
        expect(player.potential_p2p).to eq(0)
      end
      
      it 'logs Bryophyta KC as a positive F2P verification signal' do
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
          :bryo_kc => 25,
          :bryo_kc_rank => 500,
          :potential_p2p => 0,
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :overall_lvl => 838
        }
        
        player.save(validate: false)
        
        # Check that the logging occurs
        expect(Rails.logger).to receive(:info).with(/Bryophyta KC: 25/)
        
        player.check_p2p_stats(stats)
        player.reload
        
        # Player should NOT be flagged as P2P
        expect(player.potential_p2p).to eq(0)
      end
      
      it 'logs both Obor and Bryophyta KC when both are present' do
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
          :obor_kc => 50,
          :obor_kc_rank => 1000,
          :bryo_kc => 25,
          :bryo_kc_rank => 500,
          :potential_p2p => 0,
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :overall_lvl => 838
        }
        
        player.save(validate: false)
        
        # Check that the logging occurs with both
        expect(Rails.logger).to receive(:info).with(/Obor KC: 50.*Bryophyta KC: 25/)
        
        player.check_p2p_stats(stats)
        player.reload
        
        # Player should NOT be flagged as P2P
        expect(player.potential_p2p).to eq(0)
      end
    end
    
    context 'player with beginner clues present' do
      it 'logs beginner clues as a positive F2P verification signal' do
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
          :clues_beginner => 15,
          :clues_beginner_rank => 5000,
          :potential_p2p => 0,
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :overall_lvl => 838
        }
        
        player.save(validate: false)
        
        # Check that the logging occurs
        expect(Rails.logger).to receive(:info).with(/Beginner clues: 15/)
        
        player.check_p2p_stats(stats)
        player.reload
        
        # Player should NOT be flagged as P2P
        expect(player.potential_p2p).to eq(0)
      end
      
      it 'logs all F2P activities when boss KC and beginner clues are present' do
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
          :obor_kc => 50,
          :obor_kc_rank => 1000,
          :bryo_kc => 25,
          :bryo_kc_rank => 500,
          :clues_beginner => 15,
          :clues_beginner_rank => 5000,
          :potential_p2p => 0,
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :overall_lvl => 838
        }
        
        player.save(validate: false)
        
        # Check that the logging occurs with all activities
        expect(Rails.logger).to receive(:info).with(/Obor KC: 50.*Bryophyta KC: 25.*Beginner clues: 15/)
        
        player.check_p2p_stats(stats)
        player.reload
        
        # Player should NOT be flagged as P2P
        expect(player.potential_p2p).to eq(0)
      end
    end
    
    context 'player with neither boss KC nor beginner clues present (still valid F2P)' do
      it 'does not flag player as P2P when no F2P activities are present' do
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
          :obor_kc => 0,
          :bryo_kc => 0,
          :clues_beginner => 0,
          :potential_p2p => 0,
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :overall_lvl => 838
        }
        
        player.save(validate: false)
        
        # Check that appropriate logging occurs
        expect(Rails.logger).to receive(:info).with(/has no F2P boss KC or beginner clues \(acceptable/)
        
        player.check_p2p_stats(stats)
        player.reload
        
        # Player should NOT be flagged as P2P - lack of F2P activities is acceptable
        expect(player.potential_p2p).to eq(0)
      end
      
      it 'does not flag player as P2P when F2P activity fields are missing from stats' do
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
          # No obor_kc, bryo_kc, or clues_beginner fields at all
          :potential_p2p => 0,
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :overall_lvl => 838
        }
        
        player.save(validate: false)
        
        player.check_p2p_stats(stats)
        player.reload
        
        # Player should NOT be flagged as P2P - missing data is acceptable
        expect(player.potential_p2p).to eq(0)
      end
    end
    
    context 'hiscores endpoint unavailable or partial response' do
      it 'does not block player as non-F2P when hiscores data is incomplete' do
        # Simulating a partial hiscores response where some fields are missing
        stats = {
          "overall_lvl" => 838,
          "attack_lvl" => 60,
          "strength_lvl" => 60,
          # Some skills missing
          "defence_lvl" => 60,
          "hitpoints_lvl" => 60,
          # No boss KC or clues data due to partial response
          :potential_p2p => 0,
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :overall_lvl => 838
        }
        
        player.save(validate: false)
        
        player.check_p2p_stats(stats)
        player.reload
        
        # Player should NOT be flagged as P2P despite incomplete data
        expect(player.potential_p2p).to eq(0)
      end
      
      it 'treats nil values as zero (no F2P activity) and does not flag as P2P' do
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
          :obor_kc => nil,
          :bryo_kc => nil,
          :clues_beginner => nil,
          :potential_p2p => 0,
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :overall_lvl => 838
        }
        
        player.save(validate: false)
        
        player.check_p2p_stats(stats)
        player.reload
        
        # Player should NOT be flagged as P2P - nil values are treated as zero
        expect(player.potential_p2p).to eq(0)
      end
    end
  end
  
  describe 'Initial player creation with F2P activity verification' do
    context 'creating a new player with F2P boss KC' do
      it 'logs Obor KC during player creation and allows F2P player' do
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
          :obor_kc => 50,
          :obor_kc_rank => 1000,
          :potential_p2p => 0,
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :overall_lvl => 838
        }
        
        # Check that logging occurs during creation
        expect(Rails.logger).to receive(:info).with(/Obor KC: 50/)
        
        result = Player.initial_p2p_check(stats, "TestPlayer")
        
        # Player should be allowed (returns false = not P2P)
        expect(result).to eq(false)
      end
      
      it 'logs beginner clues during player creation and allows F2P player' do
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
          :clues_beginner => 15,
          :clues_beginner_rank => 5000,
          :potential_p2p => 0,
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :overall_lvl => 838
        }
        
        # Check that logging occurs during creation
        expect(Rails.logger).to receive(:info).with(/Beginner clues: 15/)
        
        result = Player.initial_p2p_check(stats, "TestPlayer")
        
        # Player should be allowed (returns false = not P2P)
        expect(result).to eq(false)
      end
      
      it 'allows player creation when no F2P activities are present' do
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
          :obor_kc => 0,
          :bryo_kc => 0,
          :clues_beginner => 0,
          :potential_p2p => 0,
          :f2p_levels_sum => 829,
          :members_skill_count => 9,
          :members_levels_sum => 9,
          :overall_lvl => 838
        }
        
        result = Player.initial_p2p_check(stats, "TestPlayer")
        
        # Player should be allowed (returns false = not P2P)
        # Lack of F2P activities should NOT prevent player creation
        expect(result).to eq(false)
      end
    end
  end
end
