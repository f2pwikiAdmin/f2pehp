#!/usr/bin/env ruby
# frozen_string_literal: true

# Demonstration script for F2P Activity Verification Layer
# This script shows how the new verification methods work with example data

puts "=" * 80
puts "F2P Activity Verification Layer - Demonstration"
puts "=" * 80
puts

# Simulate stats hash from hiscores parser
def create_test_stats(obor: 0, bryo: 0, clues: 0, p2p: false)
  {
    "overall_lvl" => p2p ? 1600 : 838,
    "attack_lvl" => 60,
    "strength_lvl" => 60,
    "defence_lvl" => 60,
    "hitpoints_lvl" => 60,
    "ranged_lvl" => 60,
    "prayer_lvl" => 45,
    "magic_lvl" => 55,
    "cooking_lvl" => 70,
    "woodcutting_lvl" => 60,
    "fishing_lvl" => 65,
    "firemaking_lvl" => 50,
    "crafting_lvl" => 40,
    "smithing_lvl" => 40,
    "mining_lvl" => 60,
    "runecraft_lvl" => 44,
    :obor_kc => obor,
    :bryo_kc => bryo,
    :clues_beginner => clues,
    :potential_p2p => p2p ? 1 : 0,
    :f2p_levels_sum => 829,
    :members_skill_count => 9,
    :members_levels_sum => p2p ? 100 : 9
  }
end

# Mock the build_f2p_activity_signals method
def build_f2p_activity_signals(stats)
  signals = []
  
  obor_kc = (stats[:obor_kc] || stats["obor_kc"]).to_i
  signals << "Obor KC: #{obor_kc}" if obor_kc > 0
  
  bryo_kc = (stats[:bryo_kc] || stats["bryo_kc"]).to_i
  signals << "Bryophyta KC: #{bryo_kc}" if bryo_kc > 0
  
  beginner_clues = (stats[:clues_beginner] || stats["clues_beginner"]).to_i
  signals << "Beginner clues: #{beginner_clues}" if beginner_clues > 0
  
  signals
end

# Mock the log_f2p_activity_signals method
def log_f2p_activity_signals(player_name, signals, creation: false)
  suffix = creation ? " (creation)" : ""
  
  if signals.any?
    puts "✅ Player #{player_name} F2P activity verification signals#{suffix}: #{signals.join(', ')}"
  else
    puts "ℹ️  Player #{player_name} has no F2P boss KC or beginner clues (acceptable - not required for F2P verification)"
  end
end

# Test scenarios
puts "Test Scenario 1: Player with all F2P activities"
puts "-" * 80
stats1 = create_test_stats(obor: 127, bryo: 45, clues: 23)
signals1 = build_f2p_activity_signals(stats1)
log_f2p_activity_signals("Dirtcrab", signals1)
puts "Result: Player is F2P (potential_p2p = #{stats1[:potential_p2p]})"
puts

puts "Test Scenario 2: Player with only Obor KC"
puts "-" * 80
stats2 = create_test_stats(obor: 50)
signals2 = build_f2p_activity_signals(stats2)
log_f2p_activity_signals("OborSlayer", signals2)
puts "Result: Player is F2P (potential_p2p = #{stats2[:potential_p2p]})"
puts

puts "Test Scenario 3: Player with only beginner clues"
puts "-" * 80
stats3 = create_test_stats(clues: 100)
signals3 = build_f2p_activity_signals(stats3)
log_f2p_activity_signals("ClueMaster", signals3)
puts "Result: Player is F2P (potential_p2p = #{stats3[:potential_p2p]})"
puts

puts "Test Scenario 4: Player with no F2P activities"
puts "-" * 80
stats4 = create_test_stats
signals4 = build_f2p_activity_signals(stats4)
log_f2p_activity_signals("CleanF2P", signals4)
puts "Result: Player is F2P (potential_p2p = #{stats4[:potential_p2p]})"
puts "⭐ This is ACCEPTABLE - lack of F2P activities does NOT indicate P2P"
puts

puts "Test Scenario 5: Player creation with F2P activities"
puts "-" * 80
stats5 = create_test_stats(obor: 10, bryo: 5, clues: 15)
signals5 = build_f2p_activity_signals(stats5)
log_f2p_activity_signals("NewPlayer", signals5, creation: true)
puts "Result: Player creation allowed (potential_p2p = #{stats5[:potential_p2p]})"
puts

puts "Test Scenario 6: P2P player with F2P activities (should be blocked by P2P checks, not F2P activity)"
puts "-" * 80
stats6 = create_test_stats(obor: 100, bryo: 50, clues: 50, p2p: true)
signals6 = build_f2p_activity_signals(stats6)
log_f2p_activity_signals("P2PPlayer", signals6)
puts "Result: Player is P2P (potential_p2p = #{stats6[:potential_p2p]})"
puts "⚠️  Blocked by P2P checks (trained P2P skills), NOT by F2P activity absence"
puts

puts "=" * 80
puts "Key Principles Demonstrated:"
puts "=" * 80
puts "✅ F2P activities provide POSITIVE signals (logged when present)"
puts "✅ Lack of F2P activities is ACCEPTABLE (neutral, not P2P indicator)"
puts "✅ Missing/nil data handled gracefully (treated as zero)"
puts "✅ P2P detection based on skills, NOT absence of F2P activities"
puts "✅ All verification decisions logged for visibility"
puts

puts "Implementation Notes:"
puts "- Checks ONLY: Obor KC, Bryophyta KC, Beginner clues"
puts "- Does NOT check any other bosses or clue tiers"
puts "- Integrated into both player creation and update flows"
puts "- No database migrations needed (uses existing columns)"
puts "- Backward compatible with existing verification"
puts

puts "=" * 80
puts "Demonstration Complete ✅"
puts "=" * 80
