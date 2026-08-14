class CreateTranslationSets < ActiveRecord::Migration[8.1]
  def change
    create_table :translation_sets, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :language, null: false
      t.string :translator, null: false
      t.string :display_name, null: false
      t.boolean :is_default, null: false, default: false
      t.timestamps
    end

    add_index :translation_sets, [:language, :translator], unique: true
    add_index :translation_sets, :is_default, unique: true, where: "is_default = TRUE"

    create_table :verse_translations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :translation_set, null: false, foreign_key: true, type: :uuid
      t.string :verse_key, null: false
      t.text :text, null: false
      t.timestamps
    end

    add_index :verse_translations, [:translation_set_id, :verse_key], unique: true
  end
end
