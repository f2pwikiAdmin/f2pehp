class AddP2pCheckReasonToPlayers < ActiveRecord::Migration[5.0]
  def change
    add_column :players, :p2p_check_reason, :string
  end
end
