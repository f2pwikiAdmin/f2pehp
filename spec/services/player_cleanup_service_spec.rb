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
    context 'when player has total level > F2P_MAX_TOTAL' do
      let!(:high_total_player) { Player.create!(player_name: 'HighTotal', player_acc_type: 'Reg', overall_lvl: Player::F2P_MAX_TOTAL + 106, potential_p2p: 0) }
      
      before do
        allow_any_instance_of(PlayerCleanupService).to receive(:sleep)
      end
      
      it 'flags player with total_level_exceeds_f2p_max reason' do
        service = PlayerCleanupService.new(limit: 1, dry_run: false)
        results = service.execute
        
        expect(results[:processed]).to eq(1)
        expect(results[:flagged_total_level]).to eq(1)
        expect(results[:flagged_verified]).to eq(0)
        
        high_total_player.reload
        expect(high_total_player.potential_p2p).to eq(1)
        expect(high_total_player.p2p_flag_reason).to eq(Player::P2P_FLAG_REASONS[:total_level_exceeds_f2p_max])
      end
      
      it 'reports what would happen in dry run mode' do
        service = PlayerCleanupService.new(limit: 1, dry_run: true)
        results = service.execute
        
        expect(results[:processed]).to eq(1)
        expect(results[:flagged_total_level]).to eq(1)
        
        high_total_player.reload
        expect(high_total_player.potential_p2p).to eq(0)
        expect(high_total_player.p2p_flag_reason).to be_nil
      end
      
      it 'does not fetch hiscores if total level already exceeds max' do
        expect(Hiscores).not_to receive(:fetch_stats_by_acc)
        
        service = PlayerCleanupService.new(limit: 1, dry_run: false)
        service.execute
      end
    end
    
    context 'when player hiscores data is available and player is F2P' do
      before do
        player # Create player
        allow(Hiscores).to receive(:fetch_stats_by_acc).and_return({ overall_lvl: 1000 })
        allow(player).to receive(:detailed_p2p_verification).and_return(false)
        allow_any_instance_of(PlayerCleanupService).to receive(:sleep)
      end
      
      it 'does not flag the player' do
        service = PlayerCleanupService.new(limit: 1, dry_run: false)
        results = service.execute
        
        expect(results[:processed]).to eq(1)
        expect(results[:flagged_total_level]).to eq(0)
        expect(results[:flagged_verified]).to eq(0)
        
        player.reload
        expect(player.potential_p2p).to eq(0)
        expect(player.p2p_flag_reason).to be_nil
      end
    end
    
    context 'when player hiscores data is available and player is P2P' do
      before do
        player # Create player
        # Mock hiscores to return P2P stats
        p2p_stats = { 
          overall_lvl: 1000,
          potential_p2p: 1  # Parser detected P2P
        }
        allow(Hiscores).to receive(:fetch_stats_by_acc).and_return(p2p_stats)
        allow_any_instance_of(PlayerCleanupService).to receive(:sleep)
      end
      
      it 'flags player with p2p reason' do
        service = PlayerCleanupService.new(limit: 1, dry_run: false)
        results = service.execute
        
        expect(results[:processed]).to eq(1)
        expect(results[:flagged_verified]).to eq(1)
        
        player.reload
        expect(player.potential_p2p).to eq(1)
        expect(player.p2p_flag_reason).to eq(Player::P2P_FLAG_REASONS[:p2p])
      end
    end
    
    context 'when player hiscores data is unavailable (nil)' do
      before do
        player # Create player
        allow(Hiscores).to receive(:fetch_stats_by_acc).and_return(nil)
        allow_any_instance_of(PlayerCleanupService).to receive(:sleep)
      end
      
      it 'does NOT flag the player based on unavailable hiscores' do
        service = PlayerCleanupService.new(limit: 1, dry_run: false)
        results = service.execute
        
        expect(results[:processed]).to eq(1)
        expect(results[:flagged_total_level]).to eq(0)
        expect(results[:flagged_verified]).to eq(0)
        
        player.reload
        expect(player.potential_p2p).to eq(0)
        expect(player.p2p_flag_reason).to be_nil
      end
      
      it 'does not include unavailable_players in results' do
        service = PlayerCleanupService.new(limit: 1, dry_run: true)
        results = service.execute
        
        expect(results[:processed]).to eq(1)
        expect(results[:flagged_total_level]).to eq(0)
        expect(results[:flagged_verified]).to eq(0)
        # unavailable_players is still tracked but should be empty since we don't track nil results
        expect(results[:unavailable_players]).to eq([])
      end
    end
    
    context 'when hiscores fetch raises an error' do
      before do
        player # Create player
        allow(Hiscores).to receive(:fetch_stats_by_acc).and_raise(StandardError.new("API Error"))
        allow_any_instance_of(PlayerCleanupService).to receive(:sleep)
        allow(Rails.logger).to receive(:error)
        allow(Rails.logger).to receive(:debug)
      end
      
      it 'tracks errors but does NOT flag the player' do
        service = PlayerCleanupService.new(limit: 1, dry_run: false)
        results = service.execute
        
        expect(results[:processed]).to eq(1)
        expect(results[:errors]).to eq(1)
        expect(results[:flagged_total_level]).to eq(0)
        expect(results[:flagged_verified]).to eq(0)
        
        player.reload
        expect(player.potential_p2p).to eq(0)
        expect(player.p2p_flag_reason).to be_nil
      end
    end
    
    context 'with multiple players' do
      let!(:player1) { Player.create!(player_name: 'Player1', player_acc_type: 'Reg', overall_lvl: 1000, potential_p2p: 0) }
      let!(:player2) { Player.create!(player_name: 'Player2', player_acc_type: 'Reg', overall_lvl: Player::F2P_MAX_TOTAL + 106, potential_p2p: 0) }  # High total
      let!(:player3) { Player.create!(player_name: 'Player3', player_acc_type: 'Reg', overall_lvl: 800, potential_p2p: 0) }
      
      before do
        allow_any_instance_of(PlayerCleanupService).to receive(:sleep)
        # Player1: F2P with available hiscores
        allow(Hiscores).to receive(:fetch_stats_by_acc).with('Player1', anything).and_return({ overall_lvl: 1000 })
        allow(player1).to receive(:detailed_p2p_verification).and_return(false)
        # Player2: High total (will be flagged before hiscores check)
        # Player3: P2P with available hiscores
        p2p_stats = { overall_lvl: 800, potential_p2p: 1 }
        allow(Hiscores).to receive(:fetch_stats_by_acc).with('Player3', anything).and_return(p2p_stats)
      end
      
      it 'processes multiple players correctly' do
        service = PlayerCleanupService.new(limit: 3, dry_run: false)
        results = service.execute
        
        expect(results[:processed]).to eq(3)
        expect(results[:flagged_total_level]).to eq(1)  # Player2
        expect(results[:flagged_verified]).to eq(1)  # Player3
        
        # Check individual player states
        player1.reload
        player2.reload
        player3.reload
        
        # Player1 should remain unflagged (F2P)
        expect(player1.potential_p2p).to eq(0)
        expect(player1.p2p_flag_reason).to be_nil
        
        # Player2 should be flagged for high total
        expect(player2.potential_p2p).to eq(1)
        expect(player2.p2p_flag_reason).to eq(Player::P2P_FLAG_REASONS[:total_level_exceeds_f2p_max])
        
        # Player3 should be flagged as verified P2P
        expect(player3.potential_p2p).to eq(1)
        expect(player3.p2p_flag_reason).to eq(Player::P2P_FLAG_REASONS[:p2p])
      end
    end
    
    context 'when a previously flagged player is now verified F2P' do
      let!(:flagged_player) { Player.create!(player_name: 'WasP2P', player_acc_type: 'Reg', overall_lvl: 1000, potential_p2p: 1, p2p_flag_reason: Player::P2P_FLAG_REASONS[:p2p]) }
      
      before do
        allow_any_instance_of(PlayerCleanupService).to receive(:sleep)
        # Hiscores shows player is now F2P
        allow(Hiscores).to receive(:fetch_stats_by_acc).and_return({ overall_lvl: 1000 })
        allow(flagged_player).to receive(:detailed_p2p_verification).and_return(false)
      end
      
      it 'unflags the player' do
        service = PlayerCleanupService.new(limit: 1, dry_run: false)
        results = service.execute
        
        expect(results[:processed]).to eq(1)
        expect(results[:flagged_total_level]).to eq(0)
        expect(results[:flagged_verified]).to eq(0)
        
        flagged_player.reload
        expect(flagged_player.potential_p2p).to eq(0)
        expect(flagged_player.p2p_flag_reason).to be_nil
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
      end
    end
    
    context 'with progress logging' do
      let!(:players) { (1..5).map { |i| Player.create!(player_name: "Player#{i}", player_acc_type: 'Reg', overall_lvl: 1000, potential_p2p: 0) } }
      
      before do
        allow(Hiscores).to receive(:fetch_stats_by_acc).and_return({ overall_lvl: 1000 })
        allow_any_instance_of(Player).to receive(:detailed_p2p_verification).and_return(false)
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
        expect(progress_messages[0]).to include('flagged_total_level=')
        expect(progress_messages[0]).to include('flagged_verified=')
        expect(progress_messages[0]).to include('errors=')
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
    
    context 'with total_level_exceeds_f2p_max flag reason' do
      let!(:high_total) { Player.create!(player_name: 'HighTotal', player_acc_type: 'Reg', overall_lvl: Player::F2P_MAX_TOTAL + 106, potential_p2p: 0) }
      
      before do
        allow_any_instance_of(PlayerCleanupService).to receive(:sleep)
      end
      
      it 'sets the correct reason when flagging player' do
        service = PlayerCleanupService.new(limit: 1, dry_run: false)
        service.execute
        
        high_total.reload
        expect(high_total.potential_p2p).to eq(1)
        expect(high_total.p2p_flag_reason).to eq(Player::P2P_FLAG_REASONS[:total_level_exceeds_f2p_max])
      end
      
      it 'can query flagged players with total_level scope' do
        # Create another player with p2p flag (different reason)
        p2p_player = Player.create!(
          player_name: 'P2PPlayer',
          player_acc_type: 'Reg',
          overall_lvl: 1000,
          potential_p2p: 1,
          p2p_flag_reason: Player::P2P_FLAG_REASONS[:p2p]
        )
        
        # Flag high_total player
        service = PlayerCleanupService.new(limit: 1, dry_run: false)
        service.execute
        
        high_total.reload
        
        # Query players with total_level reason
        total_level_players = Player.total_level_flagged
        
        expect(total_level_players).to include(high_total)
        expect(total_level_players).not_to include(p2p_player)
        expect(total_level_players.count).to eq(1)
      end
      
      it 'distinguishes between p2p and total_level reasons' do
        # Create a player flagged as P2P (via verification)
        p2p_player = Player.create!(
          player_name: 'P2PPlayer',
          player_acc_type: 'Reg',
          overall_lvl: 1000,
          potential_p2p: 1,
          p2p_flag_reason: Player::P2P_FLAG_REASONS[:p2p]
        )
        
        # Flag high_total via service
        service = PlayerCleanupService.new(limit: 1, dry_run: false)
        service.execute
        
        high_total.reload
        
        # Verify both are hidden but with different reasons
        expect(high_total.potential_p2p).to eq(1)
        expect(p2p_player.potential_p2p).to eq(1)
        
        expect(high_total.p2p_flag_reason).to eq(Player::P2P_FLAG_REASONS[:total_level_exceeds_f2p_max])
        expect(p2p_player.p2p_flag_reason).to eq(Player::P2P_FLAG_REASONS[:p2p])
        
        # Verify scopes work correctly
        expect(Player.total_level_flagged).to include(high_total)
        expect(Player.total_level_flagged).not_to include(p2p_player)
        
        expect(Player.p2p_flagged).to include(p2p_player)
        expect(Player.p2p_flagged).not_to include(high_total)
        
        expect(Player.all_hidden.count).to eq(2)
      end
    end
  end
end
