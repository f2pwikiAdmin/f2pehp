module PlayersHelper
  def ranking_page_params
    {
      skill: @skill, sort_by: @sort_by, time: @time, show_limit: @show_limit,
      filters_: @filters, filters_present: "1",
      clans_: @clan_filters, clans_present: "1",
      restrictions: @restrictions.presence || "", filter_inactive: @filter_inactive
    }
  end

  def ranking_filter_labels
    labels = []
    if @filters.keys.sort != PlayerFilterParams::ACCOUNT_TYPES.sort
      labels << "Accounts: #{@filters.keys.join(', ').presence || 'None'}"
    end
    if @clan_filters.keys.sort != (Clan.all.map(&:name) + ["None"]).sort
      labels << "Clans: #{@clan_filters.keys.join(', ').presence || 'None selected'}"
    end
    labels.concat(@restrictions.keys)
    labels << "Inactive players hidden" if @filter_inactive == "true"
    labels
  end

  # Formats rank for display to end users
  # Converts -1 (unranked) to 0 for better UX
  def display_rank(rank)
    rank = rank.to_i
    rank == -1 ? 0 : rank
  end
end
