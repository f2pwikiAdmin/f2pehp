require 'rails_helper'

RSpec.describe PlayerFilterParams do
  let(:session) { {} }
  let(:params) { ActionController::Parameters.new }

  before do
    allow(Clan).to receive(:all).and_return([double(name: "Test Clan"), double(name: "Other Clan")])
    allow(Player).to receive(:column_names).and_return(%w[overall_ehp_week_max mining_ehp_week_max])
  end

  def resolve(policy = :ranks, values = {}, state = session)
    described_class.new(params: ActionController::Parameters.new(values), session: state, policy: policy)
  end

  it 'resolves cold defaults, exposes symbol attributes, and mirrors canonical state' do
    service = described_class.new(params: params, session: session, policy: :ranks)

    expect(service.policy).to eq(:ranks)
    expect(service.attributes).to eq(
      skill: "overall", time: "week", sort_by: "ehp",
      filters: { "Reg" => 1, "IM" => 1, "UIM" => 1, "HCIM" => 1 },
      restrictions: {}, clan_filters: { "Test Clan" => 1, "Other Clan" => 1, "None" => 1 },
      show_limit: 100, filter_inactive: "false"
    )
    service.attributes.each do |key, value|
      storage_key = { filters: :filters_, clan_filters: :clans_ }.fetch(key, key)
      expect(service.public_send(key)).to eq(value)
      expect(params[storage_key]).to eq(value.is_a?(Hash) ? ActionController::Parameters.new(value) : value)
      expect(session[storage_key]).to eq(value)
    end
  end

  it 'supports only each policy settings without changing unrelated shared settings' do
    session.merge!(filters_: { "IM" => 1 }, show_limit: 50, display: "gains", filter_inactive: "true")
    clan = resolve(:clan)
    expect(clan.attributes.keys).to contain_exactly(:skill, :time, :sort_by, :display, :filter_inactive)
    expect(session[:filters_]).to eq("IM" => 1)
    expect(session[:show_limit]).to eq(50)

    %i[tracking records].each do |policy|
      service = resolve(policy)
      expect(service.attributes.keys).to contain_exactly(:skill, :time, :sort_by, :filters, :restrictions, :clan_filters, :show_limit)
      expect(session[:display]).to eq("gains")
      expect(session[:filter_inactive]).to eq("true")
    end
  end

  it 'initializes every supported policy from an empty session' do
    %i[tracking records clan].each do |policy|
      service = resolve(policy, {}, {})
      expect(service.attributes).to include(skill: "overall", time: "week", sort_by: "ehp")
      if policy == :clan
        expect(service.attributes).to include(display: "stats", filter_inactive: "false")
      else
        expect(service.attributes).to include(show_limit: 100, restrictions: {})
        expect(service.filters.keys).to eq(%w[Reg IM UIM HCIM])
      end
    end
  end

  it 'does not partially persist state if default resolution fails' do
    request = ActionController::Parameters.new(skill: "mining", filters_: { IM: "1" })
    session.merge!(skill: "fishing", time: "year", sort_by: "xp", restrictions: "1 defence")
    original_params = request.deep_dup
    original_session = session.deep_dup
    allow(Clan).to receive(:all).and_raise(StandardError, "Clan lookup failed")

    expect {
      described_class.new(params: request, session: session, policy: :ranks)
    }.to raise_error(StandardError, "Clan lookup failed")
    expect(request).to eq(original_params)
    expect(session).to eq(original_session)
  end

  it 'retains selections and restrictions through omission and a JSON session roundtrip' do
    first = resolve(:ranks, skill: "mining", sort_by: "xp", time: "month",
      filters_: { IM: "1" }, clans_: { None: "1" }, restrictions: "1 defence",
      show_limit: "250", filter_inactive: "true")
    restored_session = JSON.parse(session.to_json).with_indifferent_access
    restored = resolve(:ranks, {}, restored_session)

    expect(restored.attributes).to eq(first.attributes)
    expect(restored.restrictions).to eq("1 defence" => 1)
    expect(resolve(:tracking, {}, restored_session).restrictions).to eq("1 defence" => 1)
    expect(resolve(:ranks, { skill: "fishing" }, restored_session).filters).to eq("IM" => "1")
  end

  it 'uses missing or nil parameters from the session, including restrictions' do
    session.merge!(skill: "mining", time: "day", sort_by: "xp",
      restrictions: { :"3 combat" => 1 }, filters_: { UIM: 1 })
    service = resolve(:tracking, skill: nil, restrictions: nil)
    expect(service.skill).to eq("mining")
    expect(service.time).to eq("day")
    expect(service.sort_by).to eq("xp")
    expect(service.filters).to eq("UIM" => 1)
    expect(service.restrictions).to eq("3 combat" => 1)
  end

  it 'preserves explicitly empty groups and empty persisted groups as no selection' do
    session.merge!(filters_: { "IM" => 1 }, clans_: { "None" => 1 }, restrictions: "1 defence")
    first = resolve(:records, filters_: {}, clans_: {}, restrictions: {})
    expect(first.filters).to eq({})
    expect(first.clan_filters).to eq({})
    expect(first.restrictions).to eq({})
    restored = resolve(:ranks, {}, JSON.parse(session.to_json).with_indifferent_access)
    expect(restored.filters).to eq({})
    expect(restored.clan_filters).to eq({})
    expect(restored.restrictions).to eq({})
  end

  it 'uses browser presence markers for unchecked-all, but prioritizes supplied groups' do
    session.merge!(filters_: { "IM" => 1 }, clans_: { "None" => 1 })
    empty = resolve(:ranks, filters_present: "1", clans_present: "1")
    expect(empty.filters).to eq({})
    expect(empty.clan_filters).to eq({})
    selected = resolve(:ranks, filters_present: "1", clans_present: "1",
      filters_: { HCIM: "1" }, clans_: { "Test Clan" => "1" })
    expect(selected.filters).to eq("HCIM" => "1")
    expect(selected.clan_filters).to eq("Test Clan" => "1")
  end

  it 'defaults clan selection to None when there are no clans' do
    allow(Clan).to receive(:all).and_return([])
    %i[ranks tracking records].each do |policy|
      expect(resolve(policy, {}, {}).clan_filters).to eq("None" => 1)
    end
  end

  it 'normalizes string and hash restrictions and drops unknown restriction names' do
    expect(resolve(:ranks, restrictions: "combat only").restrictions).to eq("combat only" => 1)
    expect(resolve(:ranks, restrictions: { :"10 hitpoints" => "1", unknown: 1 }).restrictions).to eq("10 hitpoints" => "1")
    expect(resolve(:ranks, restrictions: "unknown").restrictions).to eq({})
    expect(resolve(:ranks, restrictions: ["3 combat"]).restrictions).to eq({})
  end

  it 'resets supported filter settings while retaining time, display and unrelated state' do
    session.merge!(skill: "magic", sort_by: "xp", time: "month", display: "gains",
      filters_: {}, clans_: {}, restrictions: "1 defence", show_limit: 500,
      filter_inactive: "true", unrelated: "kept")
    service = resolve(:ranks, clear_filters: "false", skill: "mining", filters_: {})
    expect(service.skill).to eq("overall")
    expect(service.sort_by).to eq("ehp")
    expect(service.filters.keys).to eq(%w[Reg IM UIM HCIM])
    expect(service.clan_filters.keys).to eq(["Test Clan", "Other Clan", "None"])
    expect(service.restrictions).to eq({})
    expect(service.show_limit).to eq(100)
    expect(service.filter_inactive).to eq("false")
    expect(service.time).to eq("month")
    expect(session[:display]).to eq("gains")
    expect(session[:unrelated]).to eq("kept")
  end

  it 'does not reset on a boolean false clear value and retains clan reset scope' do
    session.merge!(skill: "mining", time: "year", display: "custom",
      filter_inactive: "true", filters_: {}, restrictions: "3 combat", show_limit: 50)
    expect(resolve(:clan, clear_filters: false).skill).to eq("mining")
    reset = resolve(:clan, clear_filters: "")
    expect(reset.skill).to eq("overall")
    expect(reset.filter_inactive).to eq("false")
    expect(reset.time).to eq("year")
    expect(reset.display).to eq("custom")
    expect(session[:filters_]).to eq({})
    expect(session[:restrictions]).to eq("3 combat")
    expect(session[:show_limit]).to eq(50)
  end

  it 'preserves clear_filters and unknown display strings through repeated clan resolution' do
    request = ActionController::Parameters.new(clear_filters: "true", skill: "mining", display: "custom")
    first = described_class.new(params: request, session: session, policy: :clan)
    expect(first.attributes).to include(skill: "overall", sort_by: "ehp", display: "custom")
    expect(request[:clear_filters]).to eq("true")
    session[:skill] = "magic"
    repeated = described_class.new(params: request, session: session, policy: :clan)
    expect(repeated.attributes).to eq(first.attributes)
    expect(request[:clear_filters]).to eq("true")
    expect(session[:skill]).to eq("overall")
  end

  it 'safely canonicalizes invalid scalar shapes and values without using stale session values' do
    session.merge!(skill: "mining", sort_by: "xp", time: "year", filter_inactive: "true")
    service = resolve(:ranks, skill: ["mining"], time: { week: "1" }, sort_by: "invalid",
      filters_: "IM", clans_: ["None"], restrictions: 5, show_limit: {}, filter_inactive: {})
    expect(service.attributes).to include(skill: "overall", time: "week", sort_by: "ehp",
      show_limit: 100, restrictions: {}, filter_inactive: "false")
    expect(service.filters.keys).to eq(%w[Reg IM UIM HCIM])
    expect(service.clan_filters.keys).to eq(["Test Clan", "Other Clan", "None"])
    expect(session[:skill]).to eq("overall")
    expect(resolve(:clan, display: ["gains"]).display).to eq("stats")
    expect(resolve(:clan, display: "unrecognized").display).to eq("unrecognized")
  end

  it 'preserves the existing upper-only limit cap and integer conversion' do
    { "999" => 500, "25" => 25, "25players" => 25, "invalid" => 0, "-1" => -1, "0" => 0 }.each do |input, expected|
      expect(resolve(:ranks, show_limit: input).show_limit).to eq(expected)
      expect(session[:show_limit]).to eq(expected)
    end
  end

  it 'validates string skills, times and sorts against the shared allowlists' do
    %i[ranks tracking records clan].each do |policy|
      request = ActionController::Parameters.new(skill: "overall DESC", time: "forever", sort_by: "DROP TABLE players")
      service = described_class.new(params: request, session: session, policy: policy)
      expect(service.attributes).to include(skill: "overall", time: "week", sort_by: "ehp")
      expect(request[:skill]).to eq("overall")
      expect(request[:time]).to eq("week")
      expect(request[:sort_by]).to eq("ehp")
    end
  end

  it 'uses implicit XP for magic and mining on ranks and clan but respects explicit EHP' do
    %i[ranks clan].each do |policy|
      %w[magic mining].each do |skill|
        expect(resolve(policy, { skill: skill }, {}).sort_by).to eq("xp")
        expect(resolve(policy, { skill: skill, sort_by: {} }, {}).sort_by).to eq("xp")
        expect(resolve(policy, { skill: skill, sort_by: "ehp" }, {}).sort_by).to eq("ehp")
        expect(resolve(policy, { skill: skill, sort_by: [] }, {}).sort_by).to eq("ehp")
        expect(resolve(policy, { skill: skill, sort_by: "" }, {}).sort_by).to eq("ehp")
      end
    end
  end

  it 'defaults tracking and records to EHP and preserves the resolved sort on later requests' do
    %i[tracking records].each do |policy|
      service = resolve(policy, { skill: "mining" }, {})
      expect(service.sort_by).to eq("ehp")
    end
    resolve(:ranks, skill: "mining")
    expect(resolve(:ranks, skill: "magic").sort_by).to eq("xp")
    expect(resolve(:ranks, skill: "magic", sort_by: "ehp").sort_by).to eq("ehp")
    expect(resolve(:ranks, skill: "mining").sort_by).to eq("ehp")
  end

  it 'shares skill and sort coercions across pages and persists the final canonical values' do
    resolve(:ranks, skill: "combat", sort_by: "lvl")
    tracking = resolve(:tracking)
    expect(tracking.skill).to eq("overall")
    expect(tracking.sort_by).to eq("ehp")
    expect(resolve(:ranks).attributes).to include(skill: "overall", sort_by: "ehp")

    %w[gains records].each do |display|
      clan = resolve(:clan, skill: "combat", sort_by: "lvl", display: display)
      expect(clan.attributes).to include(skill: "overall", sort_by: "ehp")
      expect(session[:skill]).to eq("overall")
      expect(session[:sort_by]).to eq("ehp")
      expect(resolve(:clan, skill: "overall").skill).to eq("overall")
    end
  end

  it 'retains clan name sorting and configured virtual skills on stats pages' do
    expect(resolve(:clan, skill: "ttm_lvl", sort_by: "player_name").attributes).to include(
      skill: "ttm_lvl", sort_by: "player_name"
    )
    expect(resolve(:ranks, skill: "no_combats").skill).to eq("no_combats")
    expect(resolve(:clan, display: "gains", sort_by: "player_name").sort_by).to eq("player_name")
    expect(resolve(:ranks, sort_by: "player_name").sort_by).to eq("ehp")
  end

  it 'retains unknown inactive strings while safely defaulting malformed shapes' do
    %i[ranks clan].each do |policy|
      expect(resolve(policy, filter_inactive: "custom").filter_inactive).to eq("custom")
      expect(session[:filter_inactive]).to eq("custom")
      expect(resolve(policy).filter_inactive).to eq("custom")
      expect(resolve(policy, filter_inactive: ["true"]).filter_inactive).to eq("false")
    end
  end

  it 'forces records to XP when the selected EHP record column is unavailable' do
    request = ActionController::Parameters.new(skill: "magic", time: "week", sort_by: "ehp")
    service = described_class.new(params: request, session: session, policy: :records)
    expect(service.sort_by).to eq("xp")
    expect(request[:sort_by]).to eq("xp")
    expect(session[:sort_by]).to eq("xp")
    expect(resolve(:clan, display: "records", skill: "magic", sort_by: "player_name").sort_by).to eq("player_name")
  end
end
