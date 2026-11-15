class ClanPasswordResetsController < ApplicationController
  before_action :load_reset

  def edit
    render :edit, layout: false
  end

  def update
    if @clan.reset_password(
      token: params[:reset_token],
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )
      Rails.logger.info "Password reset completed for clan ID #{@clan.id}"
      redirect_to clan_admin_path(id: @clan.id), notice: "Password reset successfully. Use your new password to manage the clan."
    else
      render :edit, layout: false, status: :unprocessable_entity
    end
  end

  private

  def load_reset
    response.headers['Cache-Control'] = 'no-store'
    response.headers['Referrer-Policy'] = 'no-referrer'
    response.headers['X-Robots-Tag'] = 'noindex, nofollow'
    @clan = Clan.find_by(id: params[:id])
    return if @clan&.valid_password_reset?(params[:reset_token])

    render plain: "This reset link is invalid or expired. Ask the site administrator for a new one.",
      status: :unprocessable_entity
  end
end
