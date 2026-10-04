class ApplicationController < ActionController::Base
  ORDERING_SKILLS = (
    F2POSRSRanks::Application.config.skills +
    F2POSRSRanks::Application.config.f2p_skills +
    %w[ttm_lvl ttm_xp combat obor_kc bryo_kc brutus_kc lms 99_count 200m_count no_combats lowest_lvl]
  ).uniq.freeze
  ORDERING_TIMES = %w[day week month year].freeze
  ORDERING_SORT_MODES = %w[ehp xp lvl player_name].freeze

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private

  # Only configured skills and fixed virtual sorts may become SQL identifiers.
  def sanitize_skill
    unless ORDERING_SKILLS.include?(@skill)
      @skill = "overall"
      params[:skill] = "overall"
      session[:skill] = "overall"
    end
  end

  # Sanitize @time against a strict allowlist to prevent SQL injection.
  def sanitize_time
    unless ORDERING_TIMES.include?(@time)
      @time = "week"
      params[:time] = "week"
      session[:time] = "week"
    end
  end

  def sanitize_sort_by(allowed = ORDERING_SORT_MODES)
    unless allowed.include?(@sort_by)
      @sort_by = "ehp"
      params[:sort_by] = "ehp"
      session[:sort_by] = "ehp"
    end
  end

  # Ordering expressions use lowercase column identifiers and uppercase SQL keywords.
  # Check every identifier, including those inside arithmetic and COALESCE expressions.
  def validated_player_ordering(ordering)
    columns = ordering.to_s.scan(/\b[a-z][a-z0-9_]*\b/) - ["players"]
    if ordering.present? && columns.any? && columns.all? { |column| Player.column_names.include?(column) }
      ordering
    else
      "overall_ehp DESC, players.id ASC"
    end
  end
end
