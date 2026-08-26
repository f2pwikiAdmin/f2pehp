class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private

  # Sanitize @skill to prevent SQL injection — allow only lowercase letters, digits, underscores
  # starting with a letter (mirrors the existing guard in the ranks action).
  def sanitize_skill
    unless @skill.is_a?(String) && @skill.match?(/\A[a-z][a-z0-9_]*\z/)
      @skill = "overall"
      params[:skill] = "overall"
      session[:skill] = "overall"
    end
  end

  # Sanitize @time against a strict allowlist to prevent SQL injection.
  def sanitize_time
    unless %w[day week month year].include?(@time)
      @time = "week"
      params[:time] = "week"
      session[:time] = "week"
    end
  end
end
