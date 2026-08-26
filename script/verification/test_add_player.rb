#!/usr/bin/env ruby
# Test script to verify adding a player with the new verification system

require_relative 'config/environment'

def test_add_player(player_name)
  puts "=" * 80
  puts "Testing player addition: #{player_name}"
  puts "=" * 80
  
  # Check if player already exists
  existing = Player.find_player(player_name)
  if existing
    puts "❌ Player already exists in database: #{existing.player_name}"
    puts "   ID: #{existing.id}, potential_p2p: #{existing.potential_p2p}"
    puts "\n   To test addition, you would need to remove this player first."
    return
  end
  
  puts "✓ Player not found in database - can proceed with addition"
  puts ""
  
  # Try to add the player
  puts "Attempting to add player: #{player_name}"
  puts "This will:"
  puts "  1. Fetch stats from OSRS hiscores API"
  puts "  2. Run the new 4-point verification system"
  puts "  3. Add player if they pass verification (F2P)"
  puts ""
  
  result = Player.create_new(player_name)
  
  puts ""
  puts "=" * 80
  puts "Result: #{result.inspect}"
  puts "=" * 80
  
  case result
  when Player
    puts "✅ SUCCESS! Player added successfully"
    puts "   Name: #{result.player_name}"
    puts "   Account Type: #{result.player_acc_type}"
    puts "   P2P Flag: #{result.potential_p2p}"
    puts "   ID: #{result.id}"
    puts ""
    puts "   Player passed the 4-point verification system!"
    puts "   This means they are confirmed F2P:"
    puts "   - Check 0: Parser did not detect P2P content"
    puts "   - Check 1: Total level <= 1494 (F2P max)"
    puts "   - Check 2: No P2P skill training detected"
    puts "   - Check 3: No P2P boss KC or clue scrolls"
  when 'p2p'
    puts "❌ Player rejected as P2P"
    puts "   The 4-point verification system detected P2P content"
    puts "   This player cannot be added to the F2P rankings"
  when 'exists'
    puts "❌ Player already exists"
  when 'banned'
    puts "❌ Player is banned"
  when 'failed'
    puts "❌ Failed to fetch stats from OSRS hiscores"
    puts "   This could be a network issue or the player doesn't exist"
  when nil
    puts "❌ Player does not exist or stats could not be fetched"
  else
    puts "⚠️  Unexpected result: #{result}"
  end
  
  puts "=" * 80
end

# Test with the specified player
player_name = ARGV[0] || "Dirtcrab"
test_add_player(player_name)
