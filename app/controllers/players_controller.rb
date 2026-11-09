require 'net/https'
require 'uri'
require "open-uri"
require 'nokogiri'
require 'will_paginate/array'

class PlayersController < ApplicationController
  before_action :set_player, only: %i[show edit update destroy]

  def set_default_description
    @default_description = 'F2P.wiki is an open source Old School RuneScape hiscores for Free-to-play players. It also includes EHP tracking, information about meta changes, and various F2P Old School RuneScape tools.'
  end
  before_action :set_default_description

  def search_player_if_needed
    if params[:search]
      name = Player.sanitize_name(params[:search])
      @player = Player.find_player(name)
      if @player
        redirect_to "/players/#{@player.player_name.gsub(" ", "_").encode("ASCII", invalid: :replace, undef: :replace, replace: '_')}"
      else
        redirect_to ranks_path, notice: "Player '#{name}' not found."
      end
      return
    end
  end

  def create_player_if_needed
    return unless request.post?
    if !params[:player_to_add_name].nil? and params[:player_to_add_name] != ""
      if params[:player_to_add_name].length > 12
        redirect_to ranks_path, notice: 'Invalid player name.'
        return
      end

      name = Player.sanitize_name(params[:player_to_add_name])
      params[:player_to_add_name] = nil
      session[:player_to_add_name] = nil

      result = Player.create_new(name)

      case result
      when nil
        redirect_to ranks_path, notice: "Player hiscores not found."
      when 'exists'
        redirect_to "/players/#{name.gsub(" ", "_")}", notice: "The player you wish to add already exists."
      when 'p2p'
        redirect_to ranks_path, notice: "The player you wish to add is not a free to play account."
      when 'cutoff'
        redirect_to ranks_path, notice: "The player you wish to add does not meet the EHP requirement."
      when 'failed'
        redirect_to ranks_path, notice: 'Unable to fetch player hiscores.'
      else
        redirect_to result, notice: "Player added successfully."
      end
    end
  end

  def tracking
    search_player_if_needed
    create_player_if_needed

    filters = player_listing_filters(:tracking)
    compare if params[:player1] && params[:player2]
    load_player_listing(base: Player, filters: filters)
  end

  def records
    # TODO: Records page is temporarily disabled while the /records 500 is being
    # fixed on a separate branch. The 500 survives the ORDER BY hardening from
    # PR #132, so it is likely in one of the untouched `.where(...)` clauses, the
    # records.html.haml view, or the `compare` short-circuit path. Remove this
    # guard (and restore the nav links noted below) to re-enable Records.
    redirect_to ranks_path, notice: "Records are temporarily unavailable while we work on them. Check back soon!"
    return

    # --- existing implementation kept intentionally; unreachable until re-enabled ---
    search_player_if_needed
    create_player_if_needed

    Time.zone = "Pacific Time (US & Canada)"
    filters = player_listing_filters(:records)
    compare if params[:player1] && params[:player2]
    load_player_listing(base: Player, filters: filters)
  end

  def ranks
    search_player_if_needed
    create_player_if_needed

    filters = player_listing_filters(:ranks)
    compare if params[:player1] && params[:player2]
    load_player_listing(base: Player, filters: filters)
  end

  # GET /players/1
  # GET /players/1.json
  def show
    @display = params[:display] || session[:display] || "stats"
    @time = params[:time] || session[:time] || "week"

    if params[:display] != session[:display] || params[:time] != session[:time]
      session[:display] = @display
      session[:time] = @time
    end

    id = params[:search] || params[:id]
    @player = Player.find_player(id)

    unless @player
      redirect_to ranks_path, notice: "Player '#{id}' not found."
      return
    end

    # Check if player is on the fakes list - they should be removed
    if F2POSRSRanks::Application.config.downcase_fakes.include?(@player.player_name.downcase)
      Player.where(player_name: @player.player_name).destroy_all
      redirect_to ranks_path, notice: "Player '#{@player.player_name}' is not a free-to-play account and has been removed."
      return
    end

    # Check if player is on the banned list - they should be removed
    if F2POSRSRanks::Application.config.downcase_banned.include?(@player.player_name.downcase)
      Player.where(player_name: @player.player_name).destroy_all
      redirect_to ranks_path, notice: "Player '#{@player.player_name}' is banned and has been removed."
      return
    end

    if !@player.is_f2p?
      redirect_to ranks_path, notice: "Player '#{@player.player_name}' is not free to play."
      return
    end

    @player
  end

  def compare
    @player1 = Player.find_player(params[:player1])
    @player2 = Player.find_player(params[:player2])

    player_not_found = nil
    if not @player1
      player_not_found = params[:player1]
    elsif not @player2
      player_not_found = params[:player2]
    end

    if player_not_found
      redirect_to ranks_path, notice: "Player '#{player_not_found}' not found."
    end
  end

  # GET /changelog
  def changelog
  end

  # POST /players
  # POST /players.json
  def create
    @player = Player.create!(player_params)
    flash[:notice] = 'Player was successfully created.'
    redirect_to players_path
  end

  # PATCH/PUT /players/1
  # PATCH/PUT /players/1.json
  def update
    # If updated less than a minute ago
    if (@player.updated_at > 1.minutes.ago)
      redirect_to player_path(@player.player_name),
        notice: "Updating too quickly. Please try again in a minute"
    elsif @player.update_player
      redirect_to player_path(@player.player_name)
    else
      # update_player returns false for fakes/banned (which get destroyed) or failed updates
      if F2POSRSRanks::Application.config.downcase_fakes.include?(@player.player_name.downcase)
        redirect_to ranks_path,
          notice: "Player #{@player.player_name} is not a free-to-play account and has been removed."
      elsif F2POSRSRanks::Application.config.downcase_banned.include?(@player.player_name.downcase)
        redirect_to ranks_path,
          notice: "Player #{@player.player_name} is banned and has been removed."
      else
        redirect_to player_path(@player.player_name),
          notice: "Player #{@player.player_name} could not be updated. Please try again."
      end
    end
  end

  def update_player
    @player.update_player
    @player
  end

  def check_acc_type
    name = Player.sanitize_name(params[:id])
    @player = Player.find_player(name)

    if @player.force_update_acc_type
      redirect_to player_path(@player.player_name)
    else
      redirect_to player_path(@player.player_name),
        notice: "Player #{@player.player_name} could not be updated. Please try again."
    end
  end
  
