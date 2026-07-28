class CreateDeckInvites < ActiveRecord::Migration[8.1]
  def change
    create_table :deck_invites, id: :uuid do |t|
      t.references :mushaf_bundle, null: false, foreign_key: true, type: :uuid
      t.references :created_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :token, null: false
      t.datetime :revoked_at
      t.timestamps
    end

    add_index :deck_invites, :token, unique: true
    add_index :deck_invites, :mushaf_bundle_id, unique: true, where: "revoked_at IS NULL", name: "index_deck_invites_active_per_bundle"
  end
end
