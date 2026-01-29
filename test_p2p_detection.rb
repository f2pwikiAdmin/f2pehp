#!/usr/bin/env ruby
# Test to understand P2P detection logic

# Simulate what the parser does
def test_p2p_detection(lvl, xp, skill_name)
  puts "\n" + "="*60
  puts "Testing: #{skill_name}"
  puts "Level: #{lvl}, XP: #{xp}"
  
  # Apply the same logic as the parser
  lvl = [lvl, 1].max
  xp = [xp, 0].max
  
  puts "After normalization: Level: #{lvl}, XP: #{xp}"
  
  # Check P2P detection
  is_p2p = (lvl > 1 || xp > 0)
  
  puts "Result: #{is_p2p ? 'P2P FLAGGED' : 'F2P (OK)'}"
  puts "Logic: lvl > 1 (#{lvl > 1}) || xp > 0 (#{xp > 0}) = #{is_p2p}"
  puts "="*60
  
  is_p2p
end

puts "P2P DETECTION LOGIC TEST"
puts "Testing various scenarios for P2P skill detection"

# Test Case 1: Completely unranked (what API might return)
test_p2p_detection(-1, 0, "Unranked P2P skill (API returns -1, 0)")

# Test Case 2: Base level, no XP
test_p2p_detection(1, 0, "Base level P2P skill (level 1, 0 XP)")

# Test Case 3: Slightly trained
test_p2p_detection(1, 50, "Slightly trained P2P skill (level 1, 50 XP)")

# Test Case 4: Leveled up
test_p2p_detection(2, 100, "Leveled P2P skill (level 2, 100 XP)")

# Test Case 5: What if API returns 0 for level?
test_p2p_detection(0, 0, "Zero level (API might return 0, 0)")

# Test Case 6: What if API returns nil?
puts "\nTesting with nil values (rare but possible):"
test_p2p_detection(nil, nil, "Nil values")

puts "\n\nCONCLUSION:"
puts "If the OSRS API returns -1 or 0 for unranked P2P skills,"
puts "the normalization to [lvl, 1].max ensures level = 1"
puts "and [xp, 0].max ensures xp = 0"
puts "So the check (lvl > 1 || xp > 0) should correctly return FALSE for F2P players"
puts "\nThis means the logic APPEARS correct..."
puts "The issue might be elsewhere in the flow."
