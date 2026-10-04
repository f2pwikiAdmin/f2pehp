class AddPasswordDigestToClans < ActiveRecord::Migration[7.0]
  def change
    add_column :clans, :password_digest, :string
  end
end
