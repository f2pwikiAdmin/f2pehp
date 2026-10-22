require 'rails_helper'

RSpec.describe PlayersController, type: :controller do
  let(:player) { instance_double(Player, player_name: 'Callback Reg', is_f2p?: true) }

  describe 'show callbacks' do
    it 'executes show once from set_player and again as the successful action' do
      expect(Player).to receive(:find_player).with('Callback_Reg').twice.and_return(player)
      expect(controller).to receive(:show).twice.and_call_original

      get :show, params: { id: 'Callback_Reg', display: 'gains', time: 'month' }

      expect(response).to have_http_status(:ok)
      expect(controller.instance_variable_get(:@player)).to eq(player)
      expect(session[:display]).to eq('gains')
      expect(session[:time]).to eq('month')
    end

    it 'halts before the action when the callback cannot find the player' do
      expect(Player).to receive(:find_player).with('Missing_Player').once.and_return(false)
      expect(controller).to receive(:show).once.and_call_original

      get :show, params: { id: 'Missing_Player' }

      expect(response).to redirect_to(ranks_path)
      expect(flash[:notice]).to eq("Player 'Missing_Player' not found.")
    end
  end

  describe 'listing helper continuation' do
    before { Clan.create!(name: 'Callback Clan') }

    [:ranks, :tracking].each do |action|
      it "continues #{action} filter and query setup after a successful search redirect" do
        expect(Player).to receive(:find_player).with('Callback Reg').and_return(player)

        get action, params: { search: 'Callback_Reg', skill: 'attack', sort_by: 'xp' }

        expect(response).to redirect_to('/players/Callback_Reg')
        expect(session[:skill]).to eq('attack')
        expect(session[:sort_by]).to eq('xp')
        expect(controller.instance_variable_get(:@players)).to be_a(ActiveRecord::Relation)
      end

      it "continues #{action} setup after a missing search redirect" do
        expect(Player).to receive(:find_player).with('Missing Player').and_return(false)

        get action, params: { search: 'Missing_Player', skill: 'attack' }

        expect(response).to redirect_to(ranks_path)
        expect(flash[:notice]).to eq("Player 'Missing Player' not found.")
        expect(session[:skill]).to eq('attack')
        expect(controller.instance_variable_get(:@players)).to be_a(ActiveRecord::Relation)
      end

      it "runs compare inside #{action} and still builds the listing" do
        other_player = instance_double(Player, player_name: 'Callback Iron')
        expect(Player).to receive(:find_player).with('Callback_Reg').and_return(player)
        expect(Player).to receive(:find_player).with('Callback_Iron').and_return(other_player)
        expect(controller).to receive(:compare).and_call_original

        get action, params: { player1: 'Callback_Reg', player2: 'Callback_Iron' }

        expect(response).to have_http_status(:ok)
        expect(controller.instance_variable_get(:@player1)).to eq(player)
        expect(controller.instance_variable_get(:@player2)).to eq(other_player)
        expect(controller.instance_variable_get(:@players)).to be_a(ActiveRecord::Relation)
      end

      it "continues #{action} setup after compare redirects for a missing player" do
        expect(Player).to receive(:find_player).with('Missing_Player').and_return(false)
        expect(Player).to receive(:find_player).with('Callback_Reg').and_return(player)

        get action, params: { player1: 'Missing_Player', player2: 'Callback_Reg', skill: 'attack' }

        expect(response).to redirect_to(ranks_path)
        expect(flash[:notice]).to eq("Player 'Missing_Player' not found.")
        expect(session[:skill]).to eq('attack')
        expect(controller.instance_variable_get(:@players)).to be_a(ActiveRecord::Relation)
      end
    end
  end
end

RSpec.describe ClansController, type: :controller do
  describe 'show callbacks' do
    it 'executes show once from set_clan and again as the successful action' do
      clan = Clan.create!(name: 'Callback Clan')
      expect(Clan).to receive(:find_clan).with('Callback_Clan').twice.and_return(clan)
      expect(controller).to receive(:show).twice.and_call_original

      get :show, params: { id: 'Callback_Clan', display: 'gains', time: 'month' }

      expect(response).to have_http_status(:ok)
      expect(controller.instance_variable_get(:@clan)).to eq(clan)
      expect(controller.instance_variable_get(:@players)).to be_a(ActiveRecord::Relation)
      expect(session[:display]).to eq('gains')
      expect(session[:time]).to eq('month')
    end

    it 'halts before the action when the callback cannot find the clan' do
      expect(Clan).to receive(:find_clan).with('Missing_Clan').once.and_return(false)
      expect(controller).to receive(:show).once.and_call_original

      get :show, params: { id: 'Missing_Clan' }

      expect(response).to redirect_to(clans_path)
      expect(flash[:notice]).to eq("Clan 'Missing_Clan' not found.")
    end
  end
end
