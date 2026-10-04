class Clan < ActiveRecord::Base
  # This model intentionally does not have a way of conveniently adding records.
  # Due to the Heroku 10000 row limit, we need to limit the number of clans, players, and clan links.
  # In order to create a new clan, run the following in the Rails console:
  #    `Clan.create!(name: "Some Clan", symbol_link: "some_clan.png", password: "mypassword")`
  # Legacy MD5 pass values are still supported and upgraded on successful authentication.

  has_secure_password validations: false

  has_many :player_clan_links
  has_many :players, through: :player_clan_links

  def authenticate_pass(candidate)
    return false if candidate.nil? || candidate.empty?
    return authenticate(candidate) if password_digest.present?
    return false unless pass.present? && ActiveSupport::SecurityUtils.secure_compare(pass, Digest::MD5.hexdigest(candidate))
    # Keep full-password verification when bcrypt would truncate a legacy password.
    return self if candidate.bytesize > BCrypt::Engine::MAX_SECRET_BYTESIZE

    self.password = candidate
    update_column(:password_digest, password_digest)
    self
  end

  def self.sanitize_name(str)
    str = ERB::Util.url_encode(str).gsub(/[-_\\+]|(%20)|(%C2%A0)/, " ")
    return str.gsub(/\A[^A-z0-9]+|[^A-z0-9\s\_-]+|[^A-z0-9]+\z/, "")
  end

  def self.find_clan(id)
    id = self.sanitize_name(id)
    splits = id.split(/[\s\_]|(%20)/)
    res = splits.join("_") # _ is a wildcard
    term = res.downcase
    clan = Clan.where("lower(name) LIKE ? AND length(name) = ?", "%#{term}%", term.length).first

    if clan.nil?
      begin
        clan = Clan.find(Float(id))
      rescue
        return false
      end
    end
    return clan
  end

  def add_player(player)
    PlayerClanLink.create({:player_id => player.id, :clan_id => self.id})
  end

  def remove_player(player)
    PlayerClanLink.where(player_id: player.id, clan_id: self.id).destroy_all
  end
end
