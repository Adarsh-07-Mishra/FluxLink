class AddQrSettingsToLinks < ActiveRecord::Migration[7.2]
  def change
    add_column :links, :qr_settings, :json
  end
end
