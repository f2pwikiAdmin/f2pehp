require 'rack/attack'

Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
Rack::Attack.enabled = !Rails.env.test?

Rack::Attack.throttle('clan admin posts per IP', limit: 10, period: 60) do |request|
  if request.post? && request.path.match?(%r{\A/clans/[^/]+/(?:add_player_to_clan|add_many_players_to_clan|remove_player_from_clan|remove_many_players_from_clan|update_clan_description|update_clan_link1|update_clan_link2)\z})
    request.ip
  end
end

Rack::Attack.throttle('admin requests per IP', limit: 5, period: 60) do |request|
  request.ip if request.path.match?(%r{\A/admin(?:/|\z)})
end

Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env['rack.attack.match_data']
  retry_after = match_data[:period] - (match_data[:epoch_time] % match_data[:period])

  [
    429,
    { 'Content-Type' => 'text/plain; charset=utf-8', 'Retry-After' => retry_after.to_s },
    ['Too many requests. Please try again in a minute.']
  ]
end
