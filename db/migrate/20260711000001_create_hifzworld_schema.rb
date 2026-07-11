class CreateHifzworldSchema < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :users, id: :uuid do |t|
      t.string :apple_sub, null: false
      t.string :email
      t.string :handle
      t.string :display_name, null: false
      t.string :avatar_url
      t.timestamps
    end
    add_index :users, :apple_sub, unique: true
    add_index :users, :email
    add_index :users, :handle, unique: true, where: "handle IS NOT NULL"

    create_table :mushaf_bundles, id: :uuid do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :title, null: false
      t.text :description, null: false, default: ""
      t.integer :page_numbers, array: true, default: [], null: false
      t.integer :mushaf_id, null: false, default: 3
      t.timestamps
    end

    create_table :bundle_shares, id: :uuid do |t|
      t.references :mushaf_bundle, null: false, foreign_key: true, type: :uuid
      t.references :shared_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :shared_with, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :status, null: false, default: "pending"
      t.timestamps
    end
    add_index :bundle_shares, [:mushaf_bundle_id, :shared_with_id], unique: true

    create_table :review_sessions, id: :uuid do |t|
      t.references :mushaf_bundle, null: false, foreign_key: true, type: :uuid
      t.references :reciter, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :listener, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :status, null: false, default: "waiting"
      t.string :video_room_id
      t.datetime :started_at
      t.datetime :ended_at
      t.timestamps
    end

    create_table :session_marks, id: :uuid do |t|
      t.references :review_session, null: false, foreign_key: true, type: :uuid
      t.references :mushaf_bundle, null: false, foreign_key: true, type: :uuid
      t.references :listener, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.integer :word_id, null: false
      t.string :verse_key, null: false
      t.integer :page_number, null: false
      t.integer :mushaf_id, null: false
      t.string :mark_type, null: false
      t.text :note
      t.timestamps
    end
  end
end
