module PlayersHelper
  # Formats rank for display to end users
  # Converts -1 (unranked) to 0 for better UX
  def display_rank(rank)
    rank = rank.to_i
    rank == -1 ? 0 : rank
  end
end
