require "test_helper"

class RecipeTest < ActiveSupport::TestCase
  test "should create recipe with valid attributes" do
    recipe = Recipe.new(
      title: "Test Recipe",
      ingredients: [ "flour", "eggs", "milk" ],
      cook_time: 30,
      prep_time: 15,
      ratings: 4.5,
      category: "Test Category"
    )

    assert recipe.valid?
    assert recipe.save
  end

  test "should require title" do
    recipe = Recipe.new(ingredients: [ "flour" ])
    assert_not recipe.valid?
    assert_includes recipe.errors[:title], "can't be blank"
  end

  test "should require ingredients" do
    recipe = Recipe.new(title: "Test Recipe")
    assert_not recipe.valid?
    assert_includes recipe.errors[:ingredients], "can't be blank"
  end

  test "should serialize ingredients as JSON" do
    ingredients = [ "1 cup flour", "2 eggs", "1 cup milk" ]
    recipe = Recipe.create!(
      title: "Test Recipe",
      ingredients: ingredients
    )

    # Reload from database
    recipe.reload
    assert_equal ingredients, recipe.ingredients
  end

  test "should find recipes by ingredients" do
    # Clear existing recipes
    Recipe.delete_all

    # Create test recipes
    recipe1 = Recipe.create!(
      title: "Chocolate Cake",
      ingredients: [ "flour", "chocolate", "eggs", "sugar" ],
      ratings: 4.5
    )

    recipe2 = Recipe.create!(
      title: "Vanilla Cookies",
      ingredients: [ "flour", "vanilla", "butter", "sugar" ],
      ratings: 4.2
    )

    recipe3 = Recipe.create!(
      title: "Beef Stew",
      ingredients: [ "beef", "carrots", "potatoes", "onions" ],
      ratings: 4.8
    )

    # Search for recipes with flour
    results = Recipe.search_by_ingredients("flour").to_a
    assert_includes results, recipe1
    assert_includes results, recipe2
    assert_not_includes results, recipe3

    # Search for recipes with chocolate
    results = Recipe.search_by_ingredients("chocolate").to_a
    assert_includes results, recipe1
    assert_not_includes results, recipe2
    assert_not_includes results, recipe3

    # Search for recipes with beef
    results = Recipe.search_by_ingredients("beef").to_a
    assert_includes results, recipe3
    # Note: fuzzy search might match other recipes, so just ensure beef stew is found
    assert results.any? { |r| r.title == "Beef Stew" }
  end

    test "should handle typos in ingredient search" do
    Recipe.delete_all

    recipe = Recipe.create!(
      title: "Chocolate Cake",
      ingredients: [ "flour", "chocolate", "eggs" ],
      ratings: 4.5
    )

    # Test with slight typos
    results = Recipe.search_by_ingredients("chocolat").to_a # missing 'e'
    assert_includes results, recipe

    results = Recipe.search_by_ingredients("choclat").to_a # missing 'o'
    assert_includes results, recipe
  end

  test "should return empty result for blank ingredients" do
    # Clear recipes to avoid interference from fixtures
    Recipe.delete_all

    results = Recipe.search_by_ingredients("").to_a
    assert_empty results

    results = Recipe.search_by_ingredients(nil).to_a
    assert_empty results

    results = Recipe.search_by_ingredients(" ").to_a
    assert_empty results
  end

  test "should be able to order results by ratings" do
    Recipe.delete_all

    recipe1 = Recipe.create!(
      title: "Low Rated Recipe",
      ingredients: [ "flour", "eggs" ],
      ratings: 2.0
    )

    recipe2 = Recipe.create!(
      title: "High Rated Recipe",
      ingredients: [ "flour", "sugar" ],
      ratings: 5.0
    )

    recipe3 = Recipe.create!(
      title: "Medium Rated Recipe",
      ingredients: [ "flour", "milk" ],
      ratings: 3.5
    )

    # pg_search orders by relevance by default, but we can chain order
    results = Recipe.search_by_ingredients("flour").reorder(ratings: :desc).to_a
    assert_equal [ recipe2, recipe3, recipe1 ], results
  end

  test "should store ingredients as array" do
    recipe = Recipe.create!(
      title: "Test Recipe",
      ingredients: [ "1 cup all-purpose flour", "2 large eggs", "½ cup sugar" ]
    )

    # Test that ingredients are stored correctly as an array
    assert_equal 3, recipe.ingredients.length
    assert recipe.ingredients.all? { |ingredient| ingredient.is_a?(String) && !ingredient.empty? }
  end
end
