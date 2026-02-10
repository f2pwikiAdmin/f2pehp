# Service for cleaning up players with unavailable hiscores data
class PlayerCleanupService
  attr_reader :limit, :sleep_time, :start_id, :dry_run, :progress_every
  
  def initialize(limit: 100, sleep_time: 0.3, start_id: nil, dry_run: false, progress_every: 50, progress_logger: nil)
    @limit = limit
    @sleep_time = sleep_time
    @start_id = start_id
    @dry_run = dry_run
    @progress_every = progress_every
    @progress_logger = progress_logger
  end
  
  def execute
    stats = {
      processed: 0,
      unavailable: 0,
      flagged: 0,
      errors: 0,
      unavailable_players: []
    }
    
    query = build_query
    
    # Process players in batches
    # Batch size is fixed at 100 for efficient memory usage during find_each iteration
    # This is independent of the limit parameter which controls total players to check
    query.find_each(batch_size: 100) do |player|
      stats[:processed] += 1
      
      begin
        result = check_and_cleanup_player(player)
        
        if result[:unavailable]
          stats[:unavailable] += 1
          stats[:unavailable_players] << result[:player_info]
          
          if result[:flagged]
            stats[:flagged] += 1
          end
        end
        
      rescue => e
        stats[:errors] += 1
        Rails.logger.error "Error checking player #{player.player_name}: #{e.message}"
      end
      
      # Log progress at specified intervals
      log_progress(player, stats) if should_log_progress?(stats[:processed])
      
      sleep sleep_time
    end
    
    stats
  end
  
  private
  
  def build_query
    query = Player.order(:id)
    query = query.where("id >= ?", start_id) if start_id
    query = query.limit(limit) if limit
    query
  end
  
  def check_and_cleanup_player(player)
    stats = Hiscores.fetch_stats_by_acc(player.player_name, player.player_acc_type)
    
    if stats
      # Player is available
      { unavailable: false, flagged: false }
    else
      # Player is unavailable
      player_info = {
        id: player.id,
        name: player.player_name,
        total: player.overall_lvl,
        updated: player.updated_at
      }
      
      flagged = false
      unless dry_run
        # Flag/hide player instead of deleting
        player.update_columns(
          potential_p2p: 1,
          p2p_flag_reason: Player::P2P_FLAG_REASONS[:unavailable_hiscores]
        )
        flagged = true
        Rails.logger.info "Player #{player.player_name} (ID: #{player.id}) flagged as unavailable_hiscores"
      end
      
      { unavailable: true, flagged: flagged, player_info: player_info }
    end
  end
  
  def should_log_progress?(processed_count)
    progress_every > 0 && (processed_count % progress_every == 0)
  end
  
  def log_progress(player, stats)
    return unless @progress_logger
    
    timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    message = "[#{timestamp}] Progress: #{stats[:processed]} processed, " \
              "player_id=#{player.id}, " \
              "unavailable=#{stats[:unavailable]}, " \
              "flagged=#{stats[:flagged]}, " \
              "errors=#{stats[:errors]}"
    
    @progress_logger.call(message)
  end
end
