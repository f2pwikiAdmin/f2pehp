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

  describe "GET #records" do
    let(:players_relation) { instance_double(ActiveRecord::Relation) }
    let(:clan_relation) { instance_double(ActiveRecord::Relation) }

    before do
      allow(Clan).to receive(:all).and_return([])
      allow(Clan).to receive(:where).and_return(clan_relation)
      allow(Player).to receive(:sql_supporters).and_return("('supporter')")
      allow(Player).to receive(:sql_f2p_filter).and_return("1=1")
      allow(Player).to receive(:limit).and_return(players_relation)

      allow(players_relation).to receive(:left_joins).with(:clans).and_return(players_relation)
      allow(players_relation).to receive(:merge).with(clan_relation).and_return(players_relation)
      allow(players_relation).to receive(:distinct).and_return(players_relation)
      allow(players_relation).to receive(:where).and_return(players_relation)
      allow(players_relation).to receive(:order).and_return(players_relation)
      allow(players_relation).to receive(:paginate).and_return([])
    end

    it "defaults unknown sort_by values to ehp" do
      allow(Player).to receive(:column_names).and_return(%w[id overall_ehp attack_ehp attack_xp attack_ehp_week_max attack_xp_week_max])
      sql_ordering = nil
      allow(Arel).to receive(:sql) do |ordering|
        sql_ordering = ordering
        Arel::Nodes::SqlLiteral.new(ordering)
      end

      get :records, params: { skill: "attack", time: "week", sort_by: "bogus", clans_: { "TestClan" => 1, "None" => 1 } }

      expect(controller.instance_variable_get(:@sort_by)).to eq("ehp")
      expect(session[:sort_by]).to eq("ehp")
      expect(sql_ordering).to include("attack_ehp_week_max DESC")
    end

    it "forces xp ordering when the selected skill has no ehp max record column" do
      allow(Player).to receive(:column_names).and_return(%w[id overall_ehp magic_xp magic_xp_week_max])
      sql_ordering = nil
      allow(Arel).to receive(:sql) do |ordering|
        sql_ordering = ordering
        Arel::Nodes::SqlLiteral.new(ordering)
      end

      get :records, params: { skill: "magic", time: "week", sort_by: "ehp", clans_: { "TestClan" => 1, "None" => 1 } }

      expect(controller.instance_variable_get(:@sort_by)).to eq("xp")
      expect(session[:sort_by]).to eq("xp")
      expect(sql_ordering).to eq("magic_xp_week_max DESC, magic_xp DESC, players.id ASC")
      expect(sql_ordering).not_to include("magic_ehp_week_max")
    end

    it "falls back to a safe ordering when computed columns are missing" do
      allow(Player).to receive(:column_names).and_return(%w[id overall_ehp attack_xp])
      sql_ordering = nil
      allow(Arel).to receive(:sql) do |ordering|
        sql_ordering = ordering
        Arel::Nodes::SqlLiteral.new(ordering)
      end

      get :records, params: { skill: "attack", time: "week", sort_by: "ehp", clans_: { "TestClan" => 1, "None" => 1 } }

      expect(sql_ordering).to eq("overall_ehp DESC, players.id ASC")
    end
  end
end
