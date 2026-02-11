# Service for enforcing P2P rules and cleaning up players
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
      flagged_total_level: 0,
      flagged_verified: 0,
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
        result = check_and_enforce_player(player)
        
        if result[:flagged_total_level]
          stats[:flagged_total_level] += 1
        end
        
        if result[:flagged_verified]
          stats[:flagged_verified] += 1
        end
        
        # Track errors that occurred during hiscores fetch
        # But don't count them as something to act on
        if result[:fetch_error]
          stats[:errors] += 1
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
  
  def check_and_enforce_player(player)
    result = {
      flagged_total_level: false,
      flagged_verified: false,
      fetch_error: false
    }
    
    # PRIORITY 1: Check if player's stored total level exceeds F2P max
    # This is the primary enforcement mechanism and works even if hiscores are down
    if player.overall_lvl > Player::F2P_MAX_TOTAL
      unless dry_run
        # Only update if not already flagged with the correct reason
        unless already_flagged_as?(player, Player::P2P_FLAG_REASONS[:total_level_exceeds_f2p_max])
          player.update_columns(
            potential_p2p: 1,
            p2p_flag_reason: Player::P2P_FLAG_REASONS[:total_level_exceeds_f2p_max]
          )
          Rails.logger.info "Player #{player.player_name} (ID: #{player.id}) flagged: total level #{player.overall_lvl} exceeds F2P max (#{Player::F2P_MAX_TOTAL})"
        end
      end
      result[:flagged_total_level] = true
      return result
    end
    
    # PRIORITY 2: If hiscores fetch succeeds, use detailed P2P verification
    begin
      stats = Hiscores.fetch_stats_by_acc(player.player_name, player.player_acc_type)
      
      if stats
        # Hiscores data is available - verify if player is P2P
        is_p2p = player.detailed_p2p_verification(stats)
        
        unless dry_run
          if is_p2p
            # Only update if not already flagged as P2P
            unless already_flagged_as?(player, Player::P2P_FLAG_REASONS[:p2p])
              player.update_columns(
                potential_p2p: 1,
                p2p_flag_reason: Player::P2P_FLAG_REASONS[:p2p]
              )
              Rails.logger.info "Player #{player.player_name} (ID: #{player.id}) flagged: verified P2P via detailed verification"
            end
            result[:flagged_verified] = true
          else
            # Player is verified F2P - unflag if previously flagged
            if player.potential_p2p == 1
              player.update_columns(
                potential_p2p: 0,
                p2p_flag_reason: nil
              )
              Rails.logger.info "Player #{player.player_name} (ID: #{player.id}) unflagged: verified as F2P"
            end
          end
        else
          # In dry run mode, just report what would happen
          if is_p2p
            result[:flagged_verified] = true
          end
        end
      else
        # Hiscores fetch returned nil (player not found)
        # DO NOT flag based on this - it may be a transient error
        # Just log it for awareness
        Rails.logger.debug "Player #{player.player_name} (ID: #{player.id}): hiscores returned nil (not flagging)"
      end
    rescue => e
      # Hiscores fetch failed with an error
      # DO NOT flag based on this - treat as unknown/retry later
      result[:fetch_error] = true
      Rails.logger.debug "Player #{player.player_name} (ID: #{player.id}): hiscores fetch error (#{e.message})"
    end
    
    result
  end
  
  # Helper method to check if a player is already flagged with a specific reason
  def already_flagged_as?(player, reason)
    player.potential_p2p == 1 && player.p2p_flag_reason == reason
  end
  
  def should_log_progress?(processed_count)
    progress_every > 0 && (processed_count % progress_every == 0)
  end
  
  def log_progress(player, stats)
    return unless @progress_logger
    
    timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    message = "[#{timestamp}] Progress: #{stats[:processed]} processed, " \
              "player_id=#{player.id}, " \
              "flagged_total_level=#{stats[:flagged_total_level]}, " \
              "flagged_verified=#{stats[:flagged_verified]}, " \
              "errors=#{stats[:errors]}"
    
    @progress_logger.call(message)
  end
end
