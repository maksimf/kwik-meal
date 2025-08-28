class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.string :title
      t.integer :cook_time
      t.integer :prep_time
      t.text :ingredients
      t.decimal :ratings
      t.string :cuisine
      t.string :category
      t.string :author
      t.string :image

      t.timestamps
    end

    # Add indexes for search performance
    add_index :recipes, :title
    add_index :recipes, :category
    add_index :recipes, :ratings

    # Enable pg_trgm extension for trigram search
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")
  end
end
