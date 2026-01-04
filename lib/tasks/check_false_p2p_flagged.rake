namespace :players do
  desc "Check false_p2p_flagged list for players with total level exceeding F2P maximum (1494)"
  task check_false_p2p_flagged: :environment do
    # Maximum F2P total level: 15 skills × 99 = 1485
    # With 9 P2P skills at base level 1 = 1494
    # Any total level > 1494 means P2P skills have been trained beyond base
    F2P_MAX_TOTAL = 1494

    puts "=" * 80
    puts "Checking false_p2p_flagged list for players with total level > #{F2P_MAX_TOTAL}"
    puts "=" * 80
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
      
      if total_level > F2P_MAX_TOTAL
        players_to_remove << { name: player_name, total_level: total_level }
        puts "❌ REMOVE: #{player_name} - Total Level: #{total_level} (exceeds F2P max of #{F2P_MAX_TOTAL})"
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
        puts "  - #{player[:name]} (Total Level: #{player[:total_level]})"
      end
      puts ""
      puts "These players have trained P2P skills beyond base level and should not"
      puts "be in the false_p2p_flagged list. Please remove them from"
      puts "config/initializers/assets.rb"
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
      puts "These players may have been removed or renamed."
    end

    puts ""
    puts "=" * 80
  end
end
