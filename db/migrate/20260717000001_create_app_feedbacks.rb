class CreateAppFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :app_feedbacks, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: true
      t.text :message, null: false
      t.string :email
      t.string :category, default: "other", null: false
      t.timestamps
    end
  end
end
