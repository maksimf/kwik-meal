# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_30_105810) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "recipes", force: :cascade do |t|
    t.string "title"
    t.integer "cook_time"
    t.integer "prep_time"
    t.text "ingredients"
    t.decimal "ratings"
    t.string "cuisine"
    t.string "category"
    t.string "author"
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "to_tsvector('english'::regconfig, ingredients)", name: "index_recipes_on_ingredients_tsvector_gin", using: :gin
    t.index ["category"], name: "index_recipes_on_category"
    t.index ["ingredients"], name: "index_recipes_on_ingredients_gin", opclass: :gin_trgm_ops, using: :gin
    t.index ["ratings"], name: "index_recipes_on_ratings"
    t.index ["title"], name: "index_recipes_on_title"
  end
end
