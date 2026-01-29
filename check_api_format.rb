#!/usr/bin/env ruby
# Fetch actual OSRS API response and analyze the format

require 'open-uri'
require 'uri'

# Test with a known player - let's use a high-level player
test_player = ARGV[0] || "Lynx Titan"  # Known maxed player

puts "=" * 80
puts "OSRS API FORMAT ANALYSIS"
puts "=" * 80
puts ""
puts "Fetching hiscores for: #{test_player}"
puts ""

url_friendly_name = ERB::Util.url_encode(test_player).gsub(/(%C2)*%A0/, '_')
stats_uri = URI.join(
  'https://secure.runescape.com',
  "m=hiscore_oldschool/index_lite.ws",
  "?player=#{url_friendly_name}"
)

begin
  openuri_params = {
    open_timeout: 10,
    read_timeout: 10
  }
  
  csv_data = stats_uri.read(openuri_params)
  lines = csv_data.strip.split("\n")
  
  puts "✅ Successfully fetched hiscores"
  puts "Total lines in response: #{lines.length}"
  puts ""
  
  puts "First 30 lines (skills):"
  lines[0..29].each_with_index do |line, idx|
    puts "  Line #{idx}: #{line}"
  end
  puts ""
  
  puts "Lines 25-50 (start of activities):"
  lines[25..50].each_with_index do |line, idx|
    actual_idx = 25 + idx
    puts "  Line #{actual_idx}: #{line}"
  end
  puts ""
  
  puts "Last 10 lines:"
  start_idx = [0, lines.length - 10].max
  lines[start_idx..-1].each_with_index do |line, idx|
    actual_idx = start_idx + idx
    puts "  Line #{actual_idx}: #{line}"
  end
  puts ""
  
  # Count total activities
  num_skills = 25
  num_activities = lines.length - num_skills
  puts "Number of skills: #{num_skills}"
  puts "Number of activities: #{num_activities}"
  puts ""
  
  # Compare with our csv_activity_order
  puts "=" * 80
  puts "COMPARISON WITH OUR CODE"
  puts "=" * 80
  puts ""
  
  # Our expected activity count
  our_activities = [
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
  
  puts "Our csv_activity_order has: #{our_activities.length} activities"
  puts "OSRS API returns: #{num_activities} activities"
  puts ""
  
  if num_activities != our_activities.length
    puts "⚠️  MISMATCH DETECTED!"
    puts "   Difference: #{num_activities - our_activities.length} activities"
    puts ""
    if num_activities > our_activities.length
      puts "   OSRS API has MORE activities than our code expects"
      puts "   This means NEW bosses/activities were added to OSRS that we don't have!"
      puts "   This will cause ALL activities after the missing ones to be misaligned!"
    else
      puts "   OSRS API has FEWER activities than our code expects"
      puts "   We may have activities in our list that don't exist in the API"
    end
  else
    puts "✅ Activity count matches!"
  end
  
rescue OpenURI::HTTPError => e
  puts "❌ HTTP Error: #{e.message}"
  puts "   Player may not exist or API may be down"
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(3).join("\n")
end
