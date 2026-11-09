require 'rails_helper'

RSpec.describe PlayerQuery do
  def filters(policy = :ranks, **attributes)
    defaults = {
      policy: policy, skill: "overall", sort_by: "ehp", time: "week", display: "stats",
      filters: { "Reg" => 1 }, clan_filters: { "None" => 1 }, restrictions: {},
      show_limit: 100, filter_inactive: "false"
    }
    Struct.new(*defaults.keys, keyword_init: true).new(**defaults.merge(attributes))
  end

  def query(state, base: Player, page: nil)
    described_class.new(base: base, filters: state, page: page)
  end

  describe "SQL policies" do
    it "keeps clan selections in ranks but not tracking" do
      state = { clan_filters: { "Selected" => 1 } }
      expect(query(filters(:ranks, **state)).call.to_sql).to include('LEFT OUTER JOIN', 'DISTINCT', "'Selected'")
      sql = query(filters(:tracking, **state)).call.to_sql
      expect(sql).not_to include('JOIN', "'Selected'")
      expect(sql).to include('overall_ehp_day_start > 0', 'overall_ehp > 1', 'overall_lvl <= 1494')
    end

    it "uses the supplied clan membership base without global account or total restrictions" do
      clan = Clan.create!(name: "Query Clan")
      sql = query(filters(:clan, filters: {}), base: clan.players).call.to_sql
      expect(sql).to include('player_clan_links', 'potential_p2p IS NULL OR potential_p2p = 0')
      expect(sql).not_to include('player_acc_type', 'overall_lvl <=', 'overall_ehp > 250', 'LIMIT')
    end

    it "retains record day eligibility independent of selected period" do
      sql = query(filters(:records, time: "year")).call.to_sql
      expect(sql).to include('overall_ehp_day_max > 0', 'overall_ehp_year_max DESC')
      expect(sql).to include('overall_ehp > 250 OR player_name IN', 'overall_ehp > 1')
    end

    {
      "10 hitpoints" => ['"players"."hitpoints_lvl" = 10', 'combat_lvl >= 4'],
      "1 defence" => ['"players"."defence_lvl" = 1', 'combat_lvl >= 4'],
      "3 combat" => ['combat_lvl < 4', 'overall_lvl <= 816'],
      "combat only" => ['"players"."cooking_lvl" = 1', '"players"."runecraft_lvl" = 1', 'combat_lvl > 10']
    }.each do |restriction, clauses|
      it "shares the #{restriction} restriction across global listings" do
        %i[ranks tracking records].each do |policy|
          sql = query(filters(policy, restrictions: { restriction => 1 })).call.to_sql
          clauses.each { |clause| expect(sql).to include(clause) }
        end
      end
    end

    it "keeps boss-positive filtering specific to ranks" do
      expect(query(filters(:ranks, skill: "obor_kc")).call.to_sql).to include('"players"."obor_kc" > 0')
      expect(query(filters(:clan, skill: "obor_kc")).call.to_sql).not_to include('"players"."obor_kc" > 0')
    end

    it "keeps inactive filtering monthly even when another period is selected" do
      %i[ranks clan].each do |policy|
        sql = query(filters(policy, time: "year", filter_inactive: "true")).call.to_sql
        expect(sql).to include('(overall_xp - overall_xp_month_start) > 0')
      end
    end

    it "keeps TTM eligibility and nonnull combat filtering in stats policies" do
      %i[ranks clan].each do |policy|
        expect(query(filters(policy, skill: "ttm_lvl")).call.to_sql)
          .to include('ttm_lvl != 0 or ttm_xp != 0 or overall_ehp > 1000')
        expect(query(filters(policy, skill: "combat", sort_by: "lvl")).call.to_sql)
          .to include('combat_lvl IS NOT NULL')
      end
    end

    it "does not let supporter names become SQL syntax" do
      allow(Player).to receive(:supporters).and_return(["O'Brien", "x') OR 1=1 --"])
      sql = query(filters(:tracking)).call.to_sql
      expect(sql).to include("O''Brien", "x'') OR 1=1 --")
    end
  end

  describe "virtual sorts" do
    def player(name, ehp:, level: 1, xp: 0)
      attributes = Player::SKILLS.reject { |skill| skill == "overall" }.each_with_object({}) do |skill, values|
        values["#{skill}_lvl"] = level
        values["#{skill}_xp"] = xp
        values["#{skill}_ehp"] = 0
      end
      Player.create!(attributes.merge(
        player_name: name, player_acc_type: "Reg", overall_lvl: 500, overall_ehp: ehp
      ))
    end

    it "sorts the entire candidate set before paginating ranks" do
      first = player("Lower Count", ehp: 600)
      second = player("Higher Count", ehp: 400, level: 99)
      result = query(filters(:ranks, skill: "99_count", show_limit: 1)).call
      expect(result.map(&:id)).to eq([second.id])
      expect(result.total_entries).to eq(2)
      expect(query(filters(:ranks, skill: "99_count", show_limit: 1), page: 2).call.map(&:id)).to eq([first.id])
    end

    it "uses overall EHP as the count tiebreaker and sorts minimum levels descending" do
      low = player("Low", ehp: 300, level: 50)
      high = player("High", ehp: 600, level: 80)
      %w[99_count 200m_count lowest_lvl].each do |skill|
        expect(query(filters(:ranks, skill: skill)).call.map(&:id)).to eq([high.id, low.id])
      end
    end

    it "uses XP then noncombat EHP then overall EHP for no-combat ties" do
      low = player("Low", ehp: 600)
      high = player("High", ehp: 300)
      high.update!(fishing_ehp: 5)
      expect(query(filters(:ranks, skill: "no_combats", sort_by: "xp")).call.map(&:id))
        .to eq([high.id, low.id])
    end

    it "retains clan arrays for virtual sorts and relations for ordinary sorts" do
      clan = Clan.create!(name: "Virtual Clan")
      member = player("Member", ehp: 400)
      clan.add_player(member)
      expect(query(filters(:clan, skill: "99_count"), base: clan.players).call).to be_a(Array)
      expect(query(filters(:clan), base: clan.players).call).to be_a(ActiveRecord::Relation)
    end

    it "retains clan virtual precedence over alphabetical ordering" do
      clan = Clan.create!(name: "Alphabetical Clan")
      alpha = player("Alpha", ehp: 300)
      zulu = player("Zulu", ehp: 600, level: 99)
      [alpha, zulu].each { |member| clan.add_player(member) }
      result = query(filters(:clan, skill: "99_count", sort_by: "player_name"), base: clan.players).call
      expect(result.map(&:id)).to eq([zulu.id, alpha.id])
      relation = query(filters(:clan, skill: "no_combats", sort_by: "player_name"), base: clan.players).call
      expect(relation).to be_a(ActiveRecord::Relation)
      expect(relation.to_sql).not_to include('ORDER BY')
    end
  end
