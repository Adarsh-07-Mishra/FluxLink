class CreateWifiNetworks < ActiveRecord::Migration[7.2]
  def change
    create_table :wifi_networks do |t|
      t.string :ssid
      t.string :security
      t.string :password
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
