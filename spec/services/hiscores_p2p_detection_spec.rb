require 'rails_helper'

# Test for the P2P detection fix using direct member skill evidence checks
# This ensures that F2P players are not falsely flagged due to skill list changes
RSpec.describe Hiscores, 'P2P detection with member skill evidence' do
  describe '.parse_stats_csv' do
    context 'when parsing F2P player with all member skills at base level' do
      it 'stores individual member skill fields and does not flag as P2P' do
        # F2P player "Faij" scenario - all member skills at level 1, xp 0
        csv_data = [
          '12345,1344,15000000',   # Overall: 1344
          '10000,60,300000',       # Attack
          '10001,60,300000',       # Defence
          '10002,60,300000',       # Strength
          '10003,60,300000',       # Hitpoints
          '10004,60,300000',       # Ranged
          '10005,45,60000',        # Prayer
          '10006,55,170000',       # Magic
          '10007,70,800000',       # Cooking
          '10008,60,300000',       # Woodcutting
          '-1,1,0',                # Fletching (P2P, unranked, level 1, xp 0)
          '10009,65,450000',       # Fishing
          '10010,50,100000',       # Firemaking
          '10011,40,40000',        # Crafting
          '10012,40,40000',        # Smithing
          '10013,60,300000',       # Mining
          '-1,1,0',                # Herblore (P2P, unranked, level 1, xp 0)
          '-1,1,0',                # Agility (P2P, unranked, level 1, xp 0)
          '-1,1,0',                # Thieving (P2P, unranked, level 1, xp 0)
          '-1,1,0',                # Slayer (P2P, unranked, level 1, xp 0)
          '-1,1,0',                # Farming (P2P, unranked, level 1, xp 0)
          '10014,44,55000',        # Runecraft
          '-1,1,0',                # Hunter (P2P, unranked, level 1, xp 0)
          '-1,1,0',                # Construction (P2P, unranked, level 1, xp 0)
          '-1,1,0',                # Sailing (P2P, unranked, level 1, xp 0)
        ].join("\n")

        result = Hiscores.send(:parse_stats_csv, csv_data)

        # Verify individual member skill fields are stored
        expect(result['fletching_lvl']).to eq(1)
        expect(result['fletching_xp']).to eq(0)
        expect(result['fletching_rank']).to eq(-1)
        
        expect(result['herblore_lvl']).to eq(1)
        expect(result['herblore_xp']).to eq(0)
        
        expect(result['agility_lvl']).to eq(1)
        expect(result['agility_xp']).to eq(0)
        
        expect(result['thieving_lvl']).to eq(1)
        expect(result['thieving_xp']).to eq(0)
        
        expect(result['slayer_lvl']).to eq(1)
        expect(result['slayer_xp']).to eq(0)
        
        expect(result['farming_lvl']).to eq(1)
        expect(result['farming_xp']).to eq(0)
        
        expect(result['hunter_lvl']).to eq(1)
        expect(result['hunter_xp']).to eq(0)
        
        expect(result['construction_lvl']).to eq(1)
        expect(result['construction_xp']).to eq(0)
        
        expect(result['sailing_lvl']).to eq(1)
        expect(result['sailing_xp']).to eq(0)

        # Verify helper fields
        expect(result[:members_skill_count]).to eq(9)
        expect(result[:members_levels_sum]).to eq(9)
        
        # CRITICAL: Should NOT be flagged as P2P since all member skills are at base level
        expect(result['potential_p2p']).to eq(0)
      end
    end

    context 'when parsing P2P player with trained Herblore' do
      it 'stores member skill fields and flags as P2P' do
        csv_data = [
          '12345,1350,16000000',   # Overall: 1350 (6 levels more than base)
          '10000,60,300000',       # Attack
          '10001,60,300000',       # Defence
          '10002,60,300000',       # Strength
          '10003,60,300000',       # Hitpoints
          '10004,60,300000',       # Ranged
          '10005,45,60000',        # Prayer
          '10006,55,170000',       # Magic
          '10007,70,800000',       # Cooking
          '10008,60,300000',       # Woodcutting
          '-1,1,0',                # Fletching (P2P, level 1, xp 0)
          '10009,65,450000',       # Fishing
          '10010,50,100000',       # Firemaking
          '10011,40,40000',        # Crafting
          '10012,40,40000',        # Smithing
          '10013,60,300000',       # Mining
          '50000,7,1000',          # Herblore (P2P, TRAINED - level 7, xp 1000)
          '-1,1,0',                # Agility (P2P, level 1, xp 0)
          '-1,1,0',                # Thieving (P2P, level 1, xp 0)
          '-1,1,0',                # Slayer (P2P, level 1, xp 0)
          '-1,1,0',                # Farming (P2P, level 1, xp 0)
          '10014,44,55000',        # Runecraft
          '-1,1,0',                # Hunter (P2P, level 1, xp 0)
          '-1,1,0',                # Construction (P2P, level 1, xp 0)
          '-1,1,0',                # Sailing (P2P, level 1, xp 0)
        ].join("\n")

        result = Hiscores.send(:parse_stats_csv, csv_data)

        # Verify Herblore is properly stored with trained values
        expect(result['herblore_lvl']).to eq(7)
        expect(result['herblore_xp']).to eq(1000)
        expect(result['herblore_rank']).to eq(50000)

        # Verify other member skills are still at base
        expect(result['fletching_lvl']).to eq(1)
        expect(result['fletching_xp']).to eq(0)

        # Should be flagged as P2P due to trained Herblore
        expect(result['potential_p2p']).to eq(1)
      end
    end

    context 'when parsing P2P player with XP but level still 1' do
      it 'flags as P2P based on XP > 0' do
        csv_data = [
          '12345,1344,15000000',   # Overall: 1344
          '10000,60,300000',       # Attack
          '10001,60,300000',       # Defence
          '10002,60,300000',       # Strength
          '10003,60,300000',       # Hitpoints
          '10004,60,300000',       # Ranged
          '10005,45,60000',        # Prayer
          '10006,55,170000',       # Magic
          '10007,70,800000',       # Cooking
          '10008,60,300000',       # Woodcutting
          '-1,1,50',               # Fletching (P2P, level 1 but HAS XP)
          '10009,65,450000',       # Fishing
          '10010,50,100000',       # Firemaking
          '10011,40,40000',        # Crafting
          '10012,40,40000',        # Smithing
          '10013,60,300000',       # Mining
          '-1,1,0',                # Herblore
          '-1,1,0',                # Agility
          '-1,1,0',                # Thieving
          '-1,1,0',                # Slayer
          '-1,1,0',                # Farming
          '10014,44,55000',        # Runecraft
          '-1,1,0',                # Hunter
          '-1,1,0',                # Construction
          '-1,1,0',                # Sailing
        ].join("\n")

        result = Hiscores.send(:parse_stats_csv, csv_data)

        # Verify Fletching has XP even though level is 1
        expect(result['fletching_lvl']).to eq(1)
        expect(result['fletching_xp']).to eq(50)

        # Should be flagged as P2P due to XP > 0
        expect(result['potential_p2p']).to eq(1)
      end
    end

    context 'when parsing maxed F2P player' do
      it 'does not flag as P2P even at total level 1494' do
        csv_data = [
          '1,1494,200000000',      # Overall: 1494 (F2P maximum)
          '1,99,13034431',         # Attack
          '1,99,13034431',         # Defence
          '1,99,13034431',         # Strength
          '1,99,13034431',         # Hitpoints
          '1,99,13034431',         # Ranged
          '1,99,13034431',         # Prayer
          '1,99,13034431',         # Magic
          '1,99,13034431',         # Cooking
          '1,99,13034431',         # Woodcutting
          '-1,1,0',                # Fletching (base)
          '1,99,13034431',         # Fishing
          '1,99,13034431',         # Firemaking
          '1,99,13034431',         # Crafting
          '1,99,13034431',         # Smithing
          '1,99,13034431',         # Mining
          '-1,1,0',                # Herblore (base)
          '-1,1,0',                # Agility (base)
          '-1,1,0',                # Thieving (base)
          '-1,1,0',                # Slayer (base)
          '-1,1,0',                # Farming (base)
          '1,99,13034431',         # Runecraft
          '-1,1,0',                # Hunter (base)
          '-1,1,0',                # Construction (base)
          '-1,1,0',                # Sailing (base)
        ].join("\n")

        result = Hiscores.send(:parse_stats_csv, csv_data)

        # Verify all member skills are at base
        expect(result['fletching_lvl']).to eq(1)
        expect(result['fletching_xp']).to eq(0)
        expect(result['herblore_lvl']).to eq(1)
        expect(result['herblore_xp']).to eq(0)
        expect(result['sailing_lvl']).to eq(1)
        expect(result['sailing_xp']).to eq(0)

        # Should NOT be flagged as P2P
        expect(result['potential_p2p']).to eq(0)
      end
    end
  end

  describe '.parse_stats (JSON parser)' do
    context 'when parsing F2P player from JSON' do
      it 'stores member skill fields and does not flag as P2P' do
        json_data = {
          'skills' => [
            {'name' => 'Overall', 'rank' => 12345, 'level' => 1344, 'xp' => 15000000},
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
            {'name' => 'Sailing', 'rank' => -1, 'level' => 1, 'xp' => 0},
          ]
        }

        result = Hiscores.send(:parse_stats, json_data)

        # Verify member skills are stored
        expect(result['fletching_lvl']).to eq(1)
        expect(result['fletching_xp']).to eq(0)
        expect(result['herblore_lvl']).to eq(1)
        expect(result['herblore_xp']).to eq(0)
        expect(result['sailing_lvl']).to eq(1)
        expect(result['sailing_xp']).to eq(0)

        # Should NOT be flagged as P2P
        expect(result['potential_p2p']).to eq(0)
      end
    end

    context 'when parsing P2P player with trained member skill from JSON' do
      it 'stores member skill and flags as P2P' do
        json_data = {
          'skills' => [
            {'name' => 'Overall', 'rank' => 12345, 'level' => 1350, 'xp' => 16000000},
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
            {'name' => 'Herblore', 'rank' => 50000, 'level' => 7, 'xp' => 1000},
            {'name' => 'Agility', 'rank' => -1, 'level' => 1, 'xp' => 0},
            {'name' => 'Thieving', 'rank' => -1, 'level' => 1, 'xp' => 0},
            {'name' => 'Slayer', 'rank' => -1, 'level' => 1, 'xp' => 0},
            {'name' => 'Farming', 'rank' => -1, 'level' => 1, 'xp' => 0},
            {'name' => 'Runecraft', 'rank' => 10014, 'level' => 44, 'xp' => 55000},
            {'name' => 'Hunter', 'rank' => -1, 'level' => 1, 'xp' => 0},
            {'name' => 'Construction', 'rank' => -1, 'level' => 1, 'xp' => 0},
            {'name' => 'Sailing', 'rank' => -1, 'level' => 1, 'xp' => 0},
          ]
        }

        result = Hiscores.send(:parse_stats, json_data)

        # Verify Herblore is trained
        expect(result['herblore_lvl']).to eq(7)
        expect(result['herblore_xp']).to eq(1000)

        # Should be flagged as P2P
        expect(result['potential_p2p']).to eq(1)
      end
    end
  end
end
