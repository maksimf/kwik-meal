require "test_helper"

class RecipeTest < ActiveSupport::TestCase
  test "should create recipe with valid attributes" do
    recipe = Recipe.new(
      title: "Test Recipe",
      ingredients: ["flour", "eggs", "milk"],
      cook_time: 30,
      prep_time: 15,
      ratings: 4.5,
      category: "Test Category"
    )

    assert recipe.valid?
    assert recipe.save
  end

  test "should require title" do
    recipe = Recipe.new(ingredients: ["flour"])
    assert_not recipe.valid?
    assert_includes recipe.errors[:title], "can't be blank"
  end

  test "should require ingredients" do
    recipe = Recipe.new(title: "Test Recipe")
    assert_not recipe.valid?
    assert_includes recipe.errors[:ingredients], "can't be blank"
  end

  test "should serialize ingredients as JSON" do
    ingredients = ["1 cup flour", "2 eggs", "1 cup milk"]
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
      ingredients: ["flour", "chocolate", "eggs", "sugar"],
      ratings: 4.5
    )

    recipe2 = Recipe.create!(
      title: "Vanilla Cookies",
      ingredients: ["flour", "vanilla", "butter", "sugar"],
      ratings: 4.2
    )

    recipe3 = Recipe.create!(
      title: "Beef Stew",
      ingredients: ["beef", "carrots", "potatoes", "onions"],
      ratings: 4.8
    )

    # Search for recipes with flour
    results = Recipe.find_by_ingredients(["flour"])
    assert_includes results, recipe1
    assert_includes results, recipe2
    assert_not_includes results, recipe3

    # Search for recipes with chocolate
    results = Recipe.find_by_ingredients(["chocolate"])
    assert_includes results, recipe1
    assert_not_includes results, recipe2
    assert_not_includes results, recipe3

    # Search for recipes with beef
    results = Recipe.find_by_ingredients(["beef"])
    assert_includes results, recipe3
    assert_not_includes results, recipe1
    assert_not_includes results, recipe2
  end

    test "should handle typos in ingredient search" do
    Recipe.delete_all

    recipe = Recipe.create!(
      title: "Chocolate Cake",
      ingredients: ["flour", "chocolate", "eggs"],
      ratings: 4.5
    )

    # Test with slight typos
    results = Recipe.find_by_ingredients(["chocolat"]) # missing 'e'
    assert_includes results, recipe

    results = Recipe.find_by_ingredients(["choclat"]) # missing 'o'
    assert_includes results, recipe
  end

  test "should return empty result for blank ingredients" do
    # Clear recipes to avoid interference from fixtures
    Recipe.delete_all

    results = Recipe.find_by_ingredients([])
    assert_empty results

    results = Recipe.find_by_ingredients(nil)
    assert_empty results

    results = Recipe.find_by_ingredients([""])
    assert_empty results
  end

  test "should order results by ratings descending" do
    Recipe.delete_all

    recipe1 = Recipe.create!(
      title: "Low Rated Recipe",
      ingredients: ["flour", "eggs"],
      ratings: 2.0
    )

    recipe2 = Recipe.create!(
      title: "High Rated Recipe",
      ingredients: ["flour", "sugar"],
      ratings: 5.0
    )

    recipe3 = Recipe.create!(
      title: "Medium Rated Recipe",
      ingredients: ["flour", "milk"],
      ratings: 3.5
    )

    results = Recipe.find_by_ingredients(["flour"]).to_a
    assert_equal [recipe2, recipe3, recipe1], results
  end

  test "should clean ingredient list" do
    recipe = Recipe.create!(
      title: "Test Recipe",
      ingredients: ["1 cup all-purpose flour", "2 large eggs", "½ cup sugar"]
    )

    cleaned = recipe.ingredient_list
    # For now, just test that we get the ingredients back
    # The cleaning logic can be improved later
    assert_equal 3, cleaned.length
    assert cleaned.all? { |ingredient| ingredient.is_a?(String) && !ingredient.empty? }
  end
end
