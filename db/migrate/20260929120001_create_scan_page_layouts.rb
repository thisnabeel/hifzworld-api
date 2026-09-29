class CreateScanPageLayouts < ActiveRecord::Migration[8.1]
  def change
    create_table :scan_page_layouts, id: :uuid do |t|
      t.string :mushaf_key, null: false
      t.integer :page, null: false
      t.jsonb :tiles, null: false, default: []
      t.timestamps
    end

    add_index :scan_page_layouts, [:mushaf_key, :page], unique: true
  end
end
