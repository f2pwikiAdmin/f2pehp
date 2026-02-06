# Service for cleaning up players with unavailable hiscores data
class PlayerCleanupService
  attr_reader :limit, :sleep_time, :start_id, :dry_run
  
  def initialize(limit: 100, sleep_time: 0.3, start_id: nil, dry_run: false)
    @limit = limit
    @sleep_time = sleep_time
    @start_id = start_id
    @dry_run = dry_run
  end
  
  def execute
    stats = {
      processed: 0,
      unavailable: 0,
      deleted: 0,
      errors: 0,
      unavailable_players: []
    }
    
    query = build_query
    
    query.find_each(batch_size: 100) do |player|
      stats[:processed] += 1
      
      begin
        result = check_and_cleanup_player(player)
        
        if result[:unavailable]
          stats[:unavailable] += 1
          stats[:unavailable_players] << result[:player_info]
          
          if result[:deleted]
            stats[:deleted] += 1
          end
        end
        
      rescue => e
        stats[:errors] += 1
        Rails.logger.error "Error checking player #{player.player_name}: #{e.message}"
      end
      
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
      { unavailable: false, deleted: false }
    else
      # Player is unavailable
      player_info = {
        id: player.id,
        name: player.player_name,
        total: player.overall_lvl,
        updated: player.updated_at
      }
      
      deleted = false
      unless dry_run
        player.destroy
        deleted = true
      end
      
      { unavailable: true, deleted: deleted, player_info: player_info }
    end
  end
end
