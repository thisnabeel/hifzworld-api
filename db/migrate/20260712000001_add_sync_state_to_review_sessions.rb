class AddSyncStateToReviewSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :review_sessions, :current_page, :integer
    add_column :review_sessions, :page_hidden, :boolean, null: false, default: false
  end
end
