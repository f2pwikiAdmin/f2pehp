class PlayerOrdering
  FALLBACK = "overall_ehp DESC, players.id ASC".freeze

  attr_reader :header

  def initialize(filters)
    @filters = filters
  end

  def to_sql
    ordering = case @filters.policy
               when :ranks then stats
               when :tracking then gains
               when :records then records
               when :clan
                 case @filters.display
                 when "stats" then stats
                 when "gains" then gains(coalesce: true)
                 when "records" then records(coalesce: true)
                 end
               end
    ordering = "player_name ASC" if @filters.policy == :clan && sort == "player_name"
    validate(ordering)
  end

  private

  def skill
    @filters.skill
  end

  def time
    @filters.time
  end

  def sort
    @filters.sort_by
  end

  def stats
    if skill.include?("ttm")
      "#{skill} ASC, overall_ehp DESC" if %w[ttm_lvl ttm_xp].include?(skill)
    elsif skill.include?("clues")
      "clues_beginner DESC, players.id ASC" if skill == "clues_beginner"
    elsif skill.include?("no_combats") || skill.include?("count") || skill.include?("lowest_lvl")
      "overall_ehp DESC"
    elsif skill.include?("lms")
      "lms_score DESC, lms_rank ASC"
    elsif skill.include?("_kc")
      "#{skill} DESC, #{skill}_rank ASC"
    else
      @header = sort.to_sym
      case sort
      when "ehp"
        "#{skill}_ehp DESC, #{skill}_lvl DESC, #{skill}_xp DESC, #{skill}_rank ASC, players.id ASC"
      when "lvl"
        if skill == "combat"
          "combat_lvl DESC, overall_ehp DESC"
        else
          "#{skill}_lvl DESC, #{skill}_xp DESC, #{skill}_rank ASC"
        end
      when "xp"
        "#{skill}_xp DESC, #{skill}_rank ASC"
      end
    end
  end

  def gains(coalesce: false)
    @header = sort.to_sym if %w[ehp xp].include?(sort)
    ehp_start = "#{skill}_ehp_#{time}_start"
    xp_start = "#{skill}_xp_#{time}_start"
    ehp_start = "COALESCE(#{ehp_start}, 100000)" if coalesce
    xp_start = "COALESCE(#{xp_start}, 1000000000)" if coalesce
    if sort == "ehp"
      "#{skill}_ehp - #{ehp_start} DESC, #{skill}_xp - #{xp_start} DESC, #{skill}_ehp DESC, #{skill}_xp DESC, players.id ASC"
    elsif sort == "xp"
      "#{skill}_xp - #{xp_start} DESC, #{skill}_ehp - #{ehp_start} DESC, #{skill}_xp DESC"
    end
  end

  def records(coalesce: false)
    @header = sort.to_sym if %w[ehp xp].include?(sort)
    ehp_max = "#{skill}_ehp_#{time}_max"
    xp_max = "#{skill}_xp_#{time}_max"
    if coalesce
      ehp_max = "COALESCE(#{ehp_max}, -100000)"
      xp_max = "COALESCE(#{xp_max}, -1000000000)"
    elsif sort == "xp" && !Player.column_names.include?(ehp_max)
      return "#{xp_max} DESC, #{skill}_xp DESC, players.id ASC"
    end

    if sort == "ehp"
      "#{ehp_max} DESC, #{xp_max} DESC, #{skill}_ehp DESC, #{skill}_xp DESC, players.id ASC"
    elsif sort == "xp"
      "#{xp_max} DESC, #{ehp_max} DESC, #{skill}_xp DESC"
    end
  end

  # Validate identifiers inside arithmetic and COALESCE as well as plain columns.
  def validate(ordering)
    columns = ordering.to_s.scan(/\b[a-z][a-z0-9_]*\b/) - ["players"]
    if ordering.present? && columns.any? && columns.all? { |column| Player.column_names.include?(column) }
      ordering
    else
      FALLBACK
    end
  end
end
