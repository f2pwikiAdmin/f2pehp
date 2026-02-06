require 'rails_helper'

RSpec.describe PlayerCleanupService do
  let(:player) { Player.create!(player_name: 'TestPlayer', player_acc_type: 'Reg', overall_lvl: 1000) }
  
  describe '#initialize' do
    it 'sets default values' do
      service = PlayerCleanupService.new
      expect(service.limit).to eq(100)
      expect(service.sleep_time).to eq(0.3)
      expect(service.start_id).to be_nil
      expect(service.dry_run).to be false
    end
    
    it 'accepts custom values' do
      service = PlayerCleanupService.new(limit: 50, sleep_time: 0.5, start_id: 100, dry_run: true)
      expect(service.limit).to eq(50)
      expect(service.sleep_time).to eq(0.5)
      expect(service.start_id).to eq(100)
      expect(service.dry_run).to be true
    end
  end
  
  describe '#execute' do
    context 'when player hiscores data is available' do
      before do
        player # Create player
        allow(Hiscores).to receive(:fetch_stats_by_acc).and_return({ overall_lvl: 1000 })
        allow_any_instance_of(PlayerCleanupService).to receive(:sleep)
      end
      
      it 'does not mark player as unavailable' do
        service = PlayerCleanupService.new(limit: 1)
        results = service.execute
        
        expect(results[:processed]).to eq(1)
        expect(results[:unavailable]).to eq(0)
        expect(results[:deleted]).to eq(0)
      end
    end
    
    context 'when player hiscores data is unavailable' do
      before do
        player # Create player
        allow(Hiscores).to receive(:fetch_stats_by_acc).and_return(nil)
        allow_any_instance_of(PlayerCleanupService).to receive(:sleep)
      end
      
      it 'marks player as unavailable in dry run mode' do
        service = PlayerCleanupService.new(limit: 1, dry_run: true)
        results = service.execute
        
        expect(results[:processed]).to eq(1)
        expect(results[:unavailable]).to eq(1)
        expect(results[:deleted]).to eq(0)
        expect(results[:unavailable_players].length).to eq(1)
        expect(Player.exists?(player.id)).to be true
      end
      
      it 'deletes player when not in dry run mode' do
        player_id = player.id
        service = PlayerCleanupService.new(limit: 1, dry_run: false)
        results = service.execute
        
        expect(results[:processed]).to eq(1)
        expect(results[:unavailable]).to eq(1)
        expect(results[:deleted]).to eq(1)
        expect(Player.exists?(player_id)).to be false
      end
    end
    
    context 'when an error occurs' do
      before do
        player # Create player
        allow(Hiscores).to receive(:fetch_stats_by_acc).and_raise(StandardError.new("API Error"))
        allow_any_instance_of(PlayerCleanupService).to receive(:sleep)
        allow(Rails.logger).to receive(:error)
      end
      
      it 'tracks errors and continues processing' do
        service = PlayerCleanupService.new(limit: 1)
        results = service.execute
        
        expect(results[:processed]).to eq(1)
        expect(results[:errors]).to eq(1)
        expect(Player.exists?(player.id)).to be true
      end
    end
    
    context 'with multiple players' do
      let!(:player1) { Player.create!(player_name: 'Player1', player_acc_type: 'Reg', overall_lvl: 1000) }
      let!(:player2) { Player.create!(player_name: 'Player2', player_acc_type: 'Reg', overall_lvl: 1200) }
      let!(:player3) { Player.create!(player_name: 'Player3', player_acc_type: 'Reg', overall_lvl: 800) }
      
      before do
        allow_any_instance_of(PlayerCleanupService).to receive(:sleep)
      end
      
      it 'processes multiple players correctly' do
        # Player1 is available, Player2 and Player3 are unavailable
        allow(Hiscores).to receive(:fetch_stats_by_acc).with('Player1', anything).and_return({ overall_lvl: 1000 })
        allow(Hiscores).to receive(:fetch_stats_by_acc).with('Player2', anything).and_return(nil)
        allow(Hiscores).to receive(:fetch_stats_by_acc).with('Player3', anything).and_return(nil)
        
        service = PlayerCleanupService.new(limit: 3, dry_run: false)
        results = service.execute
        
        expect(results[:processed]).to eq(3)
        expect(results[:unavailable]).to eq(2)
        expect(results[:deleted]).to eq(2)
        expect(Player.exists?(player1.id)).to be true
        expect(Player.exists?(player2.id)).to be false
        expect(Player.exists?(player3.id)).to be false
      end
    end
    
    context 'with start_id parameter' do
      let!(:player1) { Player.create!(player_name: 'Player1', player_acc_type: 'Reg', overall_lvl: 1000) }
      let!(:player2) { Player.create!(player_name: 'Player2', player_acc_type: 'Reg', overall_lvl: 1200) }
      
      before do
        allow(Hiscores).to receive(:fetch_stats_by_acc).and_return(nil)
        allow_any_instance_of(PlayerCleanupService).to receive(:sleep)
      end
      
      it 'only processes players from start_id onwards' do
        service = PlayerCleanupService.new(start_id: player2.id, dry_run: true)
        results = service.execute
        
        # Should only process player2, not player1
        expect(results[:processed]).to eq(1)
        expect(results[:unavailable_players].first[:id]).to eq(player2.id)
      end
    end
    
    context 'with different account types' do
      let!(:reg_player) { Player.create!(player_name: 'RegPlayer', player_acc_type: 'Reg', overall_lvl: 1000) }
      let!(:iron_player) { Player.create!(player_name: 'IronPlayer', player_acc_type: 'IM', overall_lvl: 1000) }
      let!(:hcim_player) { Player.create!(player_name: 'HCIMPlayer', player_acc_type: 'HCIM', overall_lvl: 1000) }
      
      before do
        allow(Hiscores).to receive(:fetch_stats_by_acc).and_return(nil)
        allow_any_instance_of(PlayerCleanupService).to receive(:sleep)
      end
      
      it 'handles all account types correctly' do
        service = PlayerCleanupService.new(limit: 3, dry_run: true)
        results = service.execute
        
        expect(results[:processed]).to eq(3)
        expect(results[:unavailable]).to eq(3)
        expect(results[:unavailable_players].map { |p| p[:name] }).to contain_exactly('RegPlayer', 'IronPlayer', 'HCIMPlayer')
      end
    end
  end
end
