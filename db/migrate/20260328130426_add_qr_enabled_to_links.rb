class AddQrEnabledToLinks < ActiveRecord::Migration[7.2]
  def change
    add_column :links, :qr_enabled, :boolean
  end
end
