require 'will_paginate/array'

class PlayerQuery
  POLICIES = {
    ranks: {
      clans: true, accounts: true, restrictions: true, stats: true,
      max_total: true, inactive: true, bosses: true, virtual: true, paginate: true
    }.freeze,
    # Tracking retains the shared clan selection but intentionally does not join clans.
    tracking: {
      accounts: true, restrictions: true, supporters: true, snapshot: "overall_ehp_day_start",
      limit: true, max_total: true, minimum_ehp: true, paginate: true
    }.freeze,
    records: {
      clans: true, accounts: true, restrictions: true, supporters: true, snapshot: "overall_ehp_day_max",
      limit: true, max_total: true, minimum_ehp: true, paginate: true
    }.freeze,
    # Membership listings have no global account, supporter, total-level, or pagination gates.
    clan: {
      stats: true, inactive: true, virtual: true
    }.freeze
  }.freeze
  NON_COMBAT_SKILLS = %w[fishing cooking woodcutting firemaking mining smithing crafting runecraft].freeze

  attr_reader :ordering

  def initialize(base:, filters:, page: nil)
    @base = base
    @filters = filters
    @page = page
    @policy = POLICIES.fetch(filters.policy)
    @ordering = PlayerOrdering.new(filters)
  end

  def call
    players = @base
    if @policy[:clans]
      clans = @filters.clan_filters.keys
      clans += [nil] if @filters.clan_filters["None"]
      players = players.left_joins(:clans).merge(Clan.where(name: clans)).distinct
    end
    players = players.limit(@filters.show_limit) if @policy[:limit]
    players = players.where(player_acc_type: @filters.filters.keys) if @policy[:accounts]
    if @policy[:supporters]
      players = players.where("overall_ehp > 250 OR player_name IN (?)", Player.supporters)
    end
    players = players.where("#{@policy[:snapshot]} > 0") if @policy[:snapshot]
    players = restrict(players) if @policy[:restrictions]
    players = stats_filters(players) if @policy[:stats]
    if @policy[:inactive] && @filters.filter_inactive == "true"
      players = players.where("(overall_xp - overall_xp_month_start) > 0")
    end
    if @policy[:bosses] && %w[obor_kc bryo_kc brutus_kc].include?(@filters.skill)
      players = players.where("#{@filters.skill} > 0")
    end
    players = players.where(Player.sql_f2p_filter)
    players = players.where("overall_lvl <= ?", Player::F2P_MAX_TOTAL) if @policy[:max_total]
    players = players.where("overall_ehp > 1") if @policy[:minimum_ehp]

    sql = ordering.to_sql
    # Clan virtual sorts historically skip SQL ordering, including the name override.
    players = players.order(Arel.sql(sql)) unless @filters.policy == :clan && virtual?
    players = virtual_sort(players) if virtual?
    if @policy[:paginate]
      players = players.paginate(page: @page, per_page: @filters.show_limit)
    end
    players
  end

  private

  def restrict(players)
    restrictions = @filters.restrictions
    if restrictions["10 hitpoints"]
      players = players.where(hitpoints_lvl: 10).where("combat_lvl >= 4")
    end
    if restrictions["1 defence"]
      players = players.where(defence_lvl: 1).where("combat_lvl >= 4")
    end
    if restrictions["3 combat"]
      players = players.where("combat_lvl < 4").where("overall_lvl <= 816")
    end
    if restrictions["combat only"]
      players = players.where(NON_COMBAT_SKILLS.to_h { |skill| ["#{skill}_lvl", 1] }).where("combat_lvl > 10")
    end
    players
  end

  def stats_filters(players)
    if @filters.skill.include?("ttm")
      players = players.where("ttm_lvl != 0 or ttm_xp != 0 or overall_ehp > 1000")
    end
    players = players.where("combat_lvl IS NOT NULL") if @filters.skill == "combat"
    players
  end

  def virtual?
    @policy[:virtual] && %w[99_count 200m_count lowest_lvl no_combats].include?(@filters.skill)
  end

  def virtual_sort(players)
    case @filters.skill
    when "99_count"
      players.sort_by { |player| [player.count_99, player.overall_ehp] }.reverse
    when "200m_count"
      players.sort_by { |player| [player.count_200m, player.overall_ehp] }.reverse
    when "lowest_lvl"
      players.sort_by { |player| [player.lowest_lvl, player.overall_ehp] }.reverse
    when "no_combats"
      return players unless %w[ehp lvl xp].include?(@filters.sort_by)

      players.sort_by do |player|
        key = [non_combat_sum(player, @filters.sort_by)]
        key << non_combat_sum(player, "ehp") unless @filters.sort_by == "ehp"
        key << player.overall_ehp
      end.reverse
    end
  end

  def non_combat_sum(player, suffix)
    NON_COMBAT_SKILLS.sum { |skill| player.public_send("#{skill}_#{suffix}") }
  end
end
