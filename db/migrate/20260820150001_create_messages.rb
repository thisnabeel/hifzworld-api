class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages, id: :uuid do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }, type: :uuid, index: true
      t.references :recipient, null: false, foreign_key: { to_table: :users }, type: :uuid, index: true
      t.text :body, null: false
      t.integer :page_numbers, array: true, null: false, default: []
      t.integer :mushaf_id, null: false
      t.datetime :read_at
      t.timestamps
    end

    add_index :messages, [:recipient_id, :read_at]
    add_index :messages, [:recipient_id, :created_at]
  end
end
