require 'rails_helper'

RSpec.describe Hiscores do
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
            { 'name' => 'Bryophyta', 'rank' => 2001, 'level' => 8, 'xp' => 0 }
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
        
        # Most importantly: potential_p2p should be 0 for unranked P2P skills
        expect(result[:potential_p2p]).to eq(0)
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
            # P2P skill with XP - should be flagged
            { 'name' => 'Fletching', 'rank' => 5000, 'level' => 50, 'xp' => 100000 },
            { 'name' => 'Herblore', 'rank' => -1, 'level' => 1, 'xp' => 0 }
          ]
        }

        result = Hiscores.send(:parse_stats, json_data)

        # Should have P2P XP from Fletching
        expect(result[:potential_p2p]).to eq(100000)
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

        # Sailing stats should be stored for P2P detection
        expect(result['sailing_lvl']).to eq(30)
        expect(result['sailing_xp']).to eq(15000)
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

        # Unranked sailing should still be recorded but shouldn't flag P2P by itself
        expect(result['sailing_lvl']).to eq(1)
        expect(result['sailing_xp']).to eq(0)
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
      expect(url.to_s).to include('index_lite.json')
      expect(url.to_s).to include('player=TestPlayer')
      expect(url.to_s).not_to include('_ironman')
      expect(url.to_s).not_to include('_hardcore')
      expect(url.to_s).not_to include('_ultimate')
    end

    it 'generates correct URL for ironman account' do
      url = Hiscores.send(:api_url, 'IM', 'TestPlayer')
      
      expect(url.to_s).to include('index_lite.json')
      expect(url.to_s).to include('_ironman')
    end

    it 'generates correct URL for hardcore ironman account' do
      url = Hiscores.send(:api_url, 'HCIM', 'TestPlayer')
      
      expect(url.to_s).to include('index_lite.json')
      expect(url.to_s).to include('_hardcore_ironman')
    end

    it 'generates correct URL for ultimate ironman account' do
      url = Hiscores.send(:api_url, 'UIM', 'TestPlayer')
      
      expect(url.to_s).to include('index_lite.json')
      expect(url.to_s).to include('_ultimate')
    end
  end
end
