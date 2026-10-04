require 'rails_helper'

RSpec.describe ClansController, type: :controller do
  actions = {
    add_player_to_clan: [
      { player_name: 'Test Player' }, 'Test Player added to Test Clan.'
    ],
    add_many_players_to_clan: [
      { player_names: 'Test Player' },
      "Players added to Test Clan: [\"Test Player\"]\nPlayers not found: []\nPlayers already in Test Clan: []"
    ],
    remove_player_from_clan: [
      { player_name: 'Test Player' }, 'Test Player removed from Test Clan.'
    ],
    remove_many_players_from_clan: [
      { player_names: 'Test Player' },
      "Players been removed from Test Clan: [\"Test Player\"]\nPlayers not found, or are not in the clan: []"
    ],
    update_clan_description: [
      { clan_description: 'Updated description' }, 'Clan description updated successfully.'
    ],
    update_clan_link1: [
      { link1: 'https://example.com/one', link1_name: 'One' }, 'Clan link updated successfully.'
    ],
    update_clan_link2: [
      { link2: 'https://example.com/two', link2_name: 'Two' }, 'Clan link updated successfully.'
    ]
  }

  [:legacy, :bcrypt].each do |password_type|
    context "with a #{password_type} password" do
      let!(:clan) do
        credentials = password_type == :legacy ? { pass: Digest::MD5.hexdigest('mypassword') } : { password: 'mypassword' }
        Clan.create!({ name: 'Test Clan' }.merge(credentials))
      end
      let!(:player) { Player.create!(player_name: 'Test Player', player_acc_type: 'Reg') }

      actions.each do |action, (action_params, success_notice)|
        describe "POST ##{action}" do
          before do
            clan.add_player(player) if action.to_s.start_with?('remove')
          end

          it 'accepts the existing password and preserves the success notice' do
            post action, params: action_params.merge(id: 'Test_Clan', pass: 'mypassword')

            expect(response).to redirect_to(clan_admin_path(id: 'Test_Clan'))
            expect(flash[:notice]).to eq(success_notice)
            expect(clan.reload.password_digest).to be_present
            if action.to_s.start_with?('add')
              expect(clan.players).to include(player)
            elsif action.to_s.start_with?('remove')
              expect(clan.players).not_to include(player)
            else
              attributes = action_params.transform_keys { |key| key == :clan_description ? :description : key }
              expect(clan.attributes.symbolize_keys).to include(attributes)
            end
          end

          it 'rejects the wrong password with the original notice and no changes' do
            original_attributes = clan.reload.attributes
            original_links = PlayerClanLink.pluck(:id)

            post action, params: action_params.merge(id: 'Test_Clan', pass: 'wrong')

            expect(response).to redirect_to(clan_admin_path(id: 'Test_Clan'))
            expect(flash[:notice]).to eq('Incorrect password. Please try again.')
            expect(clan.reload.attributes).to eq(original_attributes)
            expect(PlayerClanLink.pluck(:id)).to eq(original_links)
          end
        end
      end
    end
  end
end
