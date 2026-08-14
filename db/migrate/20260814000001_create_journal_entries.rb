class CreateJournalEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :journal_entries, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.date :entry_date, null: false
      t.text :body, null: false, default: ""
      t.string :time_zone, null: false
      t.timestamps
    end

    add_index :journal_entries, [:user_id, :entry_date], unique: true
  end
end
