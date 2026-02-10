require 'rails_helper'

RSpec.describe PlayerCleanupService do
  let(:player) { Player.create!(player_name: 'TestPlayer', player_acc_type: 'Reg', overall_lvl: 1000, potential_p2p: 0) }
  
  describe '#initialize' do
    it 'sets default values' do
      service = PlayerCleanupService.new
      expect(service.limit).to eq(100)
      expect(service.sleep_time).to eq(0.3)
      expect(service.start_id).to be_nil
      expect(service.dry_run).to be false
      expect(service.progress_every).to eq(50)
    end
    
    it 'accepts custom values' do
      service = PlayerCleanupService.new(limit: 50, sleep_time: 0.5, start_id: 100, dry_run: true, progress_every: 25)
      expect(service.limit).to eq(50)
      expect(service.sleep_time).to eq(0.5)
      expect(service.start_id).to eq(100)
      expect(service.dry_run).to be true
      expect(service.progress_every).to eq(25)
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
        expect(results[:flagged]).to eq(0)
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
        expect(results[:flagged]).to eq(0)
        expect(results[:unavailable_players].length).to eq(1)
        expect(Player.exists?(player.id)).to be true
        
        # Player should not be flagged in dry run
        player.reload
        expect(player.potential_p2p).to eq(0)
        expect(player.p2p_flag_reason).to be_nil
      end
      
      it 'flags/hides player when not in dry run mode' do
        player_id = player.id
        service = PlayerCleanupService.new(limit: 1, dry_run: false)
        results = service.execute
        
        expect(results[:processed]).to eq(1)
        expect(results[:unavailable]).to eq(1)
        expect(results[:flagged]).to eq(1)
        
        # Player should still exist but be flagged
        expect(Player.exists?(player_id)).to be true
        
        # Check flagging details
        player.reload
        expect(player.potential_p2p).to eq(1)
        expect(player.p2p_flag_reason).to eq(Player::P2P_FLAG_REASONS[:unavailable_hiscores])
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
      let!(:player1) { Player.create!(player_name: 'Player1', player_acc_type: 'Reg', overall_lvl: 1000, potential_p2p: 0) }
      let!(:player2) { Player.create!(player_name: 'Player2', player_acc_type: 'Reg', overall_lvl: 1200, potential_p2p: 0) }
      let!(:player3) { Player.create!(player_name: 'Player3', player_acc_type: 'Reg', overall_lvl: 800, potential_p2p: 0) }
      
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
        expect(results[:flagged]).to eq(2)
        
        # All players should still exist
        expect(Player.exists?(player1.id)).to be true
        expect(Player.exists?(player2.id)).to be true
        expect(Player.exists?(player3.id)).to be true
        
        # Check flagging status
        player1.reload
        player2.reload
        player3.reload
        
        expect(player1.potential_p2p).to eq(0)
        expect(player2.potential_p2p).to eq(1)
        expect(player2.p2p_flag_reason).to eq(Player::P2P_FLAG_REASONS[:unavailable_hiscores])
        expect(player3.potential_p2p).to eq(1)
        expect(player3.p2p_flag_reason).to eq(Player::P2P_FLAG_REASONS[:unavailable_hiscores])
      end
    end
    
    context 'with start_id parameter' do
      let!(:player1) { Player.create!(player_name: 'Player1', player_acc_type: 'Reg', overall_lvl: 1000, potential_p2p: 0) }
      let!(:player2) { Player.create!(player_name: 'Player2', player_acc_type: 'Reg', overall_lvl: 1200, potential_p2p: 0) }
      
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
      let!(:reg_player) { Player.create!(player_name: 'RegPlayer', player_acc_type: 'Reg', overall_lvl: 1000, potential_p2p: 0) }
      let!(:iron_player) { Player.create!(player_name: 'IronPlayer', player_acc_type: 'IM', overall_lvl: 1000, potential_p2p: 0) }
      let!(:hcim_player) { Player.create!(player_name: 'HCIMPlayer', player_acc_type: 'HCIM', overall_lvl: 1000, potential_p2p: 0) }
      
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
    
    context 'with progress logging' do
      let!(:players) { (1..5).map { |i| Player.create!(player_name: "Player#{i}", player_acc_type: 'Reg', overall_lvl: 1000, potential_p2p: 0) } }
      
      before do
        allow(Hiscores).to receive(:fetch_stats_by_acc).and_return(nil)
        allow_any_instance_of(PlayerCleanupService).to receive(:sleep)
      end
      
      it 'logs progress at specified intervals' do
        progress_messages = []
        progress_logger = ->(message) { progress_messages << message }
        
        service = PlayerCleanupService.new(limit: 5, dry_run: true, progress_every: 2, progress_logger: progress_logger)
        service.execute
        
        # Should log at 2nd and 4th player (every 2 players)
        expect(progress_messages.length).to eq(2)
        
        # Verify format of progress messages
        expect(progress_messages[0]).to match(/\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] Progress: 2 processed/)
        expect(progress_messages[0]).to include('player_id=')
        expect(progress_messages[0]).to include('unavailable=')
        expect(progress_messages[0]).to include('flagged=')
        expect(progress_messages[0]).to include('errors=')
      end
      
      it 'includes correct counters in progress output' do
        progress_messages = []
        progress_logger = ->(message) { progress_messages << message }
        
        # Setup: first 2 players available, next 3 unavailable
        allow(Hiscores).to receive(:fetch_stats_by_acc) do |name, _|
          ['Player1', 'Player2'].include?(name) ? { overall_lvl: 1000 } : nil
        end
        
        service = PlayerCleanupService.new(limit: 5, dry_run: true, progress_every: 3, progress_logger: progress_logger)
        service.execute
        
        # Should log at 3rd player
        expect(progress_messages.length).to eq(1)
        expect(progress_messages[0]).to include('3 processed')
        expect(progress_messages[0]).to include('unavailable=1')  # Only player3 unavailable at this point
        expect(progress_messages[0]).to include('flagged=0')  # Dry run
        expect(progress_messages[0]).to include('errors=0')
      end
      
      it 'does not log when progress_every is 0' do
        progress_messages = []
        progress_logger = ->(message) { progress_messages << message }
        
        service = PlayerCleanupService.new(limit: 5, dry_run: true, progress_every: 0, progress_logger: progress_logger)
        service.execute
        
        expect(progress_messages.length).to eq(0)
      end
      
      it 'does not log when progress_logger is nil' do
        service = PlayerCleanupService.new(limit: 5, dry_run: true, progress_every: 2, progress_logger: nil)
        
        # Should not raise error
        expect { service.execute }.not_to raise_error
      end
    end
    
    context 'with unavailable_hiscores flag reason' do
      before do
        allow(Hiscores).to receive(:fetch_stats_by_acc).and_return(nil)
        allow_any_instance_of(PlayerCleanupService).to receive(:sleep)
      end
      
      it 'sets the correct reason when flagging player' do
        player # Create player before running service
        service = PlayerCleanupService.new(limit: 1, dry_run: false)
        service.execute
        
        player.reload
        expect(player.potential_p2p).to eq(1)
        expect(player.p2p_flag_reason).to eq(Player::P2P_FLAG_REASONS[:unavailable_hiscores])
      end
      
      it 'allows querying flagged players with unavailable_hiscores scope' do
        player # Create player first to ensure it has a lower ID
        
        # Create another player with p2p flag (different reason)
        p2p_player = Player.create!(
          player_name: 'P2PPlayer',
          player_acc_type: 'Reg',
          overall_lvl: 1500,
          potential_p2p: 1,
          p2p_flag_reason: Player::P2P_FLAG_REASONS[:p2p]
        )
        
        # Flag the test player as unavailable_hiscores
        service = PlayerCleanupService.new(limit: 1, dry_run: false)
        service.execute
        
        # Query players with unavailable_hiscores reason
        unavailable_players = Player.unavailable_hiscores_hidden
        
        expect(unavailable_players).to include(player)
        expect(unavailable_players).not_to include(p2p_player)
        expect(unavailable_players.count).to eq(1)
      end
      
      it 'distinguishes between p2p and unavailable_hiscores reasons' do
        player # Create player first
        
        # Create a player flagged as P2P
        p2p_player = Player.create!(
          player_name: 'P2PPlayer',
          player_acc_type: 'Reg',
          overall_lvl: 1500,
          potential_p2p: 1,
          p2p_flag_reason: Player::P2P_FLAG_REASONS[:p2p]
        )
        
        # Flag test player as unavailable_hiscores
        service = PlayerCleanupService.new(limit: 1, dry_run: false)
        service.execute
        
        player.reload
        
        # Verify both are hidden but with different reasons
        expect(player.potential_p2p).to eq(1)
        expect(p2p_player.potential_p2p).to eq(1)
        
        expect(player.p2p_flag_reason).to eq(Player::P2P_FLAG_REASONS[:unavailable_hiscores])
        expect(p2p_player.p2p_flag_reason).to eq(Player::P2P_FLAG_REASONS[:p2p])
        
        # Verify scopes work correctly
        expect(Player.unavailable_hiscores_hidden).to include(player)
        expect(Player.unavailable_hiscores_hidden).not_to include(p2p_player)
        
        expect(Player.p2p_flagged).to include(p2p_player)
        expect(Player.p2p_flagged).not_to include(player)
        
        expect(Player.all_hidden.count).to eq(2)
      end
    end
  end
end
