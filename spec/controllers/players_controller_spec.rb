require 'rails_helper'

RSpec.describe PlayersController, type: :controller do
  describe "GET #ranks" do
    let(:players_relation) { instance_double(ActiveRecord::Relation) }
    let(:clan_relation) { instance_double(ActiveRecord::Relation) }

    before do
      allow(Clan).to receive(:all).and_return([])
      allow(Clan).to receive(:where).and_return(clan_relation)
      allow(Player).to receive(:sql_f2p_filter).and_return("1=1")
      allow(Player).to receive(:left_joins).with(:clans).and_return(players_relation)

      allow(players_relation).to receive(:merge).with(clan_relation).and_return(players_relation)
      allow(players_relation).to receive(:distinct).and_return(players_relation)
      allow(players_relation).to receive(:where).and_return(players_relation)
      allow(players_relation).to receive(:order).and_return(players_relation)
      allow(players_relation).to receive(:paginate).and_return([])
    end

    it "sanitizes invalid skill values before building SQL ordering" do
      injected = "overall;drop_table"
      sql_ordering = nil
      allow(Arel).to receive(:sql) do |ordering|
        sql_ordering = ordering
        Arel::Nodes::SqlLiteral.new(ordering)
      end

      get :ranks, params: { skill: injected, sort_by: "ehp" }

      expect(controller.instance_variable_get(:@skill)).to eq("overall")
      expect(session[:skill]).to eq("overall")
      expect(sql_ordering).to include("overall_ehp DESC")
      expect(sql_ordering).not_to include("drop_table")
    end
  end
end
