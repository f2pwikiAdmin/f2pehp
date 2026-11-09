require 'net/https'
require 'uri'
require "open-uri"
require 'nokogiri'
require 'will_paginate/array'

class ClansController < ApplicationController
  before_action :set_clan, only: %i[show edit update destroy]

  def admin
    @clan = params[:id]
  end

  def add_player_to_clan
    clan_name = params[:id]
    clan = Clan.find_clan(clan_name)
    clan_id = clan.id

    player = Player.find_player(params[:player_name])

    if !clan.authenticate_pass(params[:pass])
      redirect_to(clan_admin_path, notice: "Incorrect password. Please try again.")
    elsif player and clan.players.pluck(:player_id).include?(player.id)
      redirect_to clan_admin_path, notice: "#{player.player_name} is already in #{clan_name.gsub("_", " ")}."
    elsif player
      clan.add_player(player)
      redirect_to clan_admin_path, notice: "#{player.player_name} added to #{clan_name.gsub("_", " ")}."
    else
      redirect_to clan_admin_path, notice: "Could not find player #{params[:player_name]}."
    end
  end

  def add_many_players_to_clan
    clan_name = params[:id]
    clan = Clan.find_clan(clan_name)
    clan_id = clan.id

    updated_players = []
    failed_players = []
    redundant_players = []

    player_names = params[:player_names].split(",")
    if !clan.authenticate_pass(params[:pass])
      redirect_to(clan_admin_path, notice: "Incorrect password. Please try again.")
      return
    elsif player_names.size > 100
      redirect_to(clan_admin_path, notice: "Too many players. Please try again with fewer than 100 players.")
      return
    end

    player_names.each do |player_name|
      player = Player.find_player(player_name)
      if player and clan.players.pluck(:player_id).include?(player.id)
        redundant_players += [player.player_name]
      elsif player
        clan.add_player(player)
        updated_players += [player.player_name]
      else
        failed_players += [player_name]
      end
    end

    notice_msg =  "Players added to #{clan_name.gsub("_", " ")}: #{updated_players}"
    notice_msg += "\nPlayers not found: #{failed_players}"
    notice_msg += "\nPlayers already in #{clan_name.gsub("_", " ")}: #{redundant_players}"

    redirect_to clan_admin_path, notice: notice_msg
  end

  def remove_player_from_clan
    clan_name = params[:id]
    clan = Clan.find_clan(clan_name)
    clan_id = clan.id

    player = Player.find_player(params[:player_name])

    if !clan.authenticate_pass(params[:pass])
      redirect_to(clan_admin_path, notice: "Incorrect password. Please try again.")
    elsif player and clan.players.pluck(:player_id).include?(player.id)
      clan.remove_player(player)
      redirect_to clan_admin_path, notice: "#{player.player_name} removed from #{clan_name.gsub("_", " ")}."
    else
      redirect_to clan_admin_path, notice: "Player #{params[:player_name]} not found, or not in #{clan_name.gsub("_", " ")}."
    end
  end

  def remove_many_players_from_clan
    clan_name = params[:id]
    clan = Clan.find_clan(clan_name)
    clan_id = clan.id

    updated_players = []
    failed_players = []

    player_names = params[:player_names].split(",")
    if !clan.authenticate_pass(params[:pass])
      redirect_to(clan_admin_path, notice: "Incorrect password. Please try again.")
      return
    elsif player_names.size > 100
      redirect_to(clan_admin_path, notice: "Too many players. Please try again with fewer than 100 players.")
      return
    end

    player_names.each do |player_name|
      player = Player.find_player(player_name)
      if player and clan.players.pluck(:player_id).include?(player.id)
        clan.remove_player(player)
        updated_players += [player.player_name]
      else
        failed_players += [player_name]
      end
    end

    notice_msg =  "Players been removed from #{clan_name.gsub("_", " ")}: #{updated_players}"
    notice_msg += "\nPlayers not found, or are not in the clan: #{failed_players}"

    redirect_to clan_admin_path, notice: notice_msg
  end

  def set_default_description
    @default_description = 'F2P.wiki is an open source Old School RuneScape hiscores for Free-to-play players. It also includes EHP tracking, information about meta changes, and various F2P Old School RuneScape tools.'
  end
  before_action :set_default_description

  def index
    @clans = Clan.all
  end

  def show
    id = params[:search] || params[:id]
    @clan = Clan.find_clan(id)

    unless @clan
      redirect_to clans_path, notice: "Clan '#{id}' not found."
      return
    end

    filters = player_listing_filters(:clan)
    load_player_listing(base: @clan.players, filters: filters)
    @clan
  end

  def update_clan_description
    clan_name = params[:id]
    clan = Clan.find_clan(clan_name)
    clan_id = clan.id

    if !clan.authenticate_pass(params[:pass])
      redirect_to(clan_admin_path, notice: "Incorrect password. Please try again.")
    elsif params[:clan_description].size > 1000
      redirect_to clan_admin_path, notice: "Description is too long. Please limit to 1000 characters."
    else
      clan.update(:description => ActiveRecord::Base.sanitize_sql(params[:clan_description]))
      redirect_to clan_admin_path, notice: "Clan description updated successfully."
    end
  end

  def update_clan_link1
    clan_name = params[:id]
    clan = Clan.find_clan(clan_name)
    clan_id = clan.id

    if !clan.authenticate_pass(params[:pass])
      redirect_to(clan_admin_path, notice: "Incorrect password. Please try again.")
    elsif params[:link1].empty? or params[:link1_name].empty?
      redirect_to clan_admin_path, notice: "Link URL and label must not be empty."
    elsif !params[:link1].include?("http")
      redirect_to clan_admin_path, notice: "Sorry, the link URL must start with 'http' or 'https'."
    elsif params[:link1].size > 500 or params[:link1_name].size > 500
      redirect_to clan_admin_path, notice: "Link URL or label are invalid (too long). Please limit to 500 characters."
    else
      clan.update(:link1 => ActiveRecord::Base.sanitize_sql(params[:link1]), :link1_name => ActiveRecord::Base.sanitize_sql(params[:link1_name]))
      redirect_to clan_admin_path, notice: "Clan link updated successfully."
    end
  end

  def update_clan_link2
    clan_name = params[:id]
    clan = Clan.find_clan(clan_name)
    clan_id = clan.id

    if !clan.authenticate_pass(params[:pass])
      redirect_to(clan_admin_path, notice: "Incorrect password. Please try again.")
    elsif params[:link2].empty? or params[:link2_name].empty?
      redirect_to clan_admin_path, notice: "Link URL and label must not be empty."
    elsif !params[:link2].include?("http")
      redirect_to clan_admin_path, notice: "Sorry, the link URL must start with 'http' or 'https'."
    elsif params[:link2].size > 500 or params[:link2_name].size > 500
      redirect_to clan_admin_path, notice: "Link URL or label are invalid (too long). Please limit to 500 characters."
    else
      clan.update(:link2 => ActiveRecord::Base.sanitize_sql(params[:link2]), :link2_name => ActiveRecord::Base.sanitize_sql(params[:link2_name]))
      redirect_to clan_admin_path, notice: "Clan link updated successfully."
    end
  end

  def create
  end

  def update
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_clan
      show
    end

    def clan_params
      params.require(:clan).permit(:name)
    end
end
