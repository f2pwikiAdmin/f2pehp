require 'rails_helper'

# Test for the fix of the F2P detection bug where Overall was being added to f2p_levels_sum
RSpec.describe Hiscores, 'f2p_levels_sum calculation fix' do
  describe '.parse_stats_csv' do
    it 'correctly calculates f2p_levels_sum without including overall' do
      # Test data for a F2P player with total level 837 (WITHOUT Sailing quest)
      # 15 F2P skills sum to 829, 8 P2P skills all at level 1 (sum to 8)
      # Overall from Jagex API: 837 (829 + 8)
      # Note: Sailing NOT in API response - player hasn't done Sailing quest
      csv_data = [
        '12345,837,15000000',    # Overall: 837 (should NOT be added to f2p_levels_sum)
        '10000,60,300000',       # Attack: 60
        '10001,60,300000',       # Defence: 60
        '10002,60,300000',       # Strength: 60
        '10003,60,300000',       # Hitpoints: 60
        '10004,60,300000',       # Ranged: 60
        '10005,45,60000',        # Prayer: 45
        '10006,55,170000',       # Magic: 55
        '10007,70,800000',       # Cooking: 70
        '10008,60,300000',       # Woodcutting: 60
        '-1,1,0',                # Fletching (P2P, unranked, level 1)
        '10009,65,450000',       # Fishing: 65
        '10010,50,100000',       # Firemaking: 50
        '10011,40,40000',        # Crafting: 40
        '10012,40,40000',        # Smithing: 40
        '10013,60,300000',       # Mining: 60
        '-1,1,0',                # Herblore (P2P, unranked, level 1)
        '-1,1,0',                # Agility (P2P, unranked, level 1)
        '-1,1,0',                # Thieving (P2P, unranked, level 1)
        '-1,1,0',                # Slayer (P2P, unranked, level 1)
        '-1,1,0',                # Farming (P2P, unranked, level 1)
        '10014,44,55000',        # Runecraft: 44
        '-1,1,0',                # Hunter (P2P, unranked, level 1)
        '-1,1,0',                # Construction (P2P, unranked, level 1)
      ].join("\n")

      result = Hiscores.send(:parse_stats_csv, csv_data)

      # THE FIX: f2p_levels_sum should be the sum of individual F2P skills ONLY
      # F2P skills sum: 60+60+60+60+60+45+55+70+60+65+50+40+40+60+44 = 829
      # This should NOT include the overall level (837)
      expect(result[:f2p_levels_sum]).to eq(829)
      
      # Overall should be stored separately
      expect(result['overall_lvl']).to eq(837)
      
      # Members skills should sum to 8 (all at level 1, Sailing omitted)
      expect(result[:members_skill_count]).to eq(8)
      expect(result[:members_levels_sum]).to eq(8)
      
      # CRITICAL: The fix ensures f2p_levels_sum + members_levels_sum = overall
      # This allows Check 1b in Player#initial_detailed_p2p_check to work correctly
      expect(result[:f2p_levels_sum] + result[:members_levels_sum]).to eq(result['overall_lvl'])
      
      # Player should not be flagged as P2P (no trained P2P skills)
      expect(result["potential_p2p"]).to eq(0)
    end

    it 'correctly calculates f2p_levels_sum for maxed F2P player' do
      # Test data for a maxed F2P player (WITHOUT Sailing quest)
      # 15 F2P skills at 99 = 1485, 8 P2P skills at 1 = 8
      # Overall from Jagex API: 1493 (1485 + 8)
      # Note: Sailing NOT in API response - F2P maximum without Sailing quest
      csv_data = [
        '1,1493,200000000',      # Overall: 1493 (F2P maximum without Sailing)
        '1,99,13034431',         # Attack: 99
        '1,99,13034431',         # Defence: 99
        '1,99,13034431',         # Strength: 99
        '1,99,13034431',         # Hitpoints: 99
        '1,99,13034431',         # Ranged: 99
        '1,99,13034431',         # Prayer: 99
        '1,99,13034431',         # Magic: 99
        '1,99,13034431',         # Cooking: 99
        '1,99,13034431',         # Woodcutting: 99
        '-1,1,0',                # Fletching (P2P, unranked, level 1)
        '1,99,13034431',         # Fishing: 99
        '1,99,13034431',         # Firemaking: 99
        '1,99,13034431',         # Crafting: 99
        '1,99,13034431',         # Smithing: 99
        '1,99,13034431',         # Mining: 99
        '-1,1,0',                # Herblore (P2P, unranked, level 1)
        '-1,1,0',                # Agility (P2P, unranked, level 1)
        '-1,1,0',                # Thieving (P2P, unranked, level 1)
        '-1,1,0',                # Slayer (P2P, unranked, level 1)
        '-1,1,0',                # Farming (P2P, unranked, level 1)
        '1,99,13034431',         # Runecraft: 99
        '-1,1,0',                # Hunter (P2P, unranked, level 1)
        '-1,1,0',                # Construction (P2P, unranked, level 1)
      ].join("\n")

      result = Hiscores.send(:parse_stats_csv, csv_data)

      # f2p_levels_sum should be 15 * 99 = 1485
      expect(result[:f2p_levels_sum]).to eq(1485)
      
      # Overall should be 1493 (F2P maximum without Sailing)
      expect(result['overall_lvl']).to eq(1493)
      
      # Members skills should sum to 8 (all at level 1, Sailing omitted)
      expect(result[:members_levels_sum]).to eq(8)
      
      # The calculation should match
      expect(result[:f2p_levels_sum] + result[:members_levels_sum]).to eq(result['overall_lvl'])
      
      # Maxed F2P player should not be flagged as P2P
      expect(result["potential_p2p"]).to eq(0)
    end
  end

  describe '.parse_stats' do
    it 'correctly calculates f2p_levels_sum without including overall (JSON parser)' do
      # Test the JSON parser has the same fix
      # Note: F2P player WITHOUT Sailing quest - overall is 837 (829 F2P + 8 P2P)
      json_data = {
        'skills' => [
          {'name' => 'Overall', 'rank' => 12345, 'level' => 837, 'xp' => 15000000},
          {'name' => 'Attack', 'rank' => 10000, 'level' => 60, 'xp' => 300000},
          {'name' => 'Defence', 'rank' => 10001, 'level' => 60, 'xp' => 300000},
          {'name' => 'Strength', 'rank' => 10002, 'level' => 60, 'xp' => 300000},
          {'name' => 'Hitpoints', 'rank' => 10003, 'level' => 60, 'xp' => 300000},
          {'name' => 'Ranged', 'rank' => 10004, 'level' => 60, 'xp' => 300000},
          {'name' => 'Prayer', 'rank' => 10005, 'level' => 45, 'xp' => 60000},
          {'name' => 'Magic', 'rank' => 10006, 'level' => 55, 'xp' => 170000},
          {'name' => 'Cooking', 'rank' => 10007, 'level' => 70, 'xp' => 800000},
          {'name' => 'Woodcutting', 'rank' => 10008, 'level' => 60, 'xp' => 300000},
          {'name' => 'Fletching', 'rank' => -1, 'level' => 1, 'xp' => 0},
          {'name' => 'Fishing', 'rank' => 10009, 'level' => 65, 'xp' => 450000},
          {'name' => 'Firemaking', 'rank' => 10010, 'level' => 50, 'xp' => 100000},
          {'name' => 'Crafting', 'rank' => 10011, 'level' => 40, 'xp' => 40000},
          {'name' => 'Smithing', 'rank' => 10012, 'level' => 40, 'xp' => 40000},
          {'name' => 'Mining', 'rank' => 10013, 'level' => 60, 'xp' => 300000},
          {'name' => 'Herblore', 'rank' => -1, 'level' => 1, 'xp' => 0},
          {'name' => 'Agility', 'rank' => -1, 'level' => 1, 'xp' => 0},
          {'name' => 'Thieving', 'rank' => -1, 'level' => 1, 'xp' => 0},
          {'name' => 'Slayer', 'rank' => -1, 'level' => 1, 'xp' => 0},
          {'name' => 'Farming', 'rank' => -1, 'level' => 1, 'xp' => 0},
          {'name' => 'Runecraft', 'rank' => 10014, 'level' => 44, 'xp' => 55000},
          {'name' => 'Hunter', 'rank' => -1, 'level' => 1, 'xp' => 0},
          {'name' => 'Construction', 'rank' => -1, 'level' => 1, 'xp' => 0},
        ]
      }

      result = Hiscores.send(:parse_stats, json_data)

      # Same expectations as CSV parser (Sailing omitted)
      # Note: overall is 837 (829 F2P + 8 P2P), matching CSV test
      expect(result[:f2p_levels_sum]).to eq(829)
      expect(result['overall_lvl']).to eq(837)
      expect(result[:members_skill_count]).to eq(8)
      expect(result[:members_levels_sum]).to eq(8)
      expect(result[:f2p_levels_sum] + result[:members_levels_sum]).to eq(result['overall_lvl'])
      expect(result["potential_p2p"]).to eq(0)
    end
  end
end
