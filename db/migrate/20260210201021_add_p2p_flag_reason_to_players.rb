class AddP2pFlagReasonToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :p2p_flag_reason, :string
  end
end
