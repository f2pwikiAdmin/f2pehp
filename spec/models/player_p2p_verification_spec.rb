require 'rails_helper'

RSpec.describe Player, 'P2P verification with direct member skill checks' do
  describe '#detailed_p2p_verification' do
    let(:player) { Player.new(player_name: 'TestPlayer', player_acc_type: 'Reg') }

    context 'when player has all member skills at base level (F2P player)' do
      it 'returns false (not P2P)' do
        stats = {
          "overall_lvl" => 1344,
          "potential_p2p" => 0,
          :f2p_levels_sum => 1302,
          :members_levels_sum => 9,
          :members_skill_count => 9,
          # All member skills at base level
          "fletching_lvl" => 1, "fletching_xp" => 0,
          "herblore_lvl" => 1, "herblore_xp" => 0,
          "agility_lvl" => 1, "agility_xp" => 0,
          "thieving_lvl" => 1, "thieving_xp" => 0,
          "slayer_lvl" => 1, "slayer_xp" => 0,
          "farming_lvl" => 1, "farming_xp" => 0,
          "hunter_lvl" => 1, "hunter_xp" => 0,
          "construction_lvl" => 1, "construction_xp" => 0,
          "sailing_lvl" => 1, "sailing_xp" => 0
        }

        result = player.detailed_p2p_verification(stats)
        expect(result).to be false
      end
    end

    context 'when player has one member skill trained (level > 1)' do
      it 'returns true (is P2P)' do
        stats = {
          "overall_lvl" => 1350,
          "potential_p2p" => 1,
          :f2p_levels_sum => 1302,
          :members_levels_sum => 15,
          :members_skill_count => 9,
          # One member skill trained
          "fletching_lvl" => 1, "fletching_xp" => 0,
          "herblore_lvl" => 7, "herblore_xp" => 1000,  # TRAINED
          "agility_lvl" => 1, "agility_xp" => 0,
          "thieving_lvl" => 1, "thieving_xp" => 0,
          "slayer_lvl" => 1, "slayer_xp" => 0,
          "farming_lvl" => 1, "farming_xp" => 0,
          "hunter_lvl" => 1, "hunter_xp" => 0,
          "construction_lvl" => 1, "construction_xp" => 0,
          "sailing_lvl" => 1, "sailing_xp" => 0
        }

        result = player.detailed_p2p_verification(stats)
        expect(result).to be true
      end
    end

    context 'when player has member skill with xp > 0 but level still 1' do
      it 'returns true (is P2P)' do
        stats = {
          "overall_lvl" => 1344,
          "potential_p2p" => 1,
          :f2p_levels_sum => 1302,
          :members_levels_sum => 9,
          :members_skill_count => 9,
          # One member skill with XP
          "fletching_lvl" => 1, "fletching_xp" => 50,  # Has XP!
          "herblore_lvl" => 1, "herblore_xp" => 0,
          "agility_lvl" => 1, "agility_xp" => 0,
          "thieving_lvl" => 1, "thieving_xp" => 0,
          "slayer_lvl" => 1, "slayer_xp" => 0,
          "farming_lvl" => 1, "farming_xp" => 0,
          "hunter_lvl" => 1, "hunter_xp" => 0,
          "construction_lvl" => 1, "construction_xp" => 0,
          "sailing_lvl" => 1, "sailing_xp" => 0
        }

        result = player.detailed_p2p_verification(stats)
        expect(result).to be true
      end
    end

    context 'when player exceeds F2P max total level' do
      it 'returns true (is P2P)' do
        stats = {
          "overall_lvl" => 1500,  # Exceeds F2P_MAX_TOTAL (1494)
          "potential_p2p" => 0,
          :f2p_levels_sum => 1485,
          :members_levels_sum => 15,
          :members_skill_count => 9,
          # Member skills
          "fletching_lvl" => 1, "fletching_xp" => 0,
          "herblore_lvl" => 7, "herblore_xp" => 1000,
          "agility_lvl" => 1, "agility_xp" => 0,
          "thieving_lvl" => 1, "thieving_xp" => 0,
          "slayer_lvl" => 1, "slayer_xp" => 0,
          "farming_lvl" => 1, "farming_xp" => 0,
          "hunter_lvl" => 1, "hunter_xp" => 0,
          "construction_lvl" => 1, "construction_xp" => 0,
          "sailing_lvl" => 1, "sailing_xp" => 0
        }

        result = player.detailed_p2p_verification(stats)
        expect(result).to be true
      end
    end

    context 'when maxed F2P player at total level 1494' do
      it 'returns false (not P2P)' do
        stats = {
          "overall_lvl" => 1494,  # F2P maximum
          "potential_p2p" => 0,
          :f2p_levels_sum => 1485,
          :members_levels_sum => 9,
          :members_skill_count => 9,
          # All member skills at base
          "fletching_lvl" => 1, "fletching_xp" => 0,
          "herblore_lvl" => 1, "herblore_xp" => 0,
          "agility_lvl" => 1, "agility_xp" => 0,
          "thieving_lvl" => 1, "thieving_xp" => 0,
          "slayer_lvl" => 1, "slayer_xp" => 0,
          "farming_lvl" => 1, "farming_xp" => 0,
          "hunter_lvl" => 1, "hunter_xp" => 0,
          "construction_lvl" => 1, "construction_xp" => 0,
          "sailing_lvl" => 1, "sailing_xp" => 0
        }

        result = player.detailed_p2p_verification(stats)
        expect(result).to be false
      end
    end
  end

  describe '.initial_detailed_p2p_check' do
    context 'when creating F2P player with all member skills at base level' do
      it 'returns false (allow creation)' do
        stats = {
          "overall_lvl" => 1344,
          "potential_p2p" => 0,
          :f2p_levels_sum => 1302,
          :members_levels_sum => 9,
          :members_skill_count => 9,
          # All member skills at base level
          "fletching_lvl" => 1, "fletching_xp" => 0,
          "herblore_lvl" => 1, "herblore_xp" => 0,
          "agility_lvl" => 1, "agility_xp" => 0,
          "thieving_lvl" => 1, "thieving_xp" => 0,
          "slayer_lvl" => 1, "slayer_xp" => 0,
          "farming_lvl" => 1, "farming_xp" => 0,
          "hunter_lvl" => 1, "hunter_xp" => 0,
          "construction_lvl" => 1, "construction_xp" => 0,
          "sailing_lvl" => 1, "sailing_xp" => 0
        }

        result = Player.initial_detailed_p2p_check(stats, 'NewPlayer')
        expect(result).to be false
      end
    end

    context 'when creating P2P player with trained member skill' do
      it 'returns true (reject creation)' do
        stats = {
          "overall_lvl" => 1350,
          "potential_p2p" => 1,
          :f2p_levels_sum => 1302,
          :members_levels_sum => 15,
          :members_skill_count => 9,
          # One member skill trained
          "fletching_lvl" => 1, "fletching_xp" => 0,
          "herblore_lvl" => 7, "herblore_xp" => 1000,  # TRAINED
          "agility_lvl" => 1, "agility_xp" => 0,
          "thieving_lvl" => 1, "thieving_xp" => 0,
          "slayer_lvl" => 1, "slayer_xp" => 0,
          "farming_lvl" => 1, "farming_xp" => 0,
          "hunter_lvl" => 1, "hunter_xp" => 0,
          "construction_lvl" => 1, "construction_xp" => 0,
          "sailing_lvl" => 1, "sailing_xp" => 0
        }

        result = Player.initial_detailed_p2p_check(stats, 'NewPlayer')
        expect(result).to be true
      end
    end
  end

  describe 'MEMBERS_ONLY_SKILLS constant' do
    it 'contains exactly 9 member skills' do
      expect(Player::MEMBERS_ONLY_SKILLS.length).to eq(9)
    end

    it 'includes all expected member skills' do
      expected_skills = %w[fletching herblore agility thieving slayer farming hunter construction sailing]
      expect(Player::MEMBERS_ONLY_SKILLS).to match_array(expected_skills)
    end
  end
end
