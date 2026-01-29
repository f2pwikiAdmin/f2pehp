require 'rails_helper'

RSpec.describe Player, type: :model do
  describe '#update_player with unknown hiscores keys' do
    let(:player) do
      Player.create!(
        player_name: 'TestPlayer',
        player_acc_type: 'Reg',
        overall_xp: 1000000,
        overall_lvl: 500,
        attack_xp: 100000,
        attack_lvl: 50,
        defence_xp: 100000,
        defence_lvl: 50,
        strength_xp: 100000,
        strength_lvl: 50,
        hitpoints_xp: 100000,
        hitpoints_lvl: 50,
        ranged_xp: 100000,
        ranged_lvl: 50,
        prayer_xp: 10000,
        prayer_lvl: 30,
        magic_xp: 100000,
        magic_lvl: 50,
        cooking_xp: 100000,
        cooking_lvl: 50,
        woodcutting_xp: 100000,
        woodcutting_lvl: 50,
        fishing_xp: 100000,
        fishing_lvl: 50,
        firemaking_xp: 100000,
        firemaking_lvl: 50,
        crafting_xp: 100000,
        crafting_lvl: 50,
        smithing_xp: 100000,
        smithing_lvl: 50,
        mining_xp: 100000,
        mining_lvl: 50,
        runecraft_xp: 100000,
        runecraft_lvl: 50
      )
    end

    it 'does not raise error when stats include unknown keys like pvp_arena_rank_score' do
      stats = {
        'overall_xp' => 1100000,
        'overall_lvl' => 510,
        'attack_xp' => 110000,
        'attack_lvl' => 51,
        'potential_p2p' => 0,
        # These keys don't have database columns:
        'pvp_arena_rank_score' => 150,
        'pvp_arena_rank_rank' => 2500,
        'collections_logged_score' => 250,
        'collections_logged_rank' => 1000
      }

      expect {
        player.update_player(stats: stats)
      }.not_to raise_error
      
      # Verify player was updated
      player.reload
      expect(player.overall_xp).to eq(1100000)
      expect(player.overall_lvl).to eq(510)
      
      # Verify extras were stored
      expect(player.hiscores_extras).to be_present
      extras = JSON.parse(player.hiscores_extras)
      expect(extras['pvp_arena_rank_score']).to eq(150)
      expect(extras['pvp_arena_rank_rank']).to eq(2500)
      expect(extras['collections_logged_score']).to eq(250)
      expect(extras['collections_logged_rank']).to eq(1000)
    end

    it 'stores only unknown keys in hiscores_extras, not known attributes' do
      stats = {
        'overall_xp' => 1200000,
        'overall_lvl' => 520,
        'attack_xp' => 120000,
        'potential_p2p' => 0,
        'lms_score' => 500,  # lms_score is a known column
        'pvp_arena_rank_score' => 100,  # This is NOT a known column
      }

      player.update_player(stats: stats)
      player.reload
      
      # Known attribute should be set directly
      expect(player.lms_score).to eq(500)
      
      # Unknown key should be in hiscores_extras
      extras = JSON.parse(player.hiscores_extras)
      expect(extras['pvp_arena_rank_score']).to eq(100)
      expect(extras).not_to have_key('lms_score')
      expect(extras).not_to have_key('overall_xp')
    end
  end
end
