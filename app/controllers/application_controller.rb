class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private

  def player_listing_filters(policy)
    filters = PlayerFilterParams.new(params: params, session: session, policy: policy)
    filters.attributes.each do |name, value|
      instance_variable_set("@#{name}", value)
    end
    @clear_filters = params[:clear_filters]
    @skills_by_xp = ['magic', 'mining']

    if %i[tracking records clan].include?(policy)
      now = policy == :records ? Time.zone.now : Time.now.gmtime
      @time_display = case @time
      when "day"
        now.strftime("%b %d, %Y")
      when "week"
        now.beginning_of_week.strftime("%b %d, %Y")
      when "month"
        now.strftime("%b %Y")
      when "year"
        now.year
      end
    end
    filters
  end

  def load_player_listing(base:, filters:)
    query = PlayerQuery.new(base: base, filters: filters, page: params[:page])
    @players = query.call
    header = query.ordering.header
    instance_variable_set("@player_#{header}_header", 'hilite') if %i[ehp lvl xp].include?(header)
    @players
  end
end
