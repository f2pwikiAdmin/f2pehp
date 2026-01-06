# Rake task to remove players with P2P clue scroll completions from the database
#
# Purpose:
#   Scans all players in the database and removes those who have completed
#   P2P clue scrolls (easy, medium, hard, elite, or master clues).
#   Only beginner clues and "clue scrolls (all)" are allowed (F2P content).
#
# Usage:
#   bundle exec rake players:remove_p2p_clue_players
#
# What it does:
#   1. Fetches all players from the database
#   2. For each player, checks hiscores for P2P clue scroll completions
#   3. Removes players who have any P2P clue scrolls (easy/medium/hard/elite/master)
#   4. Keeps players with only beginner clues and/or "all" clues
#   5. Reports statistics on removed players
#
# Output:
#   - List of players removed due to P2P clue scrolls
#   - Summary statistics
#
# WARNING:
#   This task PERMANENTLY REMOVES players from the database.
#   Use with extreme caution, especially on production databases.

namespace :players do
  desc "Remove players with P2P clue scroll completions (keeps only beginner and all)"
  task remove_p2p_clue_players: :environment do
    # P2P clue scroll types from OSRS hiscores API
    # Beginner clues and "all" clues are F2P and should NOT trigger removal
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
        'Grid Points', 'League Points', 'Deadman Points',
        'Bounty Hunter - Hunter', 'Bounty Hunter - Rogue', 'Bounty Hunter (Legacy) - Hunter',
        'Bounty Hunter (Legacy) - Rogue', 'Clue Scrolls (all)', 'Clue Scrolls (beginner)',
        'Clue Scrolls (easy)', 'Clue Scrolls (medium)', 'Clue Scrolls (hard)', 'Clue Scrolls (elite)',
        'Clue Scrolls (master)', 'LMS - Rank', 'PvP Arena - Rank', 'Soul Wars Zeal', 'Rifts closed',
        'Colosseum Glory', 'Collections Logged', 'Abyssal Sire', 'Alchemical Hydra', 'Amoxliatl',
        'Araxxor', 'Artio', 'Barrows Chests', 'Bryophyta', 'Callisto', "Calvar'ion", 'Cerberus',
        'Chambers of Xeric', 'Chambers of Xeric: Challenge Mode', 'Chaos Elemental', 'Chaos Fanatic',
        'Commander Zilyana', 'Corporeal Beast', 'Crazy Archaeologist', 'Dagannoth Prime', 'Dagannoth Rex',
        'Dagannoth Supreme', 'Deranged Archaeologist', 'Doom of Mokhaiotl', 'Duke Sucellus',
        'General Graardor', 'Giant Mole', 'Grotesque Guardians', 'Hespori', 'Kalphite Queen',
        'King Black Dragon', 'Kraken', "Kree'Arra", "K'ril Tsutsaroth", 'Lunar Chests', 'Mimic',
        'Nex', 'Nightmare', "Phosani's Nightmare", 'Obor', 'Phantom Muspah', 'Sarachnis', 'Scorpia',
        'Scurrius', 'Shellbane Gryphon', 'Skotizo', 'Sol Heredit', 'Spindel', 'Tempoross',
        'The Gauntlet', 'The Corrupted Gauntlet', 'The Hueycoatl', 'The Leviathan', 'The Royal Titans',
        'The Whisperer', 'Theatre of Blood', 'Theatre of Blood: Hard Mode', 'Thermy',
        'Tombs of Amascut', 'Tombs of Amascut: Expert Mode', 'TzKal-Zuk', 'TzTok-Jad', 'Vardorvis',
        'Venenatis', "Vet'ion", 'Vorkath', 'Wintertodt', 'Yama', 'Zalcano', 'Zulrah'
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
    puts "REMOVING PLAYERS WITH P2P CLUE SCROLL COMPLETIONS"
    puts "=" * 80
    puts ""
    puts "⚠️  WARNING: This task will PERMANENTLY DELETE players from the database!"
    puts ""
    puts "This task removes players who have completed any P2P clue scrolls:"
    puts "  - Clue Scrolls (easy)"
    puts "  - Clue Scrolls (medium)"
    puts "  - Clue Scrolls (hard)"
    puts "  - Clue Scrolls (elite)"
    puts "  - Clue Scrolls (master)"
    puts ""
    puts "Players with only beginner clues and/or 'all' clues will NOT be removed."
    puts ""
    
    total_players = Player.count
    puts "Total players in database: #{total_players}"
    puts ""
    puts "Starting scan... (this may take a while)"
    puts ""

    players_removed = []
    players_checked = 0
    players_skipped = 0
    errors = []

    Player.find_each do |player|
      players_checked += 1
      
      # Progress indicator every 100 players
      if players_checked % 100 == 0
        puts "Progress: #{players_checked}/#{total_players} players checked, #{players_removed.length} removed..."
      end
      
      begin
        # Build the API URL using the same logic as Hiscores service
        path_suffix = {
          'HCIM' => '_hardcore_ironman',
          'UIM' => '_ultimate',
          'IM' => '_ironman'
        }
        
        stats_uri = URI.join(
          'https://secure.runescape.com',
          "m=hiscore_oldschool#{path_suffix[player.player_acc_type]}/index_lite.ws",
          "?player=#{player.url_friendly_player_name}"
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
          # Player has P2P clue scroll completions - remove them
          clue_list = clue_counts_data.map { |clue_type, count| "#{clue_type}: #{count}" }.join(", ")
          
          # Store player info before destroying the record
          player_name = player.player_name
          player_acc_type = player.player_acc_type
          
          # Delete the player from the database
          player.destroy
          
          players_removed << {
            name: player_name,
            acc_type: player_acc_type,
            clue_counts: clue_counts_data,
            clue_list: clue_list
          }
          
          puts "❌ REMOVED: #{player_name} (#{player_acc_type}) - P2P clues: #{clue_list}"
        end
      rescue SocketError, Net::ReadTimeout => e
        players_skipped += 1
        errors << { player: player.player_name, error: "Network timeout: #{e.message}" }
      rescue OpenURI::HTTPError => e
        # HTTP errors might indicate player doesn't exist anymore or is banned
        # We can skip these players
        players_skipped += 1
      rescue => e
        players_skipped += 1
        errors << { player: player.player_name, error: "#{e.class}: #{e.message}" }
      end
    end

    puts ""
    puts "=" * 80
    puts "FINAL SUMMARY"
    puts "=" * 80
    puts "Total players checked: #{players_checked}"
    puts "Players removed: #{players_removed.length}"
    puts "Players skipped (errors): #{players_skipped}"
    puts "Remaining players: #{Player.count}"
    puts ""

    if players_removed.any?
      puts "Removed players:"
      puts ""
      players_removed.each do |player|
        puts "  - #{player[:name]} (#{player[:acc_type]}): #{player[:clue_list]}"
      end
      puts ""
    else
      puts "✅ No players were removed (no P2P clue scrolls found)!"
      puts ""
    end

    if errors.any?
      puts "Errors encountered (#{errors.length}):"
      puts ""
      errors.take(10).each do |error|
        puts "  - #{error[:player]}: #{error[:error]}"
      end
      if errors.length > 10
        puts "  ... and #{errors.length - 10} more errors"
      end
      puts ""
    end

    puts "=" * 80
    puts "Task completed!"
    puts "=" * 80
  end
end
