require 'net/https'
require 'uri'
require "open-uri"
require 'nokogiri'
require 'will_paginate/array'
require 'logger'

class AdminController < ApplicationController
    before_action :http_basic_auth

    def http_basic_auth
        response.headers['Cache-Control'] = 'no-store'
        response.headers['Referrer-Policy'] = 'no-referrer'
        if ENV['HTTP_AUTH_USER'].present? && ENV['HTTP_AUTH_PASS'].present?
            authenticate_or_request_with_http_basic do |user, password|
                ActiveSupport::SecurityUtils.secure_compare(user, ENV['HTTP_AUTH_USER']) &
                    ActiveSupport::SecurityUtils.secure_compare(password, ENV['HTTP_AUTH_PASS'])
            end
        else
            render plain: "Admin access is not configured. Set HTTP_AUTH_USER and HTTP_AUTH_PASS environment variables.", status: :service_unavailable
        end
    end

    def index
        
    end

    def issue_clan_password_reset
        clan = Clan.find_by(id: params[:clan_id])
        unless clan
            redirect_to admin_path, notice: "Clan not found."
            return
        end

        token = clan.issue_password_reset!
        @reset_path = clan_password_reset_path(id: clan.id, reset_token: token)
        @reset_clan = clan
        Rails.logger.info "Administrator issued password reset for clan ID #{clan.id}"
        render :index
    end

    def add_supporter
        @name = params[:player_supporter]
        x = Player.find_player @name
        if x
            x.update_player
            redirect_to admin_path, notice: "Player #{@name} has been added."
        else
            redirect_to admin_path, notice: "Could not find player #{@name}."
        end
    end

    def fix_spaces
        @name = params[:name_spaces]
        x = Player.find_player @name
        if x
            @name_spaces = x.player_name.force_encoding('ascii')
            @fixed_spaces = @name_spaces.gsub! '\xC2\xA0', ' '
            if (@fixed_spaces)
                x.update(:player_name=>@fixed_spaces)
                redirect_to admin_path, notice: "Player #{@fixed_spaces} has had whitespaces fixed."
            else
                redirect_to admin_path, notice: "Player #{@name_spaces} had no whitespace issues."
            end
        else
            redirect_to admin_path, notice: "Could not find player #{@name}."
        end
    end

    def change_name
        @name1 = params[:name1]
        @name2 = params[:name2]
        x = Player.find_player @name1
        if x
            x.update(:player_name=>@name2)
            redirect_to admin_path, notice: "Name has been updated to #{@name2}."
        else
            redirect_to admin_path, notice: "Could not find player #{@name}."
        end
    end
end
