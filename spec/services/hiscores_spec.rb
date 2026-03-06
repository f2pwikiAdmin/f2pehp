require 'rails_helper'

RSpec.describe Hiscores do
  describe '.parse_stats_csv' do
    context 'with valid CSV data' do
      it 'parses F2P player stats correctly' do
        # Mock CSV response for a F2P player
        # Format: rank,level,xp for skills; rank,score for activities
        csv_data = [
          '12345,750,15000000',    # Overall
          '10000,60,300000',       # Attack
          '10001,60,300000',       # Defence
          '10002,60,300000',       # Strength
          '10003,60,300000',       # Hitpoints
          '10004,60,300000',       # Ranged
          '10005,45,60000',        # Prayer
          '10006,55,170000',       # Magic
          '10007,70,800000',       # Cooking
          '10008,60,300000',       # Woodcutting
          '-1,1,0',                # Fletching (P2P, unranked)
          '10009,65,450000',       # Fishing
          '10010,50,100000',       # Firemaking
          '10011,40,40000',        # Crafting
          '10012,40,40000',        # Smithing
          '10013,60,300000',       # Mining
          '-1,1,0',                # Herblore (P2P, unranked)
          '-1,1,0',                # Agility (P2P, unranked)
          '-1,1,0',                # Thieving (P2P, unranked)
          '-1,1,0',                # Slayer (P2P, unranked)
          '-1,1,0',                # Farming (P2P, unranked)
          '10014,44,55000',        # Runecraft
          '-1,1,0',                # Hunter (P2P, unranked)
          '-1,1,0',                # Construction (P2P, unranked)
          '-1,1,0',                # Sailing (unranked)
          # Activities start here (line 35 in CSV, index 0 in activities)
          '-1,0',                  # Grid Points
          '-1,0',                  # League Points
          '-1,0',                  # Deadman Points
          '-1,0',                  # Bounty Hunter - Hunter
          '-1,0',                  # Bounty Hunter - Rogue
          '-1,0',                  # Bounty Hunter (Legacy) - Hunter
          '-1,0',                  # Bounty Hunter (Legacy) - Rogue
          '5000,50',               # Clue Scrolls (all)
          '5001,25',               # Clue Scrolls (beginner)
          '-1,0',                  # Clue Scrolls (easy) - P2P
          '-1,0',                  # Clue Scrolls (medium) - P2P
          '-1,0',                  # Clue Scrolls (hard) - P2P
          '-1,0',                  # Clue Scrolls (elite) - P2P
          '-1,0',                  # Clue Scrolls (master) - P2P
          '3000,500',              # LMS - Rank (index 11)
          '-1,0',                  # PvP Arena - Rank
          '-1,0',                  # Soul Wars Zeal
          '-1,0',                  # Rifts closed
          '-1,0',                  # Colosseum Glory
          '-1,0',                  # Abyssal Sire
          '-1,0',                  # Alchemical Hydra
          '-1,0',                  # Artio
          '-1,0',                  # Barrows Chests
          '-1,0',                  # Callisto
          '-1,0',                  # Calvar'ion
          '-1,0',                  # Cerberus
          '204782,41',             # Brutus (activity index 26 - F2P boss)
          '2001,8',                # Bryophyta (activity index 27 - F2P boss)
          '-1,0',                  # Chambers of Xeric
          '-1,0',                  # Chambers of Xeric: Challenge Mode
          '-1,0',                  # Chaos Elemental
          '-1,0',                  # Chaos Fanatic
          '-1,0',                  # Commander Zilyana
          '-1,0',                  # Corporeal Beast
          '-1,0',                  # Crazy Archaeologist
          '-1,0',                  # Dagannoth Prime
          '-1,0',                  # Dagannoth Rex
          '-1,0',                  # Dagannoth Supreme
          '-1,0',                  # Deranged Archaeologist
          '-1,0',                  # Duke Sucellus
          '-1,0',                  # General Graardor
          '-1,0',                  # Giant Mole
          '-1,0',                  # Grotesque Guardians
          '-1,0',                  # Hespori
          '-1,0',                  # Kalphite Queen
          '-1,0',                  # King Black Dragon
          '-1,0',                  # Kraken
          '-1,0',                  # Kree'Arra
          '-1,0',                  # K'ril Tsutsaroth
          '-1,0',                  # Lunar Chests
          '-1,0',                  # Mimic
          '-1,0',                  # Nex
          '-1,0',                  # Nightmare
          '-1,0',                  # Phosani's Nightmare
          '-1,0',                  # Phantom Muspah
          '-1,0',                  # Sarachnis
          '-1,0',                  # Scorpia
          '-1,0',                  # Scurrius
          '2000,10',               # Obor (activity index 56 - F2P boss)
          '-1,0',                  # Skotizo
          '-1,0',                  # Sol Heredit
          '-1,0',                  # Spindel
          '-1,0',                  # Tempoross
          '-1,0',                  # The Gauntlet
          '-1,0',                  # The Corrupted Gauntlet
          '-1,0',                  # The Leviathan
          '-1,0',                  # The Whisperer
          '-1,0',                  # Theatre of Blood
          '-1,0',                  # Theatre of Blood: Hard Mode
          '-1,0',                  # Thermy
          '-1,0',                  # Tombs of Amascut
          '-1,0',                  # Tombs of Amascut: Expert Mode
          '-1,0',                  # TzKal-Zuk
          '-1,0',                  # TzTok-Jad
          '-1,0',                  # Vardorvis
          '-1,0',                  # Venenatis
          '-1,0',                  # Vet'ion
          '-1,0',                  # Vorkath
          '-1,0',                  # Wintertodt
          '-1,0',                  # Zalcano
          '-1,0',                  # Zulrah
        ].join("\n")

        result = Hiscores.send(:parse_stats_csv, csv_data)

        # Check F2P skills are parsed
        expect(result['attack_lvl']).to eq(60)
        expect(result['attack_xp']).to eq(300000)
        expect(result['attack_rank']).to eq(10000)
        
        expect(result['overall_lvl']).to eq(750)
        expect(result['overall_xp']).to eq(15000000)
        
        # Check hitpoints has values
        expect(result['hitpoints_lvl']).to eq(60)
        expect(result['hitpoints_xp']).to eq(300000)
        
        # Check minigames
        expect(result['clues_all']).to eq(50)
        expect(result['clues_all_rank']).to eq(5000)
        expect(result['clues_beginner']).to eq(25)
        expect(result[:lms_score]).to eq(500)
        expect(result[:obor_kc]).to eq(10)
        expect(result[:bryo_kc]).to eq(8)
        expect(result[:brutus_kc]).to eq(41)
        
        # Most importantly: potential_p2p should be 0 for unranked P2P skills
        expect(result["potential_p2p"]).to eq(0)
      end

      it 'detects P2P player with trained P2P skills' do
        csv_data = [
          '12345,850,20000000',    # Overall
          '10000,60,300000',       # Attack
          '10001,60,300000',       # Defence
          '10002,60,300000',       # Strength
          '10003,60,300000',       # Hitpoints
          '10004,60,300000',       # Ranged
          '10005,45,60000',        # Prayer
          '10006,55,170000',       # Magic
          '10007,70,800000',       # Cooking
          '10008,60,300000',       # Woodcutting
          '5000,50,100000',        # Fletching (P2P with level 50 - should be flagged!)
          '10009,65,450000',       # Fishing
          '10010,50,100000',       # Firemaking
          '10011,40,40000',        # Crafting
          '10012,40,40000',        # Smithing
          '10013,60,300000',       # Mining
          '-1,1,0',                # Herblore
        ].join("\n")

        result = Hiscores.send(:parse_stats_csv, csv_data)

        # Should flag as P2P (value = 1) when Fletching has level 50
        expect(result["potential_p2p"]).to eq(1)
      end

      it 'detects sailing as P2P indicator' do
        csv_data = [
          '12345,750,15000000',    # Overall
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
          '1000,30,15000',         # Sailing - with level 30! (P2P skill)
        ].join("\n")

        result = Hiscores.send(:parse_stats_csv, csv_data)

        # Sailing level should flag as P2P (value = 1) when detected
        expect(result["potential_p2p"]).to eq(1)
      end

      it 'handles unranked sailing correctly' do
        csv_data = [
          '12345,750,15000000',    # Overall
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
          '-1,1,0',                # Sailing - unranked (P2P skill)
        ].join("\n")

        result = Hiscores.send(:parse_stats_csv, csv_data)

        # Unranked sailing should not contribute to P2P detection
        expect(result["potential_p2p"]).to eq(0)
      end
      
      # Test for temporary mitigation: activity-based P2P detection disabled
      it 'does not flag F2P player as P2P based on P2P activities (mitigation)' do
        # F2P player with simulated misaligned P2P boss KCs/clues that would have
        # caused false positives in unstable CSV parsing
        csv_data = [
          '12345,750,15000000',    # Overall
          '10000,60,300000',       # Attack
          '10001,60,300000',       # Defence
          '10002,60,300000',       # Strength
          '10003,60,300000',       # Hitpoints
          '10004,60,300000',       # Ranged
          '10005,45,60000',        # Prayer
          '10006,55,170000',       # Magic
          '10007,70,800000',       # Cooking
          '10008,60,300000',       # Woodcutting
          '-1,1,0',                # Fletching (P2P, unranked)
          '10009,65,450000',       # Fishing
          '10010,50,100000',       # Firemaking
          '10011,40,40000',        # Crafting
          '10012,40,40000',        # Smithing
          '10013,60,300000',       # Mining
          '-1,1,0',                # Herblore (P2P, unranked)
          '-1,1,0',                # Agility (P2P, unranked)
          '-1,1,0',                # Thieving (P2P, unranked)
          '-1,1,0',                # Slayer (P2P, unranked)
          '-1,1,0',                # Farming (P2P, unranked)
          '10014,44,55000',        # Runecraft
          '-1,1,0',                # Hunter (P2P, unranked)
          '-1,1,0',                # Construction (P2P, unranked)
          '-1,1,0',                # Sailing (unranked)
          # Activities - simulate misaligned/unstable data that could cause false positives
          '-1,0',                  # Grid Points
          '-1,0',                  # League Points
          '-1,0',                  # Deadman Points
          '-1,0',                  # Bounty Hunter - Hunter
          '-1,0',                  # Bounty Hunter - Rogue
          '-1,0',                  # Bounty Hunter (Legacy) - Hunter
          '-1,0',                  # Bounty Hunter (Legacy) - Rogue
          '5000,50',               # Clue Scrolls (all)
          '5001,25',               # Clue Scrolls (beginner)
          '100,10',                # Clue Scrolls (easy) - P2P clue (would have flagged before)
          '100,5',                 # Clue Scrolls (medium) - P2P clue
          '-1,0',                  # Clue Scrolls (hard)
          '-1,0',                  # Clue Scrolls (elite)
          '-1,0',                  # Clue Scrolls (master)
          '3000,500',              # LMS - Rank
          '-1,0',                  # PvP Arena - Rank
          '-1,0',                  # Soul Wars Zeal - P2P
          '-1,0',                  # Rifts closed
          '-1,0',                  # Colosseum Glory
          '-1,0',                  # Collections Logged
          '-1,0',                  # Abyssal Sire
          '-1,0',                  # Alchemical Hydra
          '-1,0',                  # Amoxliatl
          '-1,0',                  # Araxxor
          '-1,0',                  # Artio
          '200,50',                # Barrows Chests - P2P boss (would have flagged before)
          '-1,0',                  # Brutus (F2P boss)
          '2001,8',                # Bryophyta (F2P boss)
          '-1,0',                  # Callisto
          '-1,0',                  # Calvar'ion
          '-1,0',                  # Cerberus
          '-1,0',                  # Chambers of Xeric
          '-1,0',                  # Chambers of Xeric: Challenge Mode
          '-1,0',                  # Chaos Elemental
          '-1,0',                  # Chaos Fanatic
          '-1,0',                  # Commander Zilyana
          '-1,0',                  # Corporeal Beast
          '-1,0',                  # Crazy Archaeologist
          '-1,0',                  # Dagannoth Prime
          '-1,0',                  # Dagannoth Rex
          '-1,0',                  # Dagannoth Supreme
          '-1,0',                  # Deranged Archaeologist
          '-1,0',                  # Doom of Mokhaiotl
          '-1,0',                  # Duke Sucellus
          '-1,0',                  # General Graardor
          '-1,0',                  # Giant Mole
          '-1,0',                  # Grotesque Guardians
          '-1,0',                  # Hespori
          '-1,0',                  # Kalphite Queen
          '-1,0',                  # King Black Dragon
          '-1,0',                  # Kraken
          '-1,0',                  # Kree'Arra
          '-1,0',                  # K'ril Tsutsaroth
          '-1,0',                  # Lunar Chests
          '-1,0',                  # Mimic
          '-1,0',                  # Nex
          '-1,0',                  # Nightmare
          '-1,0',                  # Phosani's Nightmare
          '2000,10',               # Obor (F2P boss)
          '-1,0',                  # Phantom Muspah
          '-1,0',                  # Sarachnis
          '-1,0',                  # Scorpia
          '-1,0',                  # Scurrius
          '-1,0',                  # Shellbane Gryphon
          '-1,0',                  # Skotizo
          '-1,0',                  # Sol Heredit
          '-1,0',                  # Spindel
          '-1,0',                  # Tempoross
          '-1,0',                  # The Gauntlet
          '-1,0',                  # The Corrupted Gauntlet
          '-1,0',                  # The Hueycoatl
          '-1,0',                  # The Leviathan
          '-1,0',                  # The Royal Titans
          '-1,0',                  # The Whisperer
          '-1,0',                  # Theatre of Blood
          '-1,0',                  # Theatre of Blood: Hard Mode
          '-1,0',                  # Thermy
          '-1,0',                  # Tombs of Amascut
          '-1,0',                  # Tombs of Amascut: Expert Mode
          '-1,0',                  # TzKal-Zuk
          '-1,0',                  # TzTok-Jad
          '-1,0',                  # Vardorvis
          '-1,0',                  # Venenatis
          '-1,0',                  # Vet'ion
          '-1,0',                  # Vorkath
          '-1,0',                  # Wintertodt
          '-1,0',                  # Yama
          '-1,0',                  # Zalcano
          '300,100',               # Zulrah - P2P boss (would have flagged before)
        ].join("\n")

        result = Hiscores.send(:parse_stats_csv, csv_data)

        # TEMPORARY MITIGATION: Activity-based P2P detection is disabled
        # Player should NOT be flagged as P2P even with P2P boss KC and clues
        # Only skills-based detection is used
        expect(result["potential_p2p"]).to eq(0)
        
        # Activities should still be parsed and stored (for future use)
        expect(result[:obor_kc]).to eq(10)
        expect(result[:bryo_kc]).to eq(8)
        expect(result[:brutus_kc]).to eq(0)
        expect(result[:lms_score]).to eq(500)
      end
    end

    context 'with invalid CSV data' do
      it 'returns false when data is nil' do
        result = Hiscores.send(:parse_stats_csv, nil)
        expect(result).to eq(false)
      end

      it 'returns false when data is empty string' do
        result = Hiscores.send(:parse_stats_csv, '')
        expect(result).to eq(false)
      end

      it 'returns false when data is not a string' do
        result = Hiscores.send(:parse_stats_csv, 12345)
        expect(result).to eq(false)
      end
    end
  end

  # Keep the old parse_stats tests for backward compatibility
  describe '.parse_stats' do
    context 'with valid JSON data' do
      it 'parses F2P player stats correctly' do
        # Mock JSON response for a F2P player
        json_data = {
          'skills' => [
            { 'name' => 'Overall', 'rank' => 12345, 'level' => 750, 'xp' => 15000000 },
            { 'name' => 'Attack', 'rank' => 10000, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Defence', 'rank' => 10001, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Strength', 'rank' => 10002, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Hitpoints', 'rank' => 10003, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Ranged', 'rank' => 10004, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Prayer', 'rank' => 10005, 'level' => 45, 'xp' => 60000 },
            { 'name' => 'Magic', 'rank' => 10006, 'level' => 55, 'xp' => 170000 },
            { 'name' => 'Cooking', 'rank' => 10007, 'level' => 70, 'xp' => 800000 },
            { 'name' => 'Woodcutting', 'rank' => 10008, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Fishing', 'rank' => 10009, 'level' => 65, 'xp' => 450000 },
            { 'name' => 'Firemaking', 'rank' => 10010, 'level' => 50, 'xp' => 100000 },
            { 'name' => 'Crafting', 'rank' => 10011, 'level' => 40, 'xp' => 40000 },
            { 'name' => 'Smithing', 'rank' => 10012, 'level' => 40, 'xp' => 40000 },
            { 'name' => 'Mining', 'rank' => 10013, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Runecraft', 'rank' => 10014, 'level' => 44, 'xp' => 55000 },
            # P2P skills - unranked (rank=-1, level=1, xp=0)
            { 'name' => 'Fletching', 'rank' => -1, 'level' => 1, 'xp' => 0 },
            { 'name' => 'Herblore', 'rank' => -1, 'level' => 1, 'xp' => 0 },
            { 'name' => 'Agility', 'rank' => -1, 'level' => 1, 'xp' => 0 },
            { 'name' => 'Thieving', 'rank' => -1, 'level' => 1, 'xp' => 0 },
            { 'name' => 'Slayer', 'rank' => -1, 'level' => 1, 'xp' => 0 },
            { 'name' => 'Farming', 'rank' => -1, 'level' => 1, 'xp' => 0 },
            { 'name' => 'Hunter', 'rank' => -1, 'level' => 1, 'xp' => 0 },
            { 'name' => 'Construction', 'rank' => -1, 'level' => 1, 'xp' => 0 },
            # Minigames
            { 'name' => 'Clue Scrolls (all)', 'rank' => 5000, 'level' => 50, 'xp' => 0 },
            { 'name' => 'Clue Scrolls (beginner)', 'rank' => 5001, 'level' => 25, 'xp' => 0 },
            { 'name' => 'LMS - Rank', 'rank' => 3000, 'level' => 500, 'xp' => 0 },
            { 'name' => 'Obor', 'rank' => 2000, 'level' => 10, 'xp' => 0 },
            { 'name' => 'Bryophyta', 'rank' => 2001, 'level' => 8, 'xp' => 0 },
            { 'name' => 'Brutus', 'rank' => 204782, 'level' => 41, 'xp' => 0 }
          ]
        }

        result = Hiscores.send(:parse_stats, json_data)

        # Check F2P skills are parsed
        expect(result['attack_lvl']).to eq(60)
        expect(result['attack_xp']).to eq(300000)
        expect(result['attack_rank']).to eq(10000)
        
        expect(result['overall_lvl']).to eq(750)
        expect(result['overall_xp']).to eq(15000000)
        
        # Check hitpoints has minimum values
        expect(result['hitpoints_lvl']).to eq(60)
        expect(result['hitpoints_xp']).to eq(300000)
        
        # Check minigames
        expect(result['clues_all']).to eq(50)
        expect(result['clues_all_rank']).to eq(5000)
        expect(result['clues_beginner']).to eq(25)
        expect(result[:lms_score]).to eq(500)
        expect(result[:obor_kc]).to eq(10)
        expect(result[:bryo_kc]).to eq(8)
        expect(result[:brutus_kc]).to eq(41)
        
        # Most importantly: potential_p2p should be 0 for unranked P2P skills
        expect(result["potential_p2p"]).to eq(0)
      end

      it 'detects P2P player with trained P2P skills' do
        json_data = {
          'skills' => [
            { 'name' => 'Overall', 'rank' => 12345, 'level' => 850, 'xp' => 20000000 },
            { 'name' => 'Attack', 'rank' => 10000, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Defence', 'rank' => 10001, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Strength', 'rank' => 10002, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Hitpoints', 'rank' => 10003, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Ranged', 'rank' => 10004, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Prayer', 'rank' => 10005, 'level' => 45, 'xp' => 60000 },
            { 'name' => 'Magic', 'rank' => 10006, 'level' => 55, 'xp' => 170000 },
            { 'name' => 'Cooking', 'rank' => 10007, 'level' => 70, 'xp' => 800000 },
            { 'name' => 'Woodcutting', 'rank' => 10008, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Fishing', 'rank' => 10009, 'level' => 65, 'xp' => 450000 },
            { 'name' => 'Firemaking', 'rank' => 10010, 'level' => 50, 'xp' => 100000 },
            { 'name' => 'Crafting', 'rank' => 10011, 'level' => 40, 'xp' => 40000 },
            { 'name' => 'Smithing', 'rank' => 10012, 'level' => 40, 'xp' => 40000 },
            { 'name' => 'Mining', 'rank' => 10013, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Runecraft', 'rank' => 10014, 'level' => 44, 'xp' => 55000 },
            # P2P skill with level 50 - should be flagged
            { 'name' => 'Fletching', 'rank' => 5000, 'level' => 50, 'xp' => 100000 },
            { 'name' => 'Herblore', 'rank' => -1, 'level' => 1, 'xp' => 0 }
          ]
        }

        result = Hiscores.send(:parse_stats, json_data)

        # Should flag as P2P (value = 1) when Fletching has level 50
        expect(result["potential_p2p"]).to eq(1)
      end

      it 'detects sailing as P2P indicator' do
        json_data = {
          'skills' => [
            { 'name' => 'Overall', 'rank' => 12345, 'level' => 750, 'xp' => 15000000 },
            { 'name' => 'Attack', 'rank' => 10000, 'level' => 60, 'xp' => 300000 },
            # Other F2P skills...
            { 'name' => 'Sailing', 'rank' => 1000, 'level' => 30, 'xp' => 15000 }
          ]
        }

        result = Hiscores.send(:parse_stats, json_data)

        # Sailing level should flag as P2P (value = 1) when detected
        expect(result["potential_p2p"]).to eq(1)
      end

      it 'handles unranked sailing correctly' do
        json_data = {
          'skills' => [
            { 'name' => 'Overall', 'rank' => 12345, 'level' => 750, 'xp' => 15000000 },
            { 'name' => 'Attack', 'rank' => 10000, 'level' => 60, 'xp' => 300000 },
            # Sailing unranked
            { 'name' => 'Sailing', 'rank' => -1, 'level' => 1, 'xp' => 0 }
          ]
        }

        result = Hiscores.send(:parse_stats, json_data)

        # Unranked sailing at level 1 with 0 XP should NOT flag as P2P
        # The condition `lvl > 1 || xp > 0` evaluates to false for this case
        expect(result["potential_p2p"]).to eq(0)
      end

      it 'does not flag P2P for ranked minigames without score' do
        # This is the bug we're fixing: ranked P2P minigames without a "level" field
        # (which defaults to 1) should NOT flag as P2P unless they have a score
        json_data = {
          'skills' => [
            { 'name' => 'Overall', 'rank' => 12345, 'level' => 750, 'xp' => 15000000 },
            { 'name' => 'Attack', 'rank' => 10000, 'level' => 60, 'xp' => 300000 },
            # P2P minigames that are ranked but have no score/level field (no actual activity)
            { 'name' => 'Barrows Chests', 'rank' => 50000 },  # Missing score, level, xp
            { 'name' => 'Chambers of Xeric', 'rank' => 40000, 'score' => 0 }  # Ranked but zero score
          ]
        }

        result = Hiscores.send(:parse_stats, json_data)

        # Should NOT flag as P2P since there's no actual score/activity
        expect(result["potential_p2p"]).to eq(0)
      end

      # TEMPORARY MITIGATION: Activity-based P2P detection is disabled
      # This test now verifies that P2P activities do NOT flag players
      it 'does not flag P2P for minigames with actual scores (mitigation)' do
        # Minigames with real scores should NOT flag as P2P due to mitigation
        json_data = {
          'skills' => [
            { 'name' => 'Overall', 'rank' => 12345, 'level' => 750, 'xp' => 15000000 },
            { 'name' => 'Attack', 'rank' => 10000, 'level' => 60, 'xp' => 300000 },
            # P2P minigames with actual scores (would have flagged before mitigation)
            { 'name' => 'Barrows Chests', 'rank' => 5000, 'score' => 150 },
            { 'name' => 'Chambers of Xeric', 'rank' => 3000, 'score' => 25 }
          ]
        }

        result = Hiscores.send(:parse_stats, json_data)

        # TEMPORARY MITIGATION: Should NOT flag as P2P (activities disabled)
        expect(result["potential_p2p"]).to eq(0)
      end

      it 'handles P2P minigames with missing score field correctly' do
        # When score field is completely missing, should default to 0
        json_data = {
          'skills' => [
            { 'name' => 'Overall', 'rank' => 12345, 'level' => 750, 'xp' => 15000000 },
            { 'name' => 'Attack', 'rank' => 10000, 'level' => 60, 'xp' => 300000 },
            # P2P minigame without score field but with level field (edge case)
            { 'name' => 'TzTok-Jad', 'rank' => 10000, 'level' => 1 }  # No score field
          ]
        }

        result = Hiscores.send(:parse_stats, json_data)

        # Should NOT flag as P2P since score defaults to 0
        expect(result["potential_p2p"]).to eq(0)
      end

      # TEMPORARY MITIGATION: Activity-based P2P detection is disabled
      # This test now verifies that P2P activities do NOT flag players
      it 'does not flag P2P for unranked minigames with positive scores (mitigation)' do
        # Even unranked minigames with scores should NOT flag as P2P due to mitigation
        json_data = {
          'skills' => [
            { 'name' => 'Overall', 'rank' => 12345, 'level' => 750, 'xp' => 15000000 },
            { 'name' => 'Attack', 'rank' => 10000, 'level' => 60, 'xp' => 300000 },
            # Unranked but with score (would have flagged before mitigation)
            { 'name' => 'Giant Mole', 'rank' => -1, 'score' => 5 }
          ]
        }

        result = Hiscores.send(:parse_stats, json_data)

        # TEMPORARY MITIGATION: Should NOT flag as P2P (activities disabled)
        expect(result["potential_p2p"]).to eq(0)
      end
    end

    context 'with invalid JSON data' do
      it 'returns false when skills array is missing' do
        json_data = { 'other_key' => 'value' }
        
        result = Hiscores.send(:parse_stats, json_data)
        
        expect(result).to eq(false)
      end

      it 'returns false when data is nil' do
        result = Hiscores.send(:parse_stats, nil)
        
        expect(result).to eq(false)
      end

      it 'returns false when skills is not an array' do
        json_data = { 'skills' => 'not_an_array' }
        
        result = Hiscores.send(:parse_stats, json_data)
        
        expect(result).to eq(false)
      end
    end

    context 'with restrict_fields parameter' do
      it 'only parses specified fields' do
        json_data = {
          'skills' => [
            { 'name' => 'Overall', 'rank' => 12345, 'level' => 750, 'xp' => 15000000 },
            { 'name' => 'Attack', 'rank' => 10000, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Defence', 'rank' => 10001, 'level' => 60, 'xp' => 300000 }
          ]
        }

        result = Hiscores.send(:parse_stats, json_data, ['attack'])

        # Should have attack
        expect(result['attack_lvl']).to eq(60)
        
        # Should not have defence
        expect(result['defence_lvl']).to be_nil
      end
    end

    context 'resilience to API changes' do
      it 'handles skills in different order than expected' do
        # Skills deliberately out of alphabetical or traditional order
        json_data = {
          'skills' => [
            { 'name' => 'Mining', 'rank' => 10013, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Attack', 'rank' => 10000, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Overall', 'rank' => 12345, 'level' => 750, 'xp' => 15000000 },
            { 'name' => 'Defence', 'rank' => 10001, 'level' => 60, 'xp' => 300000 }
          ]
        }

        result = Hiscores.send(:parse_stats, json_data)

        # All skills should be parsed correctly regardless of order
        expect(result['attack_lvl']).to eq(60)
        expect(result['defence_lvl']).to eq(60)
        expect(result['mining_lvl']).to eq(60)
        expect(result['overall_lvl']).to eq(750)
      end

      it 'gracefully ignores unknown/unmapped skills' do
        json_data = {
          'skills' => [
            { 'name' => 'Overall', 'rank' => 12345, 'level' => 750, 'xp' => 15000000 },
            { 'name' => 'Attack', 'rank' => 10000, 'level' => 60, 'xp' => 300000 },
            # Hypothetical future skill that doesn't exist yet
            { 'name' => 'Future Skill', 'rank' => 5000, 'level' => 50, 'xp' => 100000 },
            { 'name' => 'Defence', 'rank' => 10001, 'level' => 60, 'xp' => 300000 }
          ]
        }

        result = Hiscores.send(:parse_stats, json_data)

        # Should parse known skills without error
        expect(result['attack_lvl']).to eq(60)
        expect(result['defence_lvl']).to eq(60)
        expect(result['overall_lvl']).to eq(750)
        
        # Unknown skill should be ignored (not cause error)
        expect(result).not_to have_key('future_skill_lvl')
      end

      it 'handles missing skill data fields with defaults' do
        json_data = {
          'skills' => [
            { 'name' => 'Attack' },  # Missing rank, level, xp
            { 'name' => 'Defence', 'rank' => 10001 },  # Missing level, xp
            { 'name' => 'Strength', 'rank' => 10002, 'level' => 60 }  # Missing xp
          ]
        }

        result = Hiscores.send(:parse_stats, json_data)

        # Should use defaults for missing fields
        expect(result['attack_lvl']).to eq(1)  # default level
        expect(result['attack_xp']).to eq(0)   # default xp
        expect(result['attack_rank']).to eq(-1)  # default rank
        
        expect(result['defence_lvl']).to eq(1)
        expect(result['defence_xp']).to eq(0)
        
        expect(result['strength_xp']).to eq(0)
      end
    end
  end

  describe '.api_url' do
    it 'generates correct URL for regular account' do
      url = Hiscores.send(:api_url, 'Reg', 'TestPlayer')
      
      expect(url.to_s).to include('secure.runescape.com')
      expect(url.to_s).to include('index_lite.ws')
      expect(url.to_s).to include('player=TestPlayer')
      expect(url.to_s).not_to include('_ironman')
      expect(url.to_s).not_to include('_hardcore')
      expect(url.to_s).not_to include('_ultimate')
    end

    it 'generates correct URL for ironman account' do
      url = Hiscores.send(:api_url, 'IM', 'TestPlayer')
      
      expect(url.to_s).to include('index_lite.ws')
      expect(url.to_s).to include('_ironman')
    end

    it 'generates correct URL for hardcore ironman account' do
      url = Hiscores.send(:api_url, 'HCIM', 'TestPlayer')
      
      expect(url.to_s).to include('index_lite.ws')
      expect(url.to_s).to include('_hardcore_ironman')
    end

    it 'generates correct URL for ultimate ironman account' do
      url = Hiscores.send(:api_url, 'UIM', 'TestPlayer')
      
      expect(url.to_s).to include('index_lite.ws')
      expect(url.to_s).to include('_ultimate')
    end
  end

  describe 'PR #87 - PvP Arena and Collections Logged F2P handling' do
    context 'CSV parsing' do
      it 'does NOT flag F2P players with PvP Arena rank as P2P' do
        csv_data = [
          '12345,750,15000000',    # Overall
          '10000,60,300000',       # Attack
          '10001,60,300000',       # Defence
          '10002,60,300000',       # Strength
          '10003,60,300000',       # Hitpoints
          '10004,60,300000',       # Ranged
          '10005,45,60000',        # Prayer
          '10006,55,170000',       # Magic
          '10007,70,800000',       # Cooking
          '10008,60,300000',       # Woodcutting
          '-1,1,0',                # Fletching (P2P, unranked)
          '10009,65,450000',       # Fishing
          '10010,50,100000',       # Firemaking
          '10011,40,40000',        # Crafting
          '10012,40,40000',        # Smithing
          '10013,60,300000',       # Mining
          '-1,1,0',                # Herblore (P2P, unranked)
          '-1,1,0',                # Agility (P2P, unranked)
          '-1,1,0',                # Thieving (P2P, unranked)
          '-1,1,0',                # Slayer (P2P, unranked)
          '-1,1,0',                # Farming (P2P, unranked)
          '10014,44,55000',        # Runecraft
          '-1,1,0',                # Hunter (P2P, unranked)
          '-1,1,0',                # Construction (P2P, unranked)
          '-1,1,0',                # Sailing (unranked)
          # Activities start here
          '-1,0',                  # Grid Points
          '-1,0',                  # League Points
          '-1,0',                  # Deadman Points
          '-1,0',                  # Bounty Hunter - Hunter
          '-1,0',                  # Bounty Hunter - Rogue
          '-1,0',                  # Bounty Hunter (Legacy) - Hunter
          '-1,0',                  # Bounty Hunter (Legacy) - Rogue
          '5000,50',               # Clue Scrolls (all)
          '5001,25',               # Clue Scrolls (beginner)
          '-1,0',                  # Clue Scrolls (easy) - P2P
          '-1,0',                  # Clue Scrolls (medium) - P2P
          '-1,0',                  # Clue Scrolls (hard) - P2P
          '-1,0',                  # Clue Scrolls (elite) - P2P
          '-1,0',                  # Clue Scrolls (master) - P2P
          '3000,500',              # LMS - Rank (F2P)
          '2500,150',              # PvP Arena - Rank (F2P, has rank 150!)
          '-1,0',                  # Soul Wars Zeal
          '-1,0',                  # Rifts closed
          '-1,0',                  # Colosseum Glory
          '1000,250',              # Collections Logged (F2P, has 250 collection log!)
        ].join("\n")

        result = Hiscores.send(:parse_stats_csv, csv_data)

        # Should NOT flag as P2P despite having PvP Arena rank and Collections Logged
        expect(result["potential_p2p"]).to eq(0)
        
        # Should store the values properly
        expect(result[:pvp_arena_rank_score]).to eq(150)
        expect(result[:pvp_arena_rank_rank]).to eq(2500)
        expect(result[:collections_logged_score]).to eq(250)
        expect(result[:collections_logged_rank]).to eq(1000)
      end
    end

    context 'JSON parsing' do
      it 'does NOT flag F2P players with PvP Arena rank as P2P' do
        json_data = {
          'skills' => [
            { 'name' => 'Overall', 'rank' => 12345, 'level' => 750, 'xp' => 15000000 },
            { 'name' => 'Attack', 'rank' => 10000, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Defence', 'rank' => 10001, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Strength', 'rank' => 10002, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Hitpoints', 'rank' => 10003, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Ranged', 'rank' => 10004, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Prayer', 'rank' => 10005, 'level' => 45, 'xp' => 60000 },
            { 'name' => 'Magic', 'rank' => 10006, 'level' => 55, 'xp' => 170000 },
            { 'name' => 'Cooking', 'rank' => 10007, 'level' => 70, 'xp' => 800000 },
            { 'name' => 'Woodcutting', 'rank' => 10008, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Fishing', 'rank' => 10009, 'level' => 65, 'xp' => 450000 },
            { 'name' => 'Firemaking', 'rank' => 10010, 'level' => 50, 'xp' => 100000 },
            { 'name' => 'Crafting', 'rank' => 10011, 'level' => 40, 'xp' => 40000 },
            { 'name' => 'Smithing', 'rank' => 10012, 'level' => 40, 'xp' => 40000 },
            { 'name' => 'Mining', 'rank' => 10013, 'level' => 60, 'xp' => 300000 },
            { 'name' => 'Runecraft', 'rank' => 10014, 'level' => 44, 'xp' => 55000 },
            # P2P skills - unranked (rank=-1, level=1, xp=0)
            { 'name' => 'Fletching', 'rank' => -1, 'level' => 1, 'xp' => 0 },
            { 'name' => 'Herblore', 'rank' => -1, 'level' => 1, 'xp' => 0 },
            { 'name' => 'Agility', 'rank' => -1, 'level' => 1, 'xp' => 0 },
            { 'name' => 'Thieving', 'rank' => -1, 'level' => 1, 'xp' => 0 },
            { 'name' => 'Slayer', 'rank' => -1, 'level' => 1, 'xp' => 0 },
            { 'name' => 'Farming', 'rank' => -1, 'level' => 1, 'xp' => 0 },
            { 'name' => 'Hunter', 'rank' => -1, 'level' => 1, 'xp' => 0 },
            { 'name' => 'Construction', 'rank' => -1, 'level' => 1, 'xp' => 0 },
            # Minigames
            { 'name' => 'Clue Scrolls (all)', 'rank' => 5000, 'score' => 50 },
            { 'name' => 'Clue Scrolls (beginner)', 'rank' => 5001, 'score' => 25 },
            { 'name' => 'LMS - Rank', 'rank' => 3000, 'score' => 500 },
            { 'name' => 'PvP Arena - Rank', 'rank' => 2500, 'score' => 150 },
            { 'name' => 'Collections Logged', 'rank' => 1000, 'score' => 250 },
            { 'name' => 'Obor', 'rank' => 2000, 'score' => 10 },
            { 'name' => 'Bryophyta', 'rank' => 2001, 'score' => 8 }
          ]
        }

        result = Hiscores.send(:parse_stats, json_data)

        # Should NOT flag as P2P despite having PvP Arena rank and Collections Logged
        expect(result["potential_p2p"]).to eq(0)
        
        # Should store the values properly
        expect(result[:pvp_arena_rank_score]).to eq(150)
        expect(result[:pvp_arena_rank_rank]).to eq(2500)
        expect(result[:collections_logged_score]).to eq(250)
        expect(result[:collections_logged_rank]).to eq(1000)
      end
    end
  end
end
