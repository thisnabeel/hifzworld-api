class CreateHeats < ActiveRecord::Migration[8.1]
  def change
    add_column :mushaf_marks, :heats_count, :integer, null: false, default: 0

    create_table :heats, id: :uuid do |t|
      t.references :mushaf_mark, null: false, foreign_key: true, type: :uuid
      t.references :recorded_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.timestamps
    end

    add_index :heats, [:mushaf_mark_id, :created_at]
  end
end
