class CreateMushafMarks < ActiveRecord::Migration[8.1]
  def change
    create_table :mushaf_marks, id: :uuid do |t|
      t.references :subject, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :marker, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.integer :word_id, null: false
      t.string :verse_key, null: false
      t.integer :page_number, null: false
      t.integer :mushaf_id, null: false
      t.string :mark_type, null: false
      t.text :note
      t.timestamps
    end

    add_index :mushaf_marks, [:subject_id, :created_at]
    add_index :mushaf_marks, [:marker_id, :created_at]
    add_index :mushaf_marks, [:subject_id, :page_number]
    add_index :mushaf_marks, [:subject_id, :mushaf_id, :word_id], unique: true, name: "index_mushaf_marks_unique_word"
  end
end
