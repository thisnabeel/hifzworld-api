class CreateScanPageStatuses < ActiveRecord::Migration[8.1]
  def change
    create_table :scan_page_statuses, id: :uuid do |t|
      t.string :mushaf_key, null: false
      t.integer :page, null: false
      t.boolean :ready, null: false, default: false
      t.timestamps
    end

    add_index :scan_page_statuses, [:mushaf_key, :page], unique: true
  end
end
