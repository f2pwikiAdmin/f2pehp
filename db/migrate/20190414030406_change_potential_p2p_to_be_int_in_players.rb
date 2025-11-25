class ChangePotentialP2pToBeIntInPlayers < ActiveRecord::Migration[4.2]
  def change
    change_column :players, :potential_p2p, :float, using: 'potential_p2p::double precision'
  end
end
