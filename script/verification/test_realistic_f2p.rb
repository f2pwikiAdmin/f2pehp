#!/usr/bin/env ruby
# Realistic test to show F2P player can now be added successfully

require_relative '../../config/environment'

puts "=" * 80
puts "REALISTIC F2P PLAYER ADDITION TEST"
puts "=" * 80
puts ""
puts "This test simulates adding a known F2P player with typical F2P stats."
puts ""

# Simulate a realistic F2P player profile
# Total level: 1200 (well under F2P max of 1494)
# Some skills trained, but no P2P skills beyond level 1
# Has F2P boss KC (Obor, Bryophyta)
# Has beginner clue scrolls (F2P)
# Has LMS rank (F2P minigame)

f2p_player_stats = {
  # Core stats
  :overall_lvl => 1200,
  "overall_lvl" => 1200,
  :overall_xp => 25000000,
  "overall_xp" => 25000000,
  
  # Parser flag (should be 0 for F2P)
  :potential_p2p => 0,
  "potential_p2p" => 0,
  
  # Helper fields from parser (sum of F2P levels)
  :f2p_levels_sum => 1191,  # 15 F2P skills
  "f2p_levels_sum" => 1191,
  :members_skill_count => 9,  # 9 P2P skills at base level 1
  "members_skill_count" => 9,
  :members_levels_sum => 9,  # All at level 1
  "members_levels_sum" => 9,
  
  # Individual skill levels (sample)
  "attack_lvl" => 80,
  "defence_lvl" => 75,
  "strength_lvl" => 85,
  "hitpoints_lvl" => 82,
  "ranged_lvl" => 70,
  "prayer_lvl" => 52,
  "magic_lvl" => 78,
  "cooking_lvl" => 80,
  "woodcutting_lvl" => 75,
  "fishing_lvl" => 70,
  "firemaking_lvl" => 65,
  "crafting_lvl" => 60,
  "smithing_lvl" => 55,
  "mining_lvl" => 68,
  "runecraft_lvl" => 50,
  
  # F2P activities
  :obor_kc => 15,
  :bryo_kc => 8,
  :lms_score => 250,
  :clues_beginner => 42,
  :clues_all => 42
}

puts "Player Profile:"
puts "  Total Level: #{f2p_player_stats[:overall_lvl]}"
puts "  F2P Skills Sum: #{f2p_player_stats[:f2p_levels_sum]}"
puts "  P2P Skills: All at level 1 (base)"
puts "  Obor KC: #{f2p_player_stats[:obor_kc]}"
puts "  Bryophyta KC: #{f2p_player_stats[:bryo_kc]}"
puts "  LMS Score: #{f2p_player_stats[:lms_score]}"
puts "  Beginner Clues: #{f2p_player_stats[:clues_beginner]}"
puts ""

# Test the verification
puts "Running P2P verification..."
puts ""

result = Player.initial_p2p_check(f2p_player_stats, "TestF2PPlayer")

puts "Verification Result:"
if result == false
  puts "  ✅ PASS - Player identified as F2P"
  puts "  ✅ Player can be added to the system"
  puts ""
  puts "Breakdown:"
  puts "  ✓ Check 0: Parser did not detect P2P content (potential_p2p = 0)"
  puts "  ✓ Check 1a: Total level (1200) <= F2P max (1494)"
  puts "  ✓ Check 1b: F2P skill sum (1191) + P2P base (9) = 1200 (matches overall)"
  puts "  ✓ Check 2/3: Would check hiscores (F2P bosses/clues only)"
else
  puts "  ❌ FAIL - Player incorrectly flagged as P2P"
  puts "  ❌ Player would be rejected"
  puts ""
  puts "This should not happen with the Brutus fix!"
  exit 1
end
puts ""

# Test with a player at the F2P maximum
puts "=" * 80
puts "Testing edge case: Maxed F2P player (total level = 1494)"
puts "=" * 80
puts ""

maxed_f2p_stats = {
  :overall_lvl => 1494,
  "overall_lvl" => 1494,
  :potential_p2p => 0,
  "potential_p2p" => 0,
  :f2p_levels_sum => 1485,  # 15 skills at 99 each
  "f2p_levels_sum" => 1485,
  :members_skill_count => 9,
  "members_skill_count" => 9,
  :members_levels_sum => 9,
  "members_levels_sum" => 9
}

result = Player.initial_p2p_check(maxed_f2p_stats, "MaxedF2PPlayer")

if result == false
  puts "✅ PASS - Maxed F2P player correctly identified (1494 is the exact limit)"
else
  puts "❌ FAIL - Maxed F2P player incorrectly flagged as P2P"
  exit 1
end
puts ""

# Test with a player just over the limit
puts "=" * 80
puts "Testing edge case: Player with 1 P2P level trained (total = 1495)"
puts "=" * 80
puts ""

p2p_stats = {
  :overall_lvl => 1495,
  "overall_lvl" => 1495,
  :potential_p2p => 0,  # Parser might not catch 1 level
  "potential_p2p" => 0,
  :f2p_levels_sum => 1485,
  "f2p_levels_sum" => 1485,
  :members_skill_count => 9,
  "members_skill_count" => 9,
  :members_levels_sum => 10,  # One P2P skill at level 2 instead of 1
  "members_levels_sum" => 10
}

result = Player.initial_p2p_check(p2p_stats, "SlightlyP2PPlayer")

if result == true
  puts "✅ PASS - P2P player correctly detected (total 1495 > 1494 max OR 1495 > 1485+10)"
else
  puts "❌ FAIL - P2P player not detected"
  exit 1
end
puts ""

puts "=" * 80
puts "✅ ALL REALISTIC TESTS PASSED"
puts "=" * 80
puts ""
puts "Conclusion:"
puts "  • F2P players with typical stats can be added successfully"
puts "  • Maxed F2P players (1494) are correctly identified"
puts "  • P2P players (>1494 or trained P2P skills) are correctly detected"
puts "  • The Brutus API misalignment bug is fixed!"
puts ""
