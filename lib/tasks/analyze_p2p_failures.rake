namespace :players do
  desc "Analyze and report on P2P check failures to show where players are failing checks"
  task analyze_p2p_failures: :environment do
    puts "=" * 100
    puts "P2P CHECK FAILURE ANALYSIS"
    puts "=" * 100
    puts ""
    puts "This task analyzes all players in the database to show where they are failing P2P checks."
    puts ""

    # Group players by their P2P check results
    total_players = Player.count
    f2p_players = Player.where("potential_p2p <= 0").count
    p2p_players = Player.where("potential_p2p > 0").count

    puts "=" * 100
    puts "OVERALL STATISTICS"
    puts "=" * 100
    puts "Total players in database: #{total_players}"
    puts "F2P players: #{f2p_players} (#{(f2p_players.to_f / total_players * 100).round(2)}%)"
    puts "P2P players: #{p2p_players} (#{(p2p_players.to_f / total_players * 100).round(2)}%)"
    puts ""

    # Analyze P2P failure reasons
    puts "=" * 100
    puts "P2P CHECK FAILURE REASONS"
    puts "=" * 100
    puts ""

    if Player.column_names.include?('p2p_check_reason')
      # Group by reason and count
      reason_counts = Player.where("potential_p2p > 0").group(:p2p_check_reason).count
      
      if reason_counts.any?
        puts "Breakdown of why players failed P2P checks:"
        puts ""
        reason_counts.sort_by { |k, v| -v }.each do |reason, count|
          reason_display = reason.nil? || reason.empty? ? "(No reason recorded - legacy data)" : reason
          percentage = (count.to_f / p2p_players * 100).round(2)
          puts "  #{count.to_s.rjust(6)} players (#{percentage.to_s.rjust(6)}%): #{reason_display}"
        end
      else
        puts "No P2P check reasons recorded. Run player updates to populate this field."
      end
    else
      puts "WARNING: p2p_check_reason column not found in database."
      puts "Run 'rake db:migrate' to add the column, then update players to populate reasons."
    end

    puts ""
    puts "=" * 100
    puts "DETAILED P2P FAILURE EXAMPLES"
    puts "=" * 100
    puts ""
    puts "Showing up to 10 examples of each failure type:"
    puts ""

    # Show examples of different failure types
    failure_categories = {
      "Parser detected P2P" => 'p2p_check_reason LIKE ?',
      "Overall level exceeds F2P max" => 'p2p_check_reason LIKE ?',
      "In fakes list" => 'p2p_check_reason LIKE ?',
      "No reason recorded" => 'potential_p2p > 0 AND (p2p_check_reason IS NULL OR p2p_check_reason = ?)'
    }

    failure_categories.each do |category, condition|
      puts "-" * 100
      puts "Category: #{category}"
      puts "-" * 100
      
      query_param = case category
      when "Parser detected P2P"
        "%Parser detected%"
      when "Overall level exceeds F2P max"
        "%Overall level%exceeds%"
      when "In fakes list"
        "%fakes list%"
      when "No reason recorded"
        ""
      end

      examples = Player.where(condition, query_param).limit(10)

      if examples.any?
        examples.each do |player|
          reason_display = player.respond_to?(:p2p_check_reason) && player.p2p_check_reason ? player.p2p_check_reason : "(no reason recorded)"
          puts "  • #{player.player_name} (#{player.player_acc_type}) - #{reason_display}"
        end
      else
        puts "  No examples found for this category."
      end
      puts ""
    end

    # Show statistics on false_p2p_flagged list
    puts "=" * 100
    puts "FALSE P2P FLAGGED LIST STATUS"
    puts "=" * 100
    puts ""
    
    false_flagged_list = F2POSRSRanks::Application.config.false_p2p_flagged
    puts "Players in false_p2p_flagged list: #{false_flagged_list.length}"
    
    if false_flagged_list.any?
      found_count = 0
      not_found_count = 0
      
      false_flagged_list.each do |player_name|
        player = Player.find_by("LOWER(player_name) = ?", player_name.downcase)
        if player
          found_count += 1
        else
          not_found_count += 1
        end
      end
      
      puts "  - Found in database: #{found_count}"
      puts "  - Not found in database: #{not_found_count}"
      puts ""
      puts "Note: Players in false_p2p_flagged are treated as F2P regardless of detection."
    end

    puts ""
    puts "=" * 100
    puts "RECOMMENDATIONS"
    puts "=" * 100
    puts ""
    puts "To investigate specific P2P check failures:"
    puts "  1. Run: rake players:check_false_p2p_flagged"
    puts "     - Validates players in the false_p2p_flagged list"
    puts ""
    puts "  2. Check the Rails logs for detailed P2P check information:"
    puts "     - Look for '[P2P CHECK]' entries in log/development.log or log/production.log"
    puts ""
    puts "  3. For a specific player, check their p2p_check_reason in the database:"
    puts "     - Player.find_by(player_name: 'PlayerName').p2p_check_reason"
    puts ""
    puts "  4. To re-run P2P checks on all players:"
    puts "     - This will update all p2p_check_reason fields with current logic"
    puts "     - Use with caution in production"
    puts ""
    puts "=" * 100
  end

  desc "Show detailed P2P check information for a specific player"
  task :analyze_player_p2p, [:player_name] => :environment do |t, args|
    if args[:player_name].nil?
      puts "Usage: rake players:analyze_player_p2p[PlayerName]"
      puts "Example: rake players:analyze_player_p2p[Zezima]"
      exit
    end

    player_name = args[:player_name]
    player = Player.find_by("LOWER(player_name) = ?", player_name.downcase)

    if player.nil?
      puts "=" * 100
      puts "Player '#{player_name}' not found in database"
      puts "=" * 100
      exit
    end

    puts "=" * 100
    puts "P2P CHECK ANALYSIS FOR: #{player.player_name}"
    puts "=" * 100
    puts ""
    puts "Account Type: #{player.player_acc_type}"
    puts "Overall Level: #{player.overall_lvl}"
    puts "Overall XP: #{player.overall_xp}"
    puts "P2P Flag: #{player.potential_p2p}"
    puts "P2P Check Reason: #{player.respond_to?(:p2p_check_reason) ? player.p2p_check_reason : '(column not available)'}"
    puts ""

    # Check which lists the player is in
    puts "=" * 100
    puts "LIST MEMBERSHIP"
    puts "=" * 100
    
    is_in_fakes = F2POSRSRanks::Application.config.downcase_fakes.include?(player_name.downcase)
    is_in_banned = F2POSRSRanks::Application.config.downcase_banned.include?(player_name.downcase)
    is_in_false_banned = F2POSRSRanks::Application.config.downcase_false_banned.include?(player_name.downcase)
    is_in_false_p2p = F2POSRSRanks::Application.config.downcase_false_p2p_flagged.include?(player_name.downcase)

    puts "In fakes list (known P2P): #{is_in_fakes ? 'YES ✓' : 'No'}"
    puts "In banned list: #{is_in_banned ? 'YES ✓' : 'No'}"
    puts "In false_banned list (incorrectly banned): #{is_in_false_banned ? 'YES ✓' : 'No'}"
    puts "In false_p2p_flagged list (manual override): #{is_in_false_p2p ? 'YES ✓' : 'No'}"
    puts ""

    # Fetch fresh stats from hiscores
    puts "=" * 100
    puts "FETCHING CURRENT STATS FROM HISCORES API"
    puts "=" * 100
    puts ""

    begin
      stats, account_type = Hiscores.fetch_stats_by_acc(player_name, player.player_acc_type)
      
      if stats
        puts "Successfully fetched stats from hiscores"
        puts ""
        puts "Parser P2P Flag: #{stats["potential_p2p"]}"
        puts "Overall Level from API: #{stats[:overall_lvl]}"
        puts "F2P Levels Sum: #{stats[:f2p_levels_sum]}"
        puts "Members Skill Count: #{stats[:members_skill_count]}"
        puts "Members Levels Sum: #{stats[:members_levels_sum]}"
        puts ""
        
        # Calculate expected F2P max
        expected_overall = stats[:f2p_levels_sum].to_i + stats[:members_skill_count].to_i
        actual_overall = stats[:overall_lvl].to_i
        
        puts "Expected F2P Max Overall: #{expected_overall} (F2P skills + base P2P)"
        puts "Actual Overall: #{actual_overall}"
        
        if actual_overall > expected_overall
          difference = actual_overall - expected_overall
          puts "⚠️  FAILED: Overall exceeds F2P max by #{difference} levels"
        else
          puts "✓ Overall level check PASSED"
        end
        puts ""

        # Show F2P skill levels
        puts "=" * 100
        puts "F2P SKILL LEVELS"
        puts "=" * 100
        Player::SKILLS.each do |skill|
          next if skill == 'overall'
          lvl = stats["#{skill}_lvl"]
          xp = stats["#{skill}_xp"]
          if lvl && xp
            puts "  #{skill.capitalize.ljust(15)}: Level #{lvl.to_s.rjust(3)} (#{xp.to_s.rjust(10)} xp)"
          end
        end
      else
        puts "⚠️  Could not fetch stats from hiscores (player may not be ranked)"
      end
    rescue SocketError, Net::ReadTimeout => e
      puts "⚠️  Network error fetching hiscores: #{e.message}"
    rescue => e
      puts "⚠️  Error fetching hiscores: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end

    puts ""
    puts "=" * 100
    puts "FINAL STATUS"
    puts "=" * 100
    if player.is_f2p?
      puts "✓ This player is treated as F2P"
    else
      puts "⚠️  This player is flagged as P2P"
    end
    puts ""
  end
end
