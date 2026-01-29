require 'rails_helper'

RSpec.describe Hiscores, 'Sailing quest detection' do
  describe '.parse_stats_csv' do
    context 'F2P player WITHOUT Sailing quest (Sailing not in API)' do
      it 'correctly parses when Sailing line is missing' do
        # F2P player who hasn't done Sailing quest
        # Total level: 837 (829 F2P + 8 P2P, no Sailing)
        # CSV has only 24 skill lines, activities start at line 24
        csv_data = [
          '12345,837,15000000',    # Overall (line 0)
          '10000,60,300000',       # Attack
          '10001,60,300000',       # Defence
          '10002,60,300000',       # Strength
          '10003,60,300000',       # Hitpoints
          '10004,60,300000',       # Ranged
          '10005,45,60000',        # Prayer
          '10006,55,170000',       # Magic
          '10007,70,800000',       # Cooking
          '10008,60,300000',       # Woodcutting
          '-1,1,0',                # Fletching (P2P)
          '10009,65,450000',       # Fishing
          '10010,50,100000',       # Firemaking
          '10011,40,40000',        # Crafting
          '10012,40,40000',        # Smithing
          '10013,60,300000',       # Mining
          '-1,1,0',                # Herblore (P2P)
          '-1,1,0',                # Agility (P2P)
          '-1,1,0',                # Thieving (P2P)
          '-1,1,0',                # Slayer (P2P)
          '-1,1,0',                # Farming (P2P)
          '10014,44,55000',        # Runecraft
          '-1,1,0',                # Hunter (P2P)
          '-1,1,0',                # Construction (P2P, line 23)
          # NO Sailing line - line 24 is first activity
          '-1,0',                  # Grid Points (line 24)
          '-1,100',                # League Points
        ].join("\n")

        result = Hiscores.send(:parse_stats_csv, csv_data)

        # Verify F2P skills parsed correctly
        expect(result[:f2p_levels_sum]).to eq(829)
        expect(result['overall_lvl']).to eq(837)
        
        # Verify only 8 P2P skills counted (no Sailing)
        expect(result[:members_skill_count]).to eq(8)
        expect(result[:members_levels_sum]).to eq(8)
        
        # Verify the math works out
        expect(result[:f2p_levels_sum] + result[:members_levels_sum]).to eq(result['overall_lvl'])
        
        # Should NOT be flagged as P2P
        expect(result["potential_p2p"]).to eq(0)
      end
    end

    context 'F2P player WITH Sailing quest (Sailing in API)' do
      it 'correctly parses when Sailing line is present' do
        # F2P player who DID the Sailing quest
        # Total level: 838 (829 F2P + 9 P2P including Sailing)
        # CSV has 25 skill lines, activities start at line 25
        csv_data = [
          '12345,838,15000000',    # Overall (line 0)
          '10000,60,300000',       # Attack
          '10001,60,300000',       # Defence
          '10002,60,300000',       # Strength
          '10003,60,300000',       # Hitpoints
          '10004,60,300000',       # Ranged
          '10005,45,60000',        # Prayer
          '10006,55,170000',       # Magic
          '10007,70,800000',       # Cooking
          '10008,60,300000',       # Woodcutting
          '-1,1,0',                # Fletching (P2P)
          '10009,65,450000',       # Fishing
          '10010,50,100000',       # Firemaking
          '10011,40,40000',        # Crafting
          '10012,40,40000',        # Smithing
          '10013,60,300000',       # Mining
          '-1,1,0',                # Herblore (P2P)
          '-1,1,0',                # Agility (P2P)
          '-1,1,0',                # Thieving (P2P)
          '-1,1,0',                # Slayer (P2P)
          '-1,1,0',                # Farming (P2P)
          '10014,44,55000',        # Runecraft
          '-1,1,0',                # Hunter (P2P)
          '-1,1,0',                # Construction (P2P, line 23)
          '-1,1,0',                # Sailing (P2P, line 24)
          '-1,0',                  # Grid Points (line 25)
          '-1,100',                # League Points
        ].join("\n")

        result = Hiscores.send(:parse_stats_csv, csv_data)

        # Verify F2P skills parsed correctly
        expect(result[:f2p_levels_sum]).to eq(829)
        expect(result['overall_lvl']).to eq(838)
        
        # Verify all 9 P2P skills counted (including Sailing)
        expect(result[:members_skill_count]).to eq(9)
        expect(result[:members_levels_sum]).to eq(9)
        
        # Verify the math works out
        expect(result[:f2p_levels_sum] + result[:members_levels_sum]).to eq(result['overall_lvl'])
        
        # Should NOT be flagged as P2P
        expect(result["potential_p2p"]).to eq(0)
      end
    end

    context 'P2P player with trained Sailing' do
      it 'correctly detects P2P when Sailing is trained' do
        csv_data = [
          '12345,868,25000000',    # Overall (trained P2P)
          '10000,60,300000',       # Attack
          '10001,60,300000',       # Defence
          '10002,60,300000',       # Strength
          '10003,60,300000',       # Hitpoints
          '10004,60,300000',       # Ranged
          '10005,45,60000',        # Prayer
          '10006,55,170000',       # Magic
          '10007,70,800000',       # Cooking
          '10008,60,300000',       # Woodcutting
          '-1,1,0',                # Fletching
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
          '5000,30,15000',         # Sailing TRAINED (level 30!)
        ].join("\n")

        result = Hiscores.send(:parse_stats_csv, csv_data)

        # Should be flagged as P2P due to trained Sailing
        expect(result["potential_p2p"]).to eq(1)
        expect(result[:members_skill_count]).to eq(9)
      end
    end
  end
end
