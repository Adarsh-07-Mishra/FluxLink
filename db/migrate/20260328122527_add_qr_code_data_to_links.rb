class AddQrCodeDataToLinks < ActiveRecord::Migration[7.2]
  def change
    add_column :links, :qr_code_data, :text
  end
end
