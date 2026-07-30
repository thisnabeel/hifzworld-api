class CreateFriendships < ActiveRecord::Migration[8.1]
  def change
    create_table :friendships, id: :uuid do |t|
      t.references :requester, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :recipient, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :status, null: false, default: "pending"
      t.timestamps
    end

    add_index :friendships, [:requester_id, :recipient_id], unique: true
    add_index :friendships, :recipient_id
    add_index :friendships, :status
  end
end
