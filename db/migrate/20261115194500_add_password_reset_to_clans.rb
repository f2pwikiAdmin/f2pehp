class AddPasswordResetToClans < ActiveRecord::Migration[7.0]
  def change
    add_column :clans, :password_reset_digest, :string
    add_column :clans, :password_reset_sent_at, :datetime
  end
end
