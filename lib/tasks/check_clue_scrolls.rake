# Rake task to scan the false_p2p_flagged list for players with P2P clue scrolls
#
# Purpose:
#   The false_p2p_flagged list in config/initializers/assets.rb contains players
#   who were incorrectly flagged as P2P (members) by the detection system.
#   This task helps identify players who actually have P2P clue scroll completions
#   (easy, medium, hard, elite, or master clues), meaning they should be removed 
#   from the false_p2p_flagged list.
#
# Usage:
#   bundle exec rake players:check_clue_scrolls
#
# What it does:
#   1. Fetches hiscores data for each player in the false_p2p_flagged list
#   2. Checks if they have completed any P2P clue scrolls (easy/medium/hard/elite/master)
#   3. Excludes beginner clues from the check (beginner clues are F2P)
#   4. Reports which players should be removed from the list
#
# Output:
#   - Players with P2P clue scroll completions (should be removed from false_p2p_flagged)
#   - Players not found in database (may need cleanup)
#   - Summary with actionable recommendations

namespace :players do
  desc "Check false_p2p_flagged list for players with P2P clue scroll completions (excluding beginner clues)"
  task check_clue_scrolls: :environment do
    # P2P clue scroll types from OSRS hiscores API
    # Beginner clues are F2P and should be excluded from this check
    P2P_CLUE_SCROLLS = [
      'Clue Scrolls (easy)',
      'Clue Scrolls (medium)',
      'Clue Scrolls (hard)',
      'Clue Scrolls (elite)',
      'Clue Scrolls (master)'
    ].freeze

    # Helper to extract clue scroll counts from hiscores API response
    # Returns a hash of {clue_type => count} or nil if no P2P clues found
    extract_clue_counts_from_csv = lambda do |csv_data, p2p_clues|
      return nil unless csv_data

      lines = csv_data.strip.split("\n")
      
      # Skills are lines 0-24, activities/bosses start at line 25
      # The order matches the SKILL_NAME_MAP in the Hiscores service
      # We need to maintain this order to correctly parse the CSV response
      csv_activity_order = [
        'Bounty Hunter - Hunter', 'Bounty Hunter - Rogue', 'Bounty Hunter (Legacy) - Hunter',
        'Bounty Hunter (Legacy) - Rogue', 'Clue Scrolls (all)', 'Clue Scrolls (beginner)',
        'Clue Scrolls (easy)', 'Clue Scrolls (medium)', 'Clue Scrolls (hard)', 'Clue Scrolls (elite)',
        'Clue Scrolls (master)', 'LMS - Rank', 'PvP Arena - Rank', 'Soul Wars Zeal', 'Rifts closed',
        'Colosseum Glory', 'Abyssal Sire', 'Alchemical Hydra', 'Artio', 'Barrows Chests',
        'Blood Moon', 'Blue Moon', 'Bryophyta', 'Callisto', "Calvar'ion", 'Cerberus',
        'Chambers of Xeric', 'Chambers of Xeric: Challenge Mode', 'Chaos Elemental', 'Chaos Fanatic',
        'Commander Zilyana', 'Corporeal Beast', 'Crazy Archaeologist', 'Dagannoth Prime', 'Dagannoth Rex',
        'Dagannoth Supreme', 'Deranged Archaeologist', 'Duke Sucellus', 'Eclipse Moon', 'General Graardor',
        'Giant Mole', 'Grotesque Guardians', 'Hespori', 'Kalphite Queen', 'King Black Dragon',
        'Kraken', "Kree'Arra", "K'ril Tsutsaroth", 'Lunar Chests', 'Mimic', 'Nex', 'Nightmare',
        "Phosani's Nightmare", 'Spindel', 'Phantom Muspah', 'Sarachnis', 'Scorpia', 'Scurrius',
        'Skotizo', 'Sol Heredit', 'Obor', 'Tempoross', 'The Gauntlet', 'The Corrupted Gauntlet',
        'The Leviathan', 'The Whisperer', 'Theatre of Blood', 'Theatre of Blood: Hard Mode',
        'Thermy', 'Tombs of Amascut', 'Tombs of Amascut: Expert Mode', 'TzKal-Zuk', 'TzTok-Jad',
        'Vardorvis', 'Venenatis', "Vet'ion", 'Vorkath', 'Wintertodt', 'Zalcano', 'Zulrah'
      ]
      
      clue_counts_found = {}
      activity_start_idx = 25  # Skills take lines 0-24
      
      csv_activity_order.each_with_index do |activity_name, idx|
        line_idx = activity_start_idx + idx
        next if line_idx >= lines.length
        
        # Only check P2P clue scrolls
        next unless p2p_clues.include?(activity_name)
        
        line = lines[line_idx]
        values = line.split(',').map(&:strip).map(&:to_i)
        next if values.length < 2
        
        rank, score = values[0], values[1]
        
        # If player has completions for this P2P clue type, record it
        if rank != -1 && score > 0
          clue_counts_found[activity_name] = score
        end
      end
      
      clue_counts_found.empty? ? nil : clue_counts_found
    end

    puts "=" * 80
    puts "Checking false_p2p_flagged list for players with P2P clue scroll completions"
    puts "=" * 80
    puts ""
    puts "NOTE: This check looks specifically for P2P clue scroll completions."
    puts "Beginner clues are excluded as they are F2P content."
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
      
      # Fetch raw hiscores data to check clue scroll counts
      # We use the existing Hiscores.fetch_stats_by_acc method but need the raw CSV
      # Since we can't access the raw CSV through the public API, we'll fetch it directly
      begin
        # Build the API URL using the same logic as Hiscores service
        path_suffix = {
          'HCIM' => '_hardcore_ironman',
          'UIM' => '_ultimate',
          'IM' => '_ironman'
        }
        
        url_friendly_name = ERB::Util.url_encode(player_name).gsub(/(%C2)*%A0/, '_')
        stats_uri = URI.join(
          'https://secure.runescape.com',
          "m=hiscore_oldschool#{path_suffix[player.player_acc_type]}/index_lite.ws",
          "?player=#{url_friendly_name}"
        )
        
        # Fetch the raw CSV data
        openuri_params = {
          open_timeout: 5,
          read_timeout: 5
        }
        
        csv_data = stats_uri.read(openuri_params)
        
        # Extract clue scroll counts from the CSV
        clue_counts_data = extract_clue_counts_from_csv.call(csv_data, P2P_CLUE_SCROLLS)
        
        if clue_counts_data && clue_counts_data.any?
          # Player has P2P clue scroll completions
          clue_list = clue_counts_data.map { |clue_type, count| "#{clue_type}: #{count}" }.join(", ")
          players_to_remove << {
            name: player_name,
            reason: "Has P2P clue scroll completions (#{clue_list})",
            clue_counts: clue_counts_data
          }
          puts "❌ REMOVE: #{player_name} - Has P2P clue scroll completions: #{clue_list}"
        end
      rescue SocketError, Net::ReadTimeout => e
        puts "⚠️  WARNING: Could not fetch hiscores for #{player_name}: #{e.message}"
      rescue OpenURI::HTTPError => e
        puts "⚠️  WARNING: HTTP error for #{player_name}: #{e.message}"
      rescue => e
        puts "⚠️  WARNING: Error checking #{player_name}: #{e.message}"
        puts "    #{e.backtrace.first}"
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
      puts "These players have P2P clue scroll completions and should not be in the"
      puts "false_p2p_flagged list. Please remove them from config/initializers/assets.rb"
      puts ""
      puts "To remove them, edit the false_p2p_flagged list in config/initializers/assets.rb and delete these names."
    else
      puts "✅ No players found with P2P clue scroll completions!"
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
