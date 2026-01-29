# Rake task to check all players for P2P clue scroll completions
#
# Purpose:
#   Scans all players in the database and identifies those who have completed
#   P2P clue scrolls (easy, medium, hard, elite, or master clues).
#   Only beginner clues and "clue scrolls (all)" are F2P content.
#
# Usage:
#   bundle exec rake players:check_all_clue_scrolls
#
# What it does:
#   1. Fetches all players from the database
#   2. For each player, checks hiscores for P2P clue scroll completions
#   3. Reports which players have P2P clue scrolls (easy/medium/hard/elite/master)
#   4. Provides recommendations for removal
#
# Output:
#   - Players with P2P clue scroll completions (should be removed from database)
#   - Players not found in hiscores (may need cleanup)
#   - Summary with actionable recommendations

namespace :players do
  desc "Check all players for P2P clue scroll completions (excluding beginner and all)"
  task check_all_clue_scrolls: :environment do
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
        'Araxxor', 'Artio', 'Barrows Chests', 'Bryophyta', 'Brutus', 'Callisto', "Calvar'ion", 'Cerberus',
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
    puts "Checking all players for P2P clue scroll completions"
    puts "=" * 80
    puts ""
    puts "NOTE: This check looks for P2P clue scroll completions across all players."
    puts "Beginner clues and 'clue scrolls (all)' are excluded as they are F2P content."
    puts ""
    
    total_players = Player.count
    puts "Total players in database: #{total_players}"
    puts ""
    puts "Starting scan... (this may take a while)"
    puts ""

    players_to_remove = []
    players_checked = 0
    players_not_found = []
    errors = []

    Player.find_each do |player|
      players_checked += 1
      
      # Progress indicator every 100 players
      if players_checked % 100 == 0
        puts "Progress: #{players_checked}/#{total_players} players checked, #{players_to_remove.length} flagged..."
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
          # Player has P2P clue scroll completions
          clue_list = clue_counts_data.map { |clue_type, count| "#{clue_type}: #{count}" }.join(", ")
          
          players_to_remove << {
            name: player.player_name,
            acc_type: player.player_acc_type,
            clue_counts: clue_counts_data,
            clue_list: clue_list,
            reason: "Has P2P clue scroll completions (#{clue_list})"
          }
          
          puts "❌ REMOVE: #{player.player_name} (#{player.player_acc_type}) - P2P clues: #{clue_list}"
        end
      rescue SocketError, Net::ReadTimeout => e
        errors << { player: player.player_name, error: "Network timeout: #{e.message}" }
      rescue OpenURI::HTTPError => e
        # HTTP errors might indicate player doesn't exist anymore or is banned
        players_not_found << player.player_name
      rescue => e
        errors << { player: player.player_name, error: "#{e.class}: #{e.message}" }
      end
    end

    puts ""
    puts "=" * 80
    puts "Summary:"
    puts "=" * 80
    puts "Players checked: #{players_checked}"
    puts "Players not found in hiscores: #{players_not_found.length}"
    puts "Players to remove from database: #{players_to_remove.length}"
    puts ""

    if players_to_remove.any?
      puts "⚠️  The following players should be REMOVED from the database:"
      puts ""
      players_to_remove.each do |player|
        puts "  - #{player[:name]} (#{player[:acc_type]}): #{player[:reason]}"
      end
      puts ""
      puts "These players have P2P clue scroll completions and should not be in the database."
      puts "They have trained members-only content and should be considered P2P players."
      puts ""
      puts "To remove them manually, you can use the Rails console:"
      puts "  Player.where(player_name: ['player1', 'player2', 'player3']).destroy_all"
      puts ""
      puts "Replace the player names with the actual names from the list above."
      puts "Or create a custom rake task to handle batch deletion safely."
    else
      puts "✅ No players found with P2P clue scroll completions!"
    end

    if players_not_found.any?
      puts ""
      puts "ℹ️  Players not found in hiscores (#{players_not_found.length}):"
      players_not_found.take(10).each do |player_name|
        puts "  - #{player_name}"
      end
      if players_not_found.length > 10
        puts "  ... and #{players_not_found.length - 10} more"
      end
      puts ""
      puts "These players may have been removed, renamed, or banned. Consider removing them from the database."
    end

    if errors.any?
      puts ""
      puts "⚠️  Errors encountered (#{errors.length}):"
      puts ""
      errors.take(10).each do |error|
        puts "  - #{error[:player]}: #{error[:error]}"
      end
      if errors.length > 10
        puts "  ... and #{errors.length - 10} more errors"
      end
      puts ""
    end

    puts ""
    puts "=" * 80
  end
end
