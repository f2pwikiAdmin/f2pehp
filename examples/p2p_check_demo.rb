#!/usr/bin/env ruby
# Example script demonstrating P2P check failure reporting
# Run with: ruby examples/p2p_check_demo.rb

puts "=" * 100
puts "P2P CHECK FAILURE REPORTING - DEMONSTRATION"
puts "=" * 100
puts ""
puts "This demonstrates how the P2P check system now reports failures."
puts ""

# Simulate different P2P check scenarios
scenarios = [
  {
    name: "Player1 - In Fakes List",
    in_fakes: true,
    stats: { "potential_p2p" => 0 },
    expected_result: "FAILED",
    expected_reason: "In fakes list"
  },
  {
    name: "Player2 - In False P2P Flagged List",
    in_false_p2p: true,
    stats: { 
      "potential_p2p" => 0,
      f2p_levels_sum: 1485,
      members_skill_count: 9,
      overall_lvl: 1494
    },
    expected_result: "PASSED",
    expected_reason: "In false_p2p_flagged list (manual override)"
  },
  {
    name: "Player3 - Parser Detected P2P Skill",
    stats: { 
      "potential_p2p" => 10,
      f2p_levels_sum: 829,
      members_skill_count: 9,
      overall_lvl: 887
    },
    expected_result: "FAILED",
    expected_reason: "Parser detected P2P skill or activity"
  },
  {
    name: "Player4 - Overall Level Exceeds F2P Max",
    stats: {
      "potential_p2p" => 0,
      f2p_levels_sum: 1485,
      members_skill_count: 9,
      overall_lvl: 1500
    },
    expected_result: "FAILED",
    expected_reason: "Overall level 1500 exceeds F2P max 1494 (6 P2P levels trained)"
  },
  {
    name: "Player5 - Pure F2P Player",
    stats: {
      "potential_p2p" => 0,
      f2p_levels_sum: 829,
      members_skill_count: 9,
      overall_lvl: 838
    },
    expected_result: "PASSED",
    expected_reason: "All checks passed"
  }
]

scenarios.each_with_index do |scenario, idx|
  puts "-" * 100
  puts "Scenario #{idx + 1}: #{scenario[:name]}"
  puts "-" * 100
  
  # Simulate check logic
  if scenario[:in_fakes]
    result = "FAILED"
    reason = "In fakes list"
    log = "[P2P CHECK] #{scenario[:name]}: FAILED - In fakes list (known P2P player)"
  elsif scenario[:in_false_p2p]
    result = "PASSED"
    reason = "In false_p2p_flagged list (manual override)"
    log = "[P2P CHECK] #{scenario[:name]}: PASSED - In false_p2p_flagged list (override)"
  elsif scenario[:stats]["potential_p2p"].to_i > 0
    result = "FAILED"
    reason = "Parser detected P2P skill or activity"
    log = "[P2P CHECK] #{scenario[:name]}: FAILED - Parser detected P2P skill/activity (value: #{scenario[:stats]["potential_p2p"]})"
  elsif scenario[:stats][:overall_lvl] && scenario[:stats][:f2p_levels_sum] && scenario[:stats][:members_skill_count]
    overall = scenario[:stats][:overall_lvl]
    f2p_sum = scenario[:stats][:f2p_levels_sum]
    members_count = scenario[:stats][:members_skill_count]
    expected_overall = f2p_sum + members_count
    
    if overall > expected_overall
      trained_levels = overall - expected_overall
      result = "FAILED"
      reason = "Overall level #{overall} exceeds F2P max #{expected_overall} (#{trained_levels} P2P levels trained)"
      log = "[P2P CHECK] #{scenario[:name]}: FAILED - Overall level (#{overall}) exceeds F2P max (#{expected_overall}) by #{trained_levels} levels"
    else
      result = "PASSED"
      reason = "All checks passed"
      log = "[P2P CHECK] #{scenario[:name]}: PASSED - All checks passed (F2P player)"
    end
  else
    result = "UNKNOWN"
    reason = "Insufficient data"
    log = "[P2P CHECK] #{scenario[:name]}: UNKNOWN - Insufficient data"
  end
  
  puts "Stats:"
  scenario[:stats].each do |key, value|
    puts "  #{key}: #{value}"
  end
  puts ""
  puts "Log Entry:"
  puts "  #{log}"
  puts ""
  puts "Database Update:"
  puts "  potential_p2p: #{result == 'FAILED' ? 1 : 0}"
  puts "  p2p_check_reason: \"#{reason}\""
  puts ""
  puts "Expected: #{scenario[:expected_result]}"
  puts "Actual:   #{result}"
  puts "Match:    #{result == scenario[:expected_result] ? '✓ PASS' : '✗ FAIL'}"
  puts ""
end

puts "=" * 100
puts "DEMONSTRATION COMPLETE"
puts "=" * 100
puts ""
puts "Key Takeaways:"
puts "1. Every P2P check now logs with [P2P CHECK] prefix"
puts "2. Logs include player name, result (PASSED/FAILED), and specific reason"
puts "3. Reasons are stored in p2p_check_reason database column"
puts "4. Use rake tasks to analyze failures:"
puts "   - rake players:analyze_p2p_failures (all players)"
puts "   - rake players:analyze_player_p2p[PlayerName] (specific player)"
puts ""
