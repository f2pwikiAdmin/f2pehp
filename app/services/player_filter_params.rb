class PlayerFilterParams
  ORDERING_SKILLS = (
    F2POSRSRanks::Application.config.skills +
    F2POSRSRanks::Application.config.f2p_skills +
    %w[ttm_lvl ttm_xp combat obor_kc bryo_kc brutus_kc lms 99_count 200m_count no_combats lowest_lvl]
  ).uniq.freeze
  ORDERING_TIMES = %w[day week month year].freeze
  ORDERING_SORT_MODES = %w[ehp xp lvl player_name].freeze

  SETTINGS = {
    ranks: %i[skill time sort_by filters restrictions clan_filters show_limit filter_inactive],
    tracking: %i[skill time sort_by filters restrictions clan_filters show_limit],
    records: %i[skill time sort_by filters restrictions clan_filters show_limit],
    clan: %i[skill time sort_by filter_inactive display]
  }.freeze
  PARAM_KEYS = { filters: :filters_, clan_filters: :clans_ }.freeze
  RESET_SETTINGS = %i[skill sort_by filters restrictions clan_filters show_limit filter_inactive].freeze
  ACCOUNT_TYPES = %w[Reg IM UIM HCIM].freeze
  RESTRICTIONS = ["3 combat", "1 defence", "10 hitpoints", "combat only"].freeze

  attr_reader :attributes, :policy
  attr_reader(*SETTINGS.values.flatten.uniq)

  def initialize(params:, session:, policy:)
    @params = params
    @session = session
    @policy = policy
    settings = SETTINGS.fetch(policy)
    @clear_filters = params[:clear_filters]
    @attributes = {}

    @display = string_value(value(:display), "stats") if settings.include?(:display)
    @skill = allowed_value(value(:skill), allowed_skills, "overall")
    @time = allowed_value(value(:time), ORDERING_TIMES, "week")
    @sort_by = resolve_sort

    settings.each do |setting|
      resolved = case setting
      when :skill, :time, :sort_by, :display
        public_send(setting)
      when :filters
        selection(value(setting, :filters_present)) { ACCOUNT_TYPES.index_with { 1 } }
      when :clan_filters
        selection(value(setting, :clans_present)) { (Clan.all.map(&:name) + ["None"]).index_with { 1 } }
      when :restrictions
        restrictions_value(value(setting))
      when :show_limit
        limit = value(setting)
        limit.is_a?(String) || limit.is_a?(Numeric) ? [limit.to_i, 500].min : 100
      when :filter_inactive
        string_value(value(setting), "false")
      end
      instance_variable_set("@#{setting}", resolved)
      @attributes[setting] = resolved
    end

    @attributes.each do |setting, resolved|
      key = PARAM_KEYS.fetch(setting, setting)
      @params[key] = resolved
      @session[key] = resolved
    end
  end

  private

  def value(setting, marker = nil)
    return nil if @clear_filters && RESET_SETTINGS.include?(setting)

    key = PARAM_KEYS.fetch(setting, setting)
    supplied = @params[key]
    return supplied unless supplied.nil?
    return {} if marker && @params[marker]

    @session[key]
  end

  def gains?
    %i[tracking records].include?(policy) || (policy == :clan && %w[gains records].include?(display))
  end

  def allowed_skills
    return ORDERING_SKILLS unless gains?

    F2POSRSRanks::Application.config.f2p_skills + ["overall"]
  end

  def resolve_sort
    supplied = value(:sort_by)
    implicit = supplied.nil? || (selection_hash?(supplied) && supplied.empty?)
    default = %i[ranks clan].include?(policy) && %w[magic mining].include?(skill) ? "xp" : "ehp"
    allowed = case policy
    when :tracking, :records then %w[ehp xp]
    when :ranks then %w[ehp xp lvl]
    else ORDERING_SORT_MODES
    end
    sort = implicit ? default : allowed_value(supplied, allowed, "ehp")
    sort = "ehp" if gains? && sort == "lvl"
    sort = "xp" if policy == :records && !Player.column_names.include?("#{skill}_ehp_#{time}_max")
    sort
  end

  def allowed_value(value, allowed, default)
    value.is_a?(String) && allowed.include?(value) ? value : default
  end

  def string_value(value, default)
    value.is_a?(String) ? value : default
  end

  def selection(value)
    return value.to_unsafe_h.stringify_keys if value.is_a?(ActionController::Parameters)
    return value.stringify_keys if value.is_a?(Hash)

    yield
  end

  def selection_hash?(value)
    value.is_a?(Hash) || value.is_a?(ActionController::Parameters)
  end

  def restrictions_value(value)
    return { value => 1 } if value.is_a?(String) && RESTRICTIONS.include?(value)

    selection(value) { {} }.slice(*RESTRICTIONS)
  end
end
