require "rails_helper"

RSpec.describe PlayersController, type: :controller do
  def create_ranked_player(name:, overall_rank:, fishing_rank:)
    Player.create!(
      player_name: name,
      player_acc_type: "Reg",
      potential_p2p: 0,
      overall_ehp: 300.0,
      overall_lvl: 100,
      overall_xp: 1_000,
      overall_rank: overall_rank,
      fishing_ehp: 25.0,
      fishing_lvl: 50,
      fishing_xp: 50_000,
      fishing_rank: fishing_rank
    )
  end

  describe "GET #ranks" do
    before do
      create_ranked_player(name: "Alpha", overall_rank: 1, fishing_rank: 2)
      create_ranked_player(name: "Bravo", overall_rank: 2, fishing_rank: 1)
    end

    it "falls back to overall for invalid skill parameters" do
      expect {
        get :ranks, params: { skill: "1; DROP TABLE players--" }
      }.not_to raise_error

      expect(response).to have_http_status(:ok)
      expect(session[:skill]).to eq("overall")
    end

    it "keeps valid skill parameters" do
      get :ranks, params: { skill: "fishing" }

      expect(response).to have_http_status(:ok)
      expect(session[:skill]).to eq("fishing")
    end
  end
end
