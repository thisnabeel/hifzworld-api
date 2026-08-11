class AddLineWordToMarks < ActiveRecord::Migration[8.1]
  def change
    change_table :session_marks, bulk: true do |t|
      t.integer :line_number
      t.integer :word_position
    end

    change_table :mushaf_marks, bulk: true do |t|
      t.integer :line_number
      t.integer :word_position
    end
  end
end
