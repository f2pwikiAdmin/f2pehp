#!/usr/bin/env ruby
# Test script to verify the verification system with mock data

require_relative 'config/environment'

def test_add_player_with_mock(player_name, mock_stats)
  puts "=" * 80
  puts "Testing player verification: #{player_name}"
  puts "=" * 80
  puts ""
  
  # Check if player already exists
  existing = Player.find_player(player_name)
  if existing
    puts "❌ Player already exists in database: #{existing.player_name}"
    return
  end
  
  puts "✓ Player not found in database - can proceed with verification"
  puts ""
  puts "Testing with mock data: #{mock_stats.keys.join(', ')}"
  puts ""
  
  # Test the verification system
  result = Player.initial_p2p_check(mock_stats, player_name)
  
  if result
    puts "❌ Player would be REJECTED as P2P"
    puts "   The 4-point verification system detected P2P content"
  else
    puts "✅ Player would PASS verification as F2P"
    puts "   The player passes the 4-point verification system:"
    puts "   - Check 0: Parser did not detect P2P content"
    puts "   - Check 1: Total level <= 1494 (F2P max)"
    puts "   - Check 2: No P2P skill training detected"
    puts "   - Check 3: No P2P boss KC or clue scrolls"
  end
  
  puts "=" * 80
end

# Test Case 1: Pure F2P player (no P2P content)
f2p_stats = {
  'levels' => {
    'attack' => 60,
    'defence' => 60,
    'strength' => 60,
    'constitution' => 60,
    'range' => 60,
    'prayer' => 60,
    'magic' => 60,
    'cooking' => 60,
    'woodcutting' => 60,
    'fletching' => 60,
    'fishing' => 60,
    'firemaking' => 60,
    'crafting' => 60,
    'smithing' => 60,
    'mining' => 60,
    'herblore' => 60,
    'agility' => 60,
    'thieving' => 60,
    'slayer' => 60,
    'farming' => 60,
    'runecrafting' => 60,
    'hunter' => 60,
    'construction' => 60,
    'summoning' => 60,
    'dungeoneering' => 60,
    'divination' => 60,
    'invention' => 60,
    'archaeology' => 60,
    'necromancy' => 60
  }
}

# Test Case 2: P2P player (with P2P skills like Summoning above level 52)
p2p_stats = {
  'levels' => f2p_stats['levels'].merge({
    'summoning' => 75,  # Summoning is P2P only
  })
}

puts "\n"
test_add_player_with_mock("F2PPlayer", f2p_stats)

puts "\n\n"
test_add_player_with_mock("P2PPlayer", p2p_stats)
