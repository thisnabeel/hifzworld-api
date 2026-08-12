class AddUnmarkedAtToMarks < ActiveRecord::Migration[8.1]
  def change
    add_column :mushaf_marks, :unmarked_at, :datetime
    add_index :mushaf_marks, :unmarked_at

    add_column :session_marks, :unmarked_at, :datetime
    add_index :session_marks, :unmarked_at
  end
end