def monster_ratio
  name = params[:id] || params[:search] # retrieve the player name from the request parameters
  if name.nil?
    # if no player name was specified, set @player to a default value
    @player = Player.new(id: "notrealaccount", attack_xp: 0, strength_xp: 0, defence_xp: 0, ranged_xp: 0, smithing_xp: 0, crafting_xp: 0, runecraft_xp: 0)
  else
    # if a player name was specified, look it up in the database
    @player = Player.find_player(name)
  end

  if @player.nil?
    flash[:error] = "Player not found"
    redirect_to monster_ratio_path
  elsif !@player.is_a?(Player)
    flash[:error] = "Player not found"
    redirect_to monster_ratio_path
  else
    @combatxp = @player.attack_xp + @player.strength_xp + @player.defence_xp + @player.ranged_xp
    @smithxp = @player.smithing_xp
    @craftxp = @player.crafting_xp
    @runecraftxp = @player.runecraft_xp
  end
end

    

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_player
    show
  end

  def player_params
    params.require(:player).permit(
      :player_name,
      :player_acc_type,
      :overall_xp,
      :overall_lvl,
      :overall_ehp,
      :overall_rank,
      :attack_xp,
      :attack_lvl,
      :attack_ehp,
      :attack_rank,
      :strength_xp,
      :strength_lvl,
      :strength_ehp,
      :strength_rank,
      :defence_xp,
      :defence_lvl,
      :defence_ehp,
      :defence_rank,
      :hitpoints_xp,
      :hitpoints_lvl,
      :hitpoints_ehp,
      :hitpoints_rank,
      :ranged_xp,
      :ranged_lvl,
      :ranged_ehp,
      :ranged_rank,
      :prayer_xp,
      :prayer_lvl,
      :prayer_ehp,
      :prayer_rank,
      :magic_xp,
      :magic_lvl,
      :magic_ehp,
      :magic_rank,
      :cooking_xp,
      :cooking_lvl,
      :cooking_ehp,
      :cooking_rank,
      :woodcutting_xp,
      :woodcutting_lvl,
      :woodcutting_ehp,
      :woodcutting_rank,
      :fishing_xp,
      :fishing_lvl,
      :fishing_ehp,
      :fishing_rank,
      :firemaking_xp,
      :firemaking_lvl,
      :firemaking_ehp,
      :firemaking_rank,
      :crafting_xp,
      :crafting_lvl,
      :crafting_ehp,
      :crafting_rank,
      :smithing_xp,
      :smithing_lvl,
      :smithing_ehp,
      :smithing_rank,
      :mining_xp,
      :mining_lvl,
      :mining_ehp,
      :mining_rank,
      :runecraft_xp,
      :runecraft_lvl,
      :runecraft_ehp,
      :runecraft_rank,
      :potential_p2p,
      :combat_lvl,

      :attack_xp_day_start,
      :attack_xp_day_max,
      :attack_ehp_day_start,
      :attack_ehp_day_max,
      :attack_xp_week_start,
      :attack_xp_week_max,
      :attack_ehp_week_start,
      :attack_ehp_week_max,
      :attack_xp_month_start,
      :attack_xp_month_max,
      :attack_ehp_month_start,
      :attack_ehp_month_max,
      :attack_xp_year_start,
      :attack_xp_year_max,
      :attack_ehp_year_start,
      :attack_ehp_year_max,
      :strength_xp_day_start,
      :strength_xp_day_max,
      :strength_ehp_day_start,
      :strength_ehp_day_max,
      :strength_xp_week_start,
      :strength_xp_week_max,
      :strength_ehp_week_start,
      :strength_ehp_week_max,
      :strength_xp_month_start,
      :strength_xp_month_max,
      :strength_ehp_month_start,
      :strength_ehp_month_max,
      :strength_xp_year_start,
      :strength_xp_year_max,
      :strength_ehp_year_start,
      :strength_ehp_year_max,
      :defence_xp_day_start,
      :defence_xp_day_max,
      :defence_ehp_day_start,
      :defence_ehp_day_max,
      :defence_xp_week_start,
      :defence_xp_week_max,
      :defence_ehp_week_start,
      :defence_ehp_week_max,
      :defence_xp_month_start,
      :defence_xp_month_max,
      :defence_ehp_month_start,
      :defence_ehp_month_max,
      :defence_xp_year_start,
      :defence_xp_year_max,
      :defence_ehp_year_start,
      :defence_ehp_year_max,
      :hitpoints_xp_day_start,
      :hitpoints_xp_day_max,
      :hitpoints_ehp_day_start,
      :hitpoints_ehp_day_max,
      :hitpoints_xp_week_start,
      :hitpoints_xp_week_max,
      :hitpoints_ehp_week_start,
      :hitpoints_ehp_week_max,
      :hitpoints_xp_month_start,
      :hitpoints_xp_month_max,
      :hitpoints_ehp_month_start,
      :hitpoints_ehp_month_max,
      :hitpoints_xp_year_start,
      :hitpoints_xp_year_max,
      :hitpoints_ehp_year_start,
      :hitpoints_ehp_year_max,
      :ranged_xp_day_start,
      :ranged_xp_day_max,
      :ranged_ehp_day_start,
      :ranged_ehp_day_max,
      :ranged_xp_week_start,
      :ranged_xp_week_max,
      :ranged_ehp_week_start,
      :ranged_ehp_week_max,
      :ranged_xp_month_start,
      :ranged_xp_month_max,
      :ranged_ehp_month_start,
      :ranged_ehp_month_max,
      :ranged_xp_year_start,
      :ranged_xp_year_max,
      :ranged_ehp_year_start,
      :ranged_ehp_year_max,
      :prayer_xp_day_start,
      :prayer_xp_day_max,
      :prayer_ehp_day_start,
      :prayer_ehp_day_max,
      :prayer_xp_week_start,
      :prayer_xp_week_max,
      :prayer_ehp_week_start,
      :prayer_ehp_week_max,
      :prayer_xp_month_start,
      :prayer_xp_month_max,
      :prayer_ehp_month_start,
      :prayer_ehp_month_max,
      :prayer_xp_year_start,
      :prayer_xp_year_max,
      :prayer_ehp_year_start,
      :prayer_ehp_year_max,
      :magic_xp_day_start,
      :magic_xp_day_max,
      :magic_ehp_day_start,
      :magic_ehp_day_max,
      :magic_xp_week_start,
      :magic_xp_week_max,
      :magic_ehp_week_start,
      :magic_ehp_week_max,
      :magic_xp_month_start,
      :magic_xp_month_max,
      :magic_ehp_month_start,
      :magic_ehp_month_max,
      :magic_xp_year_start,
      :magic_xp_year_max,
      :magic_ehp_year_start,
      :magic_ehp_year_max,
      :cooking_xp_day_start,
      :cooking_xp_day_max,
      :cooking_ehp_day_start,
      :cooking_ehp_day_max,
      :cooking_xp_week_start,
      :cooking_xp_week_max,
      :cooking_ehp_week_start,
      :cooking_ehp_week_max,
      :cooking_xp_month_start,
      :cooking_xp_month_max,
      :cooking_ehp_month_start,
      :cooking_ehp_month_max,
      :cooking_xp_year_start,
      :cooking_xp_year_max,
      :cooking_ehp_year_start,
      :cooking_ehp_year_max,
      :woodcutting_xp_day_start,
      :woodcutting_xp_day_max,
      :woodcutting_ehp_day_start,
      :woodcutting_ehp_day_max,
      :woodcutting_xp_week_start,
      :woodcutting_xp_week_max,
      :woodcutting_ehp_week_start,
      :woodcutting_ehp_week_max,
      :woodcutting_xp_month_start,
      :woodcutting_xp_month_max,
      :woodcutting_ehp_month_start,
      :woodcutting_ehp_month_max,
      :woodcutting_xp_year_start,
      :woodcutting_xp_year_max,
      :woodcutting_ehp_year_start,
      :woodcutting_ehp_year_max,
      :fishing_xp_day_start,
      :fishing_xp_day_max,
      :fishing_ehp_day_start,
      :fishing_ehp_day_max,
      :fishing_xp_week_start,
      :fishing_xp_week_max,
      :fishing_ehp_week_start,
      :fishing_ehp_week_max,
      :fishing_xp_month_start,
      :fishing_xp_month_max,
      :fishing_ehp_month_start,
      :fishing_ehp_month_max,
      :fishing_xp_year_start,
      :fishing_xp_year_max,
      :fishing_ehp_year_start,
      :fishing_ehp_year_max,
      :firemaking_xp_day_start,
      :firemaking_xp_day_max,
      :firemaking_ehp_day_start,
      :firemaking_ehp_day_max,
      :firemaking_xp_week_start,
      :firemaking_xp_week_max,
      :firemaking_ehp_week_start,
      :firemaking_ehp_week_max,
      :firemaking_xp_month_start,
      :firemaking_xp_month_max,
      :firemaking_ehp_month_start,
      :firemaking_ehp_month_max,
      :firemaking_xp_year_start,
      :firemaking_xp_year_max,
      :firemaking_ehp_year_start,
      :firemaking_ehp_year_max,
      :crafting_xp_day_start,
      :crafting_xp_day_max,
      :crafting_ehp_day_start,
      :crafting_ehp_day_max,
      :crafting_xp_week_start,
      :crafting_xp_week_max,
      :crafting_ehp_week_start,
      :crafting_ehp_week_max,
      :crafting_xp_month_start,
      :crafting_xp_month_max,
      :crafting_ehp_month_start,
      :crafting_ehp_month_max,
      :crafting_xp_year_start,
      :crafting_xp_year_max,
      :crafting_ehp_year_start,
      :crafting_ehp_year_max,
      :smithing_xp_day_start,
      :smithing_xp_day_max,
      :smithing_ehp_day_start,
      :smithing_ehp_day_max,
      :smithing_xp_week_start,
      :smithing_xp_week_max,
      :smithing_ehp_week_start,
      :smithing_ehp_week_max,
      :smithing_xp_month_start,
      :smithing_xp_month_max,
      :smithing_ehp_month_start,
      :smithing_ehp_month_max,
      :smithing_xp_year_start,
      :smithing_xp_year_max,
      :smithing_ehp_year_start,
      :smithing_ehp_year_max,
      :mining_xp_day_start,
      :mining_xp_day_max,
      :mining_ehp_day_start,
      :mining_ehp_day_max,
      :mining_xp_week_start,
      :mining_xp_week_max,
      :mining_ehp_week_start,
      :mining_ehp_week_max,
      :mining_xp_month_start,
      :mining_xp_month_max,
      :mining_ehp_month_start,
      :mining_ehp_month_max,
      :mining_xp_year_start,
      :mining_xp_year_max,
      :mining_ehp_year_start,
      :mining_ehp_year_max,
      :runecraft_xp_day_start,
      :runecraft_xp_day_max,
      :runecraft_ehp_day_start,
      :runecraft_ehp_day_max,
      :runecraft_xp_week_start,
      :runecraft_xp_week_max,
      :runecraft_ehp_week_start,
      :runecraft_ehp_week_max,
      :runecraft_xp_month_start,
      :runecraft_xp_month_max,
      :runecraft_ehp_month_start,
      :runecraft_ehp_month_max,
      :runecraft_xp_year_start,
      :runecraft_xp_year_max,
      :runecraft_ehp_year_start,
      :runecraft_ehp_year_max,
      :overall_xp_day_start,
      :overall_xp_day_max,
      :overall_ehp_day_start,
      :overall_ehp_day_max,
      :overall_xp_week_start,
      :overall_xp_week_max,
      :overall_ehp_week_start,
      :overall_ehp_week_max,
      :overall_xp_month_start,
      :overall_xp_month_max,
      :overall_ehp_month_start,
      :overall_ehp_month_max,
      :overall_xp_year_start,
      :overall_xp_year_max,
      :overall_ehp_year_start,
      :overall_ehp_year_max
      )
  end
end
