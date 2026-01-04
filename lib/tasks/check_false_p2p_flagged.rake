namespace :players do
  desc "Check false_p2p_flagged list for players who fail P2P skill checks"
  task check_false_p2p_flagged: :environment do
    # Maximum F2P total level: 15 skills × 99 = 1485
    # With 9 P2P skills at base level 1 = 1494
    # Any total level > 1494 means P2P skills have been trained beyond base
    F2P_MAX_TOTAL = 1494
    
    # P2P skills that should all be at level 1 for true F2P players
    # These correspond to the 9 members-only skills in OSRS
    P2P_SKILLS = ['fletching', 'herblore', 'agility', 'thieving', 'slayer', 'farming', 'hunter', 'construction', 'sailing']

    puts "=" * 80
    puts "Checking false_p2p_flagged list for players who fail P2P skill checks"
    puts "=" * 80
    puts ""
    puts "NOTE: We ignore P2P minigame scores and boss kill counts, as those may have false positives."
    puts "We only check if players have actually trained P2P skills (Fletching, Herblore, etc.)"
    puts ""

    false_flagged_list = F2POSRSRanks::Application.config.false_p2p_flagged
    puts "Total players in false_p2p_flagged list: #{false_flagged_list.length}"
    puts ""

    players_to_remove = []
    players_not_found = []
    players_checked = 0

    false_flagged_list.each do |player_name|
      player = Player.find_by("LOWER(player_name) = ?", player_name.downcase)
      
      if player.nil?
        players_not_found << player_name
        next
      end
      
      players_checked += 1
      total_level = player.overall_lvl || 0
      
      # Check 1: Total level exceeds F2P maximum
      if total_level > F2P_MAX_TOTAL
        players_to_remove << { 
          name: player_name, 
          total_level: total_level,
          reason: "Total level #{total_level} exceeds F2P max (#{F2P_MAX_TOTAL})"
        }
        puts "❌ REMOVE: #{player_name} - Total Level: #{total_level} (exceeds F2P max of #{F2P_MAX_TOTAL})"
        next
      end
      
      # Check 2: Fetch current stats from hiscores to check P2P skills
      # We need to check the actual hiscores data, not just database values
      # since database might not have P2P skill data stored
      begin
        stats, account_type = Hiscores.fetch_stats_by_acc(player_name, player.player_acc_type)
        
        if stats
          # Check if any P2P skill is trained beyond base level
          # The parser sets potential_p2p based on skill checks, but we want to be more specific
          # and ignore minigame/boss flags
          
          # The deterministic check from Player model:
          # overall > (f2p_levels_sum + members_skill_count) means P2P skills trained
          overall = stats[:overall_lvl].to_i
          f2p_sum = stats[:f2p_levels_sum].to_i
          members_count = stats[:members_skill_count].to_i
          
          if overall > 0 && members_count > 0
            expected_overall = f2p_sum + members_count
            if overall > expected_overall
              trained_p2p_levels = overall - expected_overall
              players_to_remove << {
                name: player_name,
                total_level: overall,
                reason: "Has trained P2P skills (#{trained_p2p_levels} levels beyond base)"
              }
              puts "❌ REMOVE: #{player_name} - Has trained P2P skills (Total: #{overall}, Expected F2P max: #{expected_overall})"
            end
          end
        end
      rescue SocketError, Net::ReadTimeout => e
        puts "⚠️  WARNING: Could not fetch hiscores for #{player_name}: #{e.message}"
      rescue => e
        puts "⚠️  WARNING: Error checking #{player_name}: #{e.message}"
      end
    end

    puts ""
    puts "=" * 80
    puts "Summary:"
    puts "=" * 80
    puts "Players checked: #{players_checked}"
    puts "Players not found in database: #{players_not_found.length}"
    puts "Players to remove from false_p2p_flagged: #{players_to_remove.length}"
    puts ""

    if players_to_remove.any?
      puts "⚠️  The following players should be REMOVED from false_p2p_flagged:"
      puts ""
      players_to_remove.each do |player|
        puts "  - #{player[:name]}: #{player[:reason]}"
      end
      puts ""
      puts "These players have trained P2P skills and should not be in the"
      puts "false_p2p_flagged list. Please remove them from config/initializers/assets.rb"
      puts ""
      puts "To remove them, edit line 20 in config/initializers/assets.rb and delete these names."
    else
      puts "✅ No players found that need to be removed!"
    end

    if players_not_found.any?
      puts ""
      puts "ℹ️  Players not found in database (#{players_not_found.length}):"
      players_not_found.each do |player_name|
        puts "  - #{player_name}"
      end
      puts ""
      puts "These players may have been removed or renamed. Consider removing them from the list."
    end

    puts ""
    puts "=" * 80
  end
end
