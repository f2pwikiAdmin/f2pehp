require 'rails_helper'

RSpec.describe 'P2P Check Failure Reporting', type: :model do
  describe 'Player#check_p2p_stats with logging' do
    let(:player) { Player.new(player_name: "TestPlayer", player_acc_type: "Reg") }
    
    before do
      allow(Rails.logger).to receive(:info)
      player.save(validate: false)
    end
    
    context 'when player is in fakes list' do
      before do
        allow(F2POSRSRanks::Application.config).to receive(:downcase_fakes)
          .and_return(['testplayer'])
      end
      
      it 'logs the failure reason' do
        stats = { "potential_p2p" => 0 }
        
        expect(Rails.logger).to receive(:info)
          .with(/\[P2P CHECK\].*FAILED.*fakes list/)
        
        player.check_p2p_stats(stats)
      end
      
      it 'sets p2p_check_reason if column exists' do
        stats = { "potential_p2p" => 0 }
        player.check_p2p_stats(stats)
        player.reload
        
        expect(player.potential_p2p).to eq(1)
        if player.respond_to?(:p2p_check_reason)
          expect(player.p2p_check_reason).to eq("In fakes list")
        end
      end
    end
    
    context 'when player is in false_p2p_flagged list' do
      before do
        allow(F2POSRSRanks::Application.config).to receive(:downcase_false_p2p_flagged)
          .and_return(['testplayer'])
      end
      
      it 'logs the pass reason' do
        stats = { 
          "potential_p2p" => 0,
          :f2p_levels_sum => 100,
          :members_skill_count => 9,
          :overall_lvl => 109
        }
        
        expect(Rails.logger).to receive(:info)
          .with(/\[P2P CHECK\].*PASSED.*false_p2p_flagged/)
        
        player.check_p2p_stats(stats)
      end
    end
    
    context 'when parser detects P2P' do
      it 'logs parser detection' do
        stats = { 
          "potential_p2p" => 10,
          :f2p_levels_sum => 100,
          :members_skill_count => 9
        }
        
        expect(Rails.logger).to receive(:info)
          .with(/\[P2P CHECK\].*FAILED.*Parser detected/)
        
        player.check_p2p_stats(stats)
      end
    end
    
    context 'when overall level exceeds F2P max' do
      it 'logs the level discrepancy' do
        stats = {
          "potential_p2p" => 0,
          :overall_lvl => 1500,  # Exceeds F2P max of 1494
          :f2p_levels_sum => 1485,
          :members_skill_count => 9
        }
        
        expect(Rails.logger).to receive(:info)
          .with(/\[P2P CHECK\].*FAILED.*Overall level.*exceeds/)
        
        player.check_p2p_stats(stats)
      end
      
      it 'includes the number of trained P2P levels' do
        stats = {
          "potential_p2p" => 0,
          :overall_lvl => 1500,
          :f2p_levels_sum => 1485,
          :members_skill_count => 9
        }
        
        expect(Rails.logger).to receive(:info)
          .with(/6 levels/)  # 1500 - 1494 = 6
        
        player.check_p2p_stats(stats)
      end
    end
    
    context 'when player passes all checks' do
      it 'logs successful F2P status' do
        stats = {
          "potential_p2p" => 0,
          :overall_lvl => 1494,  # Exactly F2P max
          :f2p_levels_sum => 1485,
          :members_skill_count => 9
        }
        
        expect(Rails.logger).to receive(:info)
          .with(/\[P2P CHECK\].*PASSED.*All checks passed/)
        
        player.check_p2p_stats(stats)
      end
    end
  end
  
  describe 'Player#update_with_reason' do
    let(:player) { Player.new(player_name: "TestPlayer", player_acc_type: "Reg") }
    
    before do
      player.save(validate: false)
    end
    
    it 'updates potential_p2p' do
      player.send(:update_with_reason, potential_p2p: 1, reason: "Test reason")
      player.reload
      expect(player.potential_p2p).to eq(1)
    end
    
    it 'is backward compatible when p2p_check_reason column does not exist' do
      # Should not raise error even if column doesn't exist
      expect {
        player.send(:update_with_reason, potential_p2p: 1, reason: "Test reason")
      }.not_to raise_error
    end
    
    it 'sets p2p_check_reason when column exists' do
      if Player.column_names.include?('p2p_check_reason')
        player.send(:update_with_reason, potential_p2p: 1, reason: "Test reason")
        player.reload
        expect(player.p2p_check_reason).to eq("Test reason")
      else
        pending("p2p_check_reason column not yet migrated")
      end
    end
  end
end
