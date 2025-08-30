class AddGinIndexToRecipesIngredients < ActiveRecord::Migration[8.0]
  def change
    # Enable the pg_trgm extension if not already enabled
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')

    # Add GIN index for full-text search on ingredients
    add_index :recipes, :ingredients,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: 'index_recipes_on_ingredients_gin'

    # Also add a tsvector GIN index for tsearch
    execute <<-SQL
      CREATE INDEX index_recipes_on_ingredients_tsvector_gin
      ON recipes
      USING GIN (to_tsvector('english', ingredients));
    SQL
  end

  def down
    remove_index :recipes, name: 'index_recipes_on_ingredients_gin'
    execute "DROP INDEX IF EXISTS index_recipes_on_ingredients_tsvector_gin;"
  end
end
