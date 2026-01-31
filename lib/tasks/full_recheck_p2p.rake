namespace :players do
  desc "Full P2P recheck for all players by fetching fresh hiscores data"
  task full_recheck_p2p: :environment do
    # Environment variables for control
    sleep_time = ENV['SLEEP']&.to_f || 0.2
    start_id = ENV['START_ID']&.to_i
    limit = ENV['LIMIT']&.to_i

    # Build the base scope
    scope = Player.all
    scope = scope.where('id >= ?', start_id) if start_id
    scope = scope.limit(limit) if limit

    total = scope.count
    processed_count = 0
    updated_count = 0
    failed_count = 0
    skipped_count = 0

    puts "=" * 80
    puts "Full P2P Recheck - Fetching Fresh Hiscores Data"
    puts "=" * 80
    puts "Total players to process: #{total}"
    puts "Sleep time between players: #{sleep_time}s"
    puts "Start ID: #{start_id || 'beginning'}"
    puts "Limit: #{limit || 'none'}"
    puts "=" * 80
    puts ""

    start_time = Time.now

    scope.find_each do |player|
      processed_count += 1
      
      begin
        # Fetch fresh hiscores data
        stats = Hiscores.fetch_stats_by_acc(player.player_name, player.player_acc_type)
        
        if stats
          old_value = player.potential_p2p
          old_updated_at = player.updated_at
          
          # Call the p2p check method with fresh stats
          # This will update the potential_p2p field and save the record
          player.check_p2p_stats(stats)
          
          # Check if potential_p2p actually changed
          if old_value != player.potential_p2p
            # Value changed - restore the original updated_at to avoid triggering timestamp changes
            player.update_column(:updated_at, old_updated_at) if old_updated_at
            updated_count += 1
            puts "[#{processed_count}/#{total}] ✓ Updated #{player.player_name} (ID: #{player.id}): #{old_value} -> #{player.potential_p2p}"
          else
            # Value didn't change - restore updated_at since check_p2p_stats touched it
            player.update_column(:updated_at, old_updated_at) if old_updated_at && player.updated_at != old_updated_at
            if processed_count % 50 == 0
              puts "[#{processed_count}/#{total}] No change for #{player.player_name} (ID: #{player.id})"
            end
          end
        else
          skipped_count += 1
          if processed_count % 50 == 0
            puts "[#{processed_count}/#{total}] ⊗ Skipped #{player.player_name} (ID: #{player.id}) - No hiscores data"
          end
        end
      rescue SocketError, Net::ReadTimeout => e
        failed_count += 1
        puts "[#{processed_count}/#{total}] ✗ Network error for #{player.player_name} (ID: #{player.id}): #{e.class.name}"
      rescue => e
        failed_count += 1
        puts "[#{processed_count}/#{total}] ✗ Error for #{player.player_name} (ID: #{player.id}): #{e.message}"
      end
      
      # Throttle requests to avoid hammering the hiscores API
      sleep sleep_time if processed_count < total
    end

    elapsed_time = Time.now - start_time
    
    puts ""
    puts "=" * 80
    puts "Summary"
    puts "=" * 80
    puts "Total processed: #{processed_count}"
    puts "Updated (potential_p2p changed): #{updated_count}"
    puts "Skipped (no hiscores data): #{skipped_count}"
    puts "Failed (network/other errors): #{failed_count}"
    puts "Elapsed time: #{elapsed_time.round(2)}s"
    puts "=" * 80
  end
end
