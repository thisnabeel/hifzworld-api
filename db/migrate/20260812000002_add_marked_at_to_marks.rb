class AddMarkedAtToMarks < ActiveRecord::Migration[8.1]
  def change
    add_column :mushaf_marks, :marked_at, :datetime
    add_index :mushaf_marks, :marked_at

    add_column :session_marks, :marked_at, :datetime
    add_index :session_marks, :marked_at

    reversible do |dir|
      dir.up do
        execute "UPDATE mushaf_marks SET marked_at = created_at WHERE marked_at IS NULL"
        execute "UPDATE session_marks SET marked_at = created_at WHERE marked_at IS NULL"
      end
    end
  end
end
