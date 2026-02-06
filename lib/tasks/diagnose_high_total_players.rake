namespace :players do
  desc "Diagnose players with total level > F2P max (1494)"
  task diagnose_high_total: :environment do
    puts "=" * 80
    puts "Diagnosing Players with Total Level > F2P Maximum (1494)"
    puts "=" * 80
    puts ""

    # Find all players with high total level
    high_total_players = Player.where("overall_lvl > ?", Player::F2P_MAX_TOTAL).order(overall_lvl: :desc)
    
    total_count = high_total_players.count
    puts "Total players with overall_lvl > 1494: #{total_count}"
    puts ""

    if total_count == 0
      puts "✓ No players found with total level exceeding F2P maximum!"
      puts "=" * 80
      return
    end

    # Breakdown by potential_p2p status
    flagged_count = high_total_players.where(potential_p2p: 1).count
    not_flagged_count = high_total_players.where("potential_p2p != 1 OR potential_p2p IS NULL").count

    puts "Breakdown:"
    puts "  - Already flagged as P2P (potential_p2p = 1): #{flagged_count}"
    puts "  - NOT flagged as P2P (potential_p2p = 0 or NULL): #{not_flagged_count}"
    puts ""

    if not_flagged_count > 0
      puts "⚠️  WARNING: #{not_flagged_count} players have high total levels but are NOT flagged as P2P!"
      puts ""
      puts "Sample of unflagged players (top 10 by total level):"
      puts ""
      
      unflagged = high_total_players.where("potential_p2p != 1 OR potential_p2p IS NULL").limit(10)
      unflagged.each do |player|
        puts "  - #{player.player_name} (ID: #{player.id})"
        puts "    Total Level: #{player.overall_lvl}"
        puts "    Potential P2P: #{player.potential_p2p || 'NULL'}"
        puts "    Last Updated: #{player.updated_at}"
        puts ""
      end
    end

    # Check hiscores availability for a sample
    puts "-" * 80
    puts "Checking Hiscores Availability (sample of 5)..."
    puts ""
    
    sample = high_total_players.limit(5)
    available_count = 0
    unavailable_count = 0

    sample.each do |player|
      begin
        stats = Hiscores.fetch_stats_by_acc(player.player_name, player.player_acc_type)
        if stats
          available_count += 1
          current_total = stats[:overall_lvl] || stats["overall_lvl"]
          puts "  ✓ #{player.player_name}: Hiscores available (current total: #{current_total})"
        else
          unavailable_count += 1
          puts "  ✗ #{player.player_name}: Hiscores unavailable (404 or deleted)"
        end
      rescue => e
        unavailable_count += 1
        puts "  ✗ #{player.player_name}: Error fetching hiscores (#{e.message})"
      end
      sleep 0.5  # Rate limit
    end

    puts ""
    puts "Sample Results:"
    puts "  - Available: #{available_count}/5"
    puts "  - Unavailable: #{unavailable_count}/5"
    puts ""

    # Recommendations
    puts "=" * 80
    puts "Recommendations:"
    puts "=" * 80
    puts ""
    
    if not_flagged_count > 0
      puts "1. Fix Unflagged Players:"
      puts "   Run: rake players:fix_high_total_unflagged"
      puts "   This will set potential_p2p = 1 for all players with total > 1494"
      puts ""
    end

    puts "2. Clean Up Unavailable Players (optional):"
    puts "   Preview first: DRY_RUN=1 rake players:cleanup_unavailable"
    puts "   Then run: rake players:cleanup_unavailable"
    puts "   This will remove players whose hiscores data is no longer available"
    puts "   Options: LIMIT=500 SLEEP=0.5 DRY_RUN=1"
    puts ""

    puts "3. Re-run Full P2P Recheck:"
    puts "   Run: rake players:full_recheck_p2p"
    puts "   This will fetch fresh data and update all players"
    puts ""
    puts "=" * 80
  end

  desc "Fix players with high total level that aren't flagged as P2P"
  task fix_high_total_unflagged: :environment do
    puts "=" * 80
    puts "Fixing Unflagged Players with Total Level > 1494"
    puts "=" * 80
    puts ""

    unflagged = Player.where("overall_lvl > ?", Player::F2P_MAX_TOTAL)
                     .where("potential_p2p != 1 OR potential_p2p IS NULL")

    count = unflagged.count
    
    if count == 0
      puts "✓ No unflagged players found!"
      puts "=" * 80
      return
    end

    puts "Found #{count} players to fix."
    puts ""
    
    print "Do you want to proceed? (yes/no): "
    response = STDIN.gets.chomp.downcase
    
    unless response == 'yes' || response == 'y'
      puts "Aborted."
      return
    end
    
    puts ""
    puts "Updating players..."
    
    updated = 0
    unflagged.find_each do |player|
      player.update_column(:potential_p2p, 1)
      updated += 1
      puts "  ✓ Updated #{player.player_name} (total: #{player.overall_lvl})" if updated % 100 == 0 || updated <= 10
    end
    
    puts ""
    puts "✓ Fixed #{updated} players"
    puts "=" * 80
  end

  desc "List players whose hiscores data is unavailable (for cleanup consideration)"
  task list_unavailable: :environment do
    puts "=" * 80
    puts "Finding Players with Unavailable Hiscores Data"
    puts "=" * 80
    puts ""
    
    limit = ENV['LIMIT']&.to_i || 50
    sleep_time = ENV['SLEEP']&.to_f || 0.3
    
    puts "Checking players (limit: #{limit})..."
    puts "This may take a while..."
    puts ""
    
    unavailable = []
    
    Player.limit(limit).find_each do |player|
      begin
        stats = Hiscores.fetch_stats_by_acc(player.player_name, player.player_acc_type)
        if !stats
          unavailable << {
            name: player.player_name,
            id: player.id,
            total: player.overall_lvl,
            updated: player.updated_at
          }
        end
      rescue => e
        unavailable << {
          name: player.player_name,
          id: player.id,
          total: player.overall_lvl,
          updated: player.updated_at,
          error: e.message
        }
      end
      sleep sleep_time
    end
    
    puts ""
    puts "=" * 80
    puts "Results:"
    puts "=" * 80
    puts "Players with unavailable hiscores: #{unavailable.count}/#{limit} checked"
    puts ""
    
    if unavailable.any?
      puts "Sample (first 10):"
      unavailable.first(10).each do |p|
        puts "  - #{p[:name]} (ID: #{p[:id]}, Total: #{p[:total]}, Last: #{p[:updated]})"
        puts "    Error: #{p[:error]}" if p[:error]
      end
    end
    
    puts ""
    puts "To check more players, run: LIMIT=100 rake players:list_unavailable"
    puts "=" * 80
  end

  desc "Clean up players whose hiscores data is unavailable (safe with confirmation)"
  task cleanup_unavailable: :environment do
    puts "=" * 80
    puts "Cleanup Players with Unavailable Hiscores Data"
    puts "=" * 80
    puts ""
    
    # Parse environment variables
    limit = ENV['LIMIT']&.to_i || 100
    sleep_time = ENV['SLEEP']&.to_f || 0.3
    start_id = ENV['START_ID']&.to_i
    dry_run = ENV['DRY_RUN'] == '1'
    
    puts "Configuration:"
    puts "  - Limit: #{limit} players"
    puts "  - Sleep between API calls: #{sleep_time}s"
    puts "  - Start ID: #{start_id || 'beginning'}"
    puts "  - Mode: #{dry_run ? 'DRY RUN (no deletions)' : 'LIVE (will delete)'}"
    puts ""
    
    if dry_run
      puts "ℹ️  DRY RUN MODE: No players will be deleted. This is a preview."
      puts ""
    else
      puts "⚠️  WARNING: This will permanently delete players from the database!"
      puts ""
      print "Are you sure you want to proceed? Type 'yes' to confirm: "
      response = STDIN.gets.chomp
      
      unless response == 'yes'
        puts "Aborted. No changes made."
        puts "=" * 80
        return
      end
      puts ""
    end
    
    puts "Checking players for unavailable hiscores data..."
    puts "This may take a while..."
    puts ""
    
    # Use service to perform cleanup
    service = PlayerCleanupService.new(
      limit: limit,
      sleep_time: sleep_time,
      start_id: start_id,
      dry_run: dry_run
    )
    
    # Run the service
    results = service.execute
    
    # Summary
    puts ""
    puts "=" * 80
    puts "Summary:"
    puts "=" * 80
    puts "  - Total processed: #{results[:processed]}"
    puts "  - Unavailable players found: #{results[:unavailable]}"
    if dry_run
      puts "  - Would be deleted: #{results[:unavailable]}"
      puts "  - Actually deleted: 0 (DRY RUN)"
    else
      puts "  - Successfully deleted: #{results[:deleted]}"
    end
    puts "  - Errors: #{results[:errors]}"
    puts ""
    
    if dry_run && results[:unavailable] > 0
      puts "To actually delete these players, run without DRY_RUN:"
      puts "  rake players:cleanup_unavailable"
      puts ""
    end
    
    if results[:unavailable] > 0 && results[:unavailable] < 20
      puts "Unavailable players:"
      results[:unavailable_players].each do |p|
        puts "  - #{p[:name]} (ID: #{p[:id]}, Total: #{p[:total]})"
      end
      puts ""
    end
    
    puts "To check more players, adjust LIMIT:"
    puts "  LIMIT=500 rake players:cleanup_unavailable"
    puts ""
    puts "To resume from a specific ID:"
    puts "  START_ID=1000 rake players:cleanup_unavailable"
    puts ""
    puts "=" * 80
  end
end
