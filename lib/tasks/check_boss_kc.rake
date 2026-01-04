# Rake task to scan the false_p2p_flagged list for players with P2P boss KC
#
# Purpose:
#   The false_p2p_flagged list in config/initializers/assets.rb contains players
#   who were incorrectly flagged as P2P (members) by the detection system.
#   This task helps identify players who actually have P2P boss kill counts,
#   meaning they should be removed from the false_p2p_flagged list.
#
# Usage:
#   bundle exec rake players:check_boss_kc
#
# What it does:
#   1. Fetches hiscores data for each player in the false_p2p_flagged list
#   2. Checks if they have kill counts for any P2P bosses
#   3. Excludes F2P bosses (Obor and Bryophyta) from the check
#   4. Reports which players should be removed from the list
#
# Output:
#   - Players with P2P boss KC (should be removed from false_p2p_flagged)
#   - Players not found in database (may need cleanup)
#   - Summary with actionable recommendations

namespace :players do
  desc "Check false_p2p_flagged list for players with P2P boss KC (excluding Obor and Bryophyta)"
  task check_boss_kc: :environment do
    # P2P boss names from OSRS hiscores API
    # These are the boss names that appear in the API response, mapped to p2p_minigame
    # Obor and Bryophyta are F2P bosses and should be excluded from this check
    P2P_BOSSES = [
      'Abyssal Sire', 'Alchemical Hydra', 'Artio', 'Barrows Chests',
      'Callisto', "Calvar'ion", 'Cerberus', 'Chambers of Xeric',
      'Chambers of Xeric: Challenge Mode', 'Chaos Elemental', 'Chaos Fanatic',
      'Commander Zilyana', 'Corporeal Beast', 'Crazy Archaeologist',
      'Dagannoth Prime', 'Dagannoth Rex', 'Dagannoth Supreme',
      'Deranged Archaeologist', 'Duke Sucellus', 'General Graardor',
      'Giant Mole', 'Grotesque Guardians', 'Hespori', 'Kalphite Queen',
      'King Black Dragon', 'Kraken', "Kree'Arra", "K'ril Tsutsaroth",
      'Lunar Chests', 'Mimic', 'Nex', 'Nightmare', "Phosani's Nightmare",
      'Phantom Muspah', 'Sarachnis', 'Scorpia', 'Scurrius', 'Skotizo',
      'Sol Heredit', 'Spindel', 'Tempoross', 'The Gauntlet',
      'The Corrupted Gauntlet', 'The Leviathan', 'The Whisperer',
      'Theatre of Blood', 'Theatre of Blood: Hard Mode', 'Thermy',
      'Tombs of Amascut', 'Tombs of Amascut: Expert Mode', 'TzKal-Zuk',
      'TzTok-Jad', 'Vardorvis', 'Venenatis', "Vet'ion", 'Vorkath',
      'Wintertodt', 'Zalcano', 'Zulrah'
    ].freeze

    # Helper to extract boss KC from hiscores API response
    # Returns a hash of {boss_name => kill_count} or nil if no P2P bosses found
    def extract_boss_kc_from_csv(csv_data, p2p_bosses)
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
        'Bryophyta', 'Callisto', "Calvar'ion", 'Cerberus', 'Chambers of Xeric',
        'Chambers of Xeric: Challenge Mode', 'Chaos Elemental', 'Chaos Fanatic', 'Commander Zilyana',
        'Corporeal Beast', 'Crazy Archaeologist', 'Dagannoth Prime', 'Dagannoth Rex',
        'Dagannoth Supreme', 'Deranged Archaeologist', 'Duke Sucellus', 'General Graardor',
        'Giant Mole', 'Grotesque Guardians', 'Hespori', 'Kalphite Queen', 'King Black Dragon',
        'Kraken', "Kree'Arra", "K'ril Tsutsaroth", 'Lunar Chests', 'Mimic', 'Nex', 'Nightmare',
        "Phosani's Nightmare", 'Obor', 'Phantom Muspah', 'Sarachnis', 'Scorpia', 'Scurrius',
        'Skotizo', 'Sol Heredit', 'Spindel', 'Tempoross', 'The Gauntlet', 'The Corrupted Gauntlet',
        'The Leviathan', 'The Whisperer', 'Theatre of Blood', 'Theatre of Blood: Hard Mode',
        'Thermy', 'Tombs of Amascut', 'Tombs of Amascut: Expert Mode', 'TzKal-Zuk', 'TzTok-Jad',
        'Vardorvis', 'Venenatis', "Vet'ion", 'Vorkath', 'Wintertodt', 'Zalcano', 'Zulrah'
      ]
      
      boss_kc_found = {}
      activity_start_idx = 25  # Skills take lines 0-24
      
      csv_activity_order.each_with_index do |activity_name, idx|
        line_idx = activity_start_idx + idx
        next if line_idx >= lines.length
        
        # Only check P2P bosses
        next unless p2p_bosses.include?(activity_name)
        
        line = lines[line_idx]
        values = line.split(',').map(&:strip).map(&:to_i)
        next if values.length < 2
        
        rank, score = values[0], values[1]
        
        # If player has KC for this P2P boss, record it
        if rank != -1 && score > 0
          boss_kc_found[activity_name] = score
        end
      end
      
      boss_kc_found.empty? ? nil : boss_kc_found
    end

    puts "=" * 80
    puts "Checking false_p2p_flagged list for players with P2P boss KC"
    puts "=" * 80
    puts ""
    puts "NOTE: This check looks specifically for P2P boss kill counts."
    puts "Obor and Bryophyta are excluded as they are F2P bosses."
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
      
      # Fetch raw hiscores data to check boss KC
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
        
        # Extract boss KC from the CSV
        boss_kc_data = extract_boss_kc_from_csv(csv_data, P2P_BOSSES)
        
        if boss_kc_data && boss_kc_data.any?
          # Player has P2P boss KC
          boss_list = boss_kc_data.map { |boss, kc| "#{boss}: #{kc}" }.join(", ")
          players_to_remove << {
            name: player_name,
            reason: "Has P2P boss KC (#{boss_list})",
            boss_kc: boss_kc_data
          }
          puts "❌ REMOVE: #{player_name} - Has P2P boss KC: #{boss_list}"
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
      puts "These players have P2P boss kill counts and should not be in the"
      puts "false_p2p_flagged list. Please remove them from config/initializers/assets.rb"
      puts ""
      puts "To remove them, edit line 21 in config/initializers/assets.rb and delete these names."
    else
      puts "✅ No players found with P2P boss KC!"
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