end

RSpec.describe PlayerOrdering do
  def ordering(policy = :ranks, **attributes)
    defaults = { policy: policy, skill: "attack", time: "month", sort_by: "ehp", display: "stats" }
    state = Struct.new(*defaults.keys, keyword_init: true).new(**defaults.merge(attributes))
    described_class.new(state)
  end

  it "shares each stats special ordering between ranks and clan" do
    {
      "ttm_lvl" => "ttm_lvl ASC, overall_ehp DESC",
      "ttm_xp" => "ttm_xp ASC, overall_ehp DESC",
      "clues_beginner" => "clues_beginner DESC, players.id ASC",
      "clues_all" => PlayerOrdering::FALLBACK,
      "lms" => "lms_score DESC, lms_rank ASC",
      "brutus_kc" => "brutus_kc DESC, brutus_kc_rank ASC",
      "99_count" => "overall_ehp DESC",
      "200m_count" => "overall_ehp DESC",
      "lowest_lvl" => "overall_ehp DESC",
      "no_combats" => "overall_ehp DESC"
    }.each do |skill, expected|
      %i[ranks clan].each { |policy| expect(ordering(policy, skill: skill).to_sql).to eq(expected) }
    end
  end

  it "preserves all ordinary stats sort tie breakers and headers" do
    {
      "ehp" => "attack_ehp DESC, attack_lvl DESC, attack_xp DESC, attack_rank ASC, players.id ASC",
      "lvl" => "attack_lvl DESC, attack_xp DESC, attack_rank ASC",
      "xp" => "attack_xp DESC, attack_rank ASC"
    }.each do |sort, expected|
      result = ordering(sort_by: sort)
      expect(result.to_sql).to eq(expected)
      expect(result.header).to eq(sort.to_sym)
    end
    expect(ordering(skill: "combat", sort_by: "lvl").to_sql).to eq("combat_lvl DESC, overall_ehp DESC")
  end

  it "keeps tracking null arithmetic separate from clan gains COALESCE" do
    expect(ordering(:tracking).to_sql).to eq(
      "attack_ehp - attack_ehp_month_start DESC, attack_xp - attack_xp_month_start DESC, attack_ehp DESC, attack_xp DESC, players.id ASC"
    )
    expect(ordering(:clan, display: "gains", sort_by: "xp").to_sql).to eq(
      "attack_xp - COALESCE(attack_xp_month_start, 1000000000) DESC, attack_ehp - COALESCE(attack_ehp_month_start, 100000) DESC, attack_xp DESC"
    )
  end

  it "retains distinct record SQL and the player-record XP-only fallback" do
    expect(ordering(:records).to_sql).to eq(
      "attack_ehp_month_max DESC, attack_xp_month_max DESC, attack_ehp DESC, attack_xp DESC, players.id ASC"
    )
    expect(ordering(:clan, display: "records").to_sql).to eq(
      "COALESCE(attack_ehp_month_max, -100000) DESC, COALESCE(attack_xp_month_max, -1000000000) DESC, attack_ehp DESC, attack_xp DESC, players.id ASC"
    )
    allow(Player).to receive(:column_names).and_return(Player.column_names - ["attack_ehp_month_max"])
    expect(ordering(:records, sort_by: "xp").to_sql)
      .to eq("attack_xp_month_max DESC, attack_xp DESC, players.id ASC")
  end

  it "validates every derived column and retains unknown-display fallback" do
    allow(Player).to receive(:column_names).and_return(Player.column_names - ["attack_xp"])
    %i[ranks tracking records clan].each do |policy|
      expect(ordering(policy).to_sql).to eq(PlayerOrdering::FALLBACK)
    end
    expect(ordering(:clan, display: "unknown").to_sql).to eq(PlayerOrdering::FALLBACK)
    expect(ordering(:clan, display: "unknown", sort_by: "player_name").to_sql).to eq("player_name ASC")
  end
end
