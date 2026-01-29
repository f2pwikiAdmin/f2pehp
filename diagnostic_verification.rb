#!/usr/bin/env ruby
# Diagnostic script to add logging and test real player verification

require_relative 'config/environment'
require 'open-uri'

# Test with a real F2P player if provided, or use mock data
player_name = ARGV[0] || "MockF2PPlayer"

puts "=" * 80
puts "COMPREHENSIVE F2P VERIFICATION DIAGNOSTIC"
puts "=" * 80
puts ""
puts "Player: #{player_name}"
puts ""

if player_name == "MockF2PPlayer"
  puts "Using MOCK F2P player data (no API call)"
  puts ""
  
  # Mock F2P player data
  stats = {
    :overall_lvl => 1200,
    "overall_lvl" => 1200,
    :overall_xp => 25000000,
    "overall_xp" => 25000000,
    :potential_p2p => 0,
    "potential_p2p" => 0,
    :f2p_levels_sum => 1191,
    "f2p_levels_sum" => 1191,
    :members_skill_count => 9,
    "members_skill_count" => 9,
    :members_levels_sum => 9,
    "members_levels_sum" => 9
  }
  
  puts "Mock Stats:"
  puts "  overall_lvl: #{stats[:overall_lvl]}"
  puts "  potential_p2p: #{stats[:potential_p2p]}"
  puts "  f2p_levels_sum: #{stats[:f2p_levels_sum]}"
  puts "  members_levels_sum: #{stats[:members_levels_sum]}"
  puts ""
  
else
  puts "Fetching REAL data from OSRS API..."
  puts ""
  
  begin
    stats, account_type = Hiscores.fetch_stats(player_name)
    
    if stats.nil?
      puts "❌ Player not found in OSRS hiscores"
      exit 1
    end
    
    puts "✅ Stats fetched successfully"
    puts "Account Type: #{account_type}"
    puts ""
    puts "Key Stats:"
    puts "  overall_lvl: #{stats[:overall_lvl] || stats["overall_lvl"]}"
    puts "  overall_xp: #{stats[:overall_xp] || stats["overall_xp"]}"
    puts "  potential_p2p: #{stats[:potential_p2p] || stats["potential_p2p"]}"
    puts "  f2p_levels_sum: #{stats[:f2p_levels_sum] || stats["f2p_levels_sum"]}"
    puts "  members_skill_count: #{stats[:members_skill_count] || stats["members_skill_count"]}"
    puts "  members_levels_sum: #{stats[:members_levels_sum] || stats["members_levels_sum"]}"
    puts ""
    
    # Show some individual skills
    puts "Sample Skills:"
    ['attack', 'defence', 'strength', 'magic', 'ranged', 'prayer'].each do |skill|
      lvl = stats["#{skill}_lvl"] || stats[:"#{skill}_lvl"]
      puts "  #{skill}: #{lvl}" if lvl
    end
    puts ""
    
    # Show activities if any
    if stats[:obor_kc] && stats[:obor_kc] > 0
      puts "  Obor KC: #{stats[:obor_kc]}"
    end
    if stats[:bryo_kc] && stats[:bryo_kc] > 0
      puts "  Bryophyta KC: #{stats[:bryo_kc]}"
    end
    if stats[:lms_score] && stats[:lms_score] > 0
      puts "  LMS Score: #{stats[:lms_score]}"
    end
    puts ""
    
  rescue => e
    puts "❌ Error fetching stats: #{e.message}"
    puts e.backtrace.first(5).join("\n")
    exit 1
  end
end

# Now test the verification with detailed logging
puts "=" * 80
puts "RUNNING VERIFICATION WITH DETAILED LOGGING"
puts "=" * 80
puts ""

# Test Check 0: Parser detection
puts "Check 0: Parser Detection"
potential_p2p_value = (stats[:potential_p2p] || stats["potential_p2p"]).to_i
puts "  potential_p2p = #{potential_p2p_value}"
if potential_p2p_value > 0
  puts "  ❌ FAIL: Parser detected P2P content"
  puts "  Result: Player would be flagged as P2P"
else
  puts "  ✅ PASS: Parser did not detect P2P content"
end
puts ""

# Test Check 1a: Total level
puts "Check 1a: Total Level Check"
overall = (stats[:overall_lvl] || stats["overall_lvl"]).to_i
puts "  Overall level: #{overall}"
puts "  F2P maximum: #{Player::F2P_MAX_TOTAL}"
if overall > Player::F2P_MAX_TOTAL
  puts "  ❌ FAIL: Total level exceeds F2P maximum"
  puts "  Result: Player would be flagged as P2P"
else
  puts "  ✅ PASS: Total level within F2P range"
end
puts ""

# Test Check 1b: P2P skill training
puts "Check 1b: P2P Skill Training Check"
has_helper_fields = stats.key?(:f2p_levels_sum) || stats.key?("f2p_levels_sum")
puts "  Has helper fields: #{has_helper_fields}"

if has_helper_fields && overall > 0
  f2p_sum = (stats[:f2p_levels_sum] || stats["f2p_levels_sum"]).to_i
  members_count = (stats[:members_skill_count] || stats["members_skill_count"]).to_i
  members_sum = (stats[:members_levels_sum] || stats["members_levels_sum"]).to_i
  
  puts "  F2P levels sum: #{f2p_sum}"
  puts "  Members skill count: #{members_count}"
  puts "  Members levels sum: #{members_sum}"
  puts "  Expected overall: #{f2p_sum + members_sum}"
  puts "  Actual overall: #{overall}"
  
  if members_count > 0
    expected_overall = f2p_sum + members_sum
    if overall > expected_overall
      trained_p2p_levels = overall - expected_overall
      puts "  ❌ FAIL: Has trained P2P skills (#{trained_p2p_levels} levels beyond base)"
      puts "  Result: Player would be flagged as P2P"
    else
      puts "  ✅ PASS: No P2P skill training detected"
    end
  else
    puts "  ⚠️  WARNING: members_count is 0 (unexpected)"
  end
else
  puts "  ⚠️  SKIPPED: Helper fields not available or overall is 0"
end
puts ""

# Run the actual verification
puts "=" * 80
puts "ACTUAL VERIFICATION RESULT"
puts "=" * 80
puts ""

result = Player.initial_p2p_check(stats, player_name)

if result
  puts "❌ VERIFICATION FAILED"
  puts "Player would be REJECTED as P2P"
  puts ""
  puts "This is the problem! A known F2P player is being flagged as P2P."
else
  puts "✅ VERIFICATION PASSED"
  puts "Player would be ACCEPTED as F2P"
  puts ""
  puts "If this is a known F2P player, the verification is working correctly."
end
puts ""

puts "=" * 80
puts "DIAGNOSTIC COMPLETE"
puts "=" * 80
