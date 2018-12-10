class CreateTestTables < ActiveRecord::Migration[5.2]
  def change
    create_table :articles do |t|
      t.string :carrierwave_file
      t.json :carrierwave_files
    end
  end
end
