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
      begin
        boss_kc_data = fetch_boss_kc(player_name, player.player_acc_type)
        
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

  # Helper method to fetch and parse boss KC from hiscores
  def fetch_boss_kc(player_name, account_type)
    # Get the API URI for this player
    stats_uri = Hiscores.send(:api_url, account_type, player_name)
    
    # Fetch raw CSV data
    csv_data = Hiscores.fetch(stats_uri)
    return nil unless csv_data
    
    # Parse the CSV to extract boss KC
    lines = csv_data.strip.split("\n")
    
    # Skills are lines 0-24, activities/bosses start at line 25
    # The order matches the csv_activity_order in Hiscores service
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
    
    # P2P bosses from the constant defined above
    p2p_bosses = [
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
end
