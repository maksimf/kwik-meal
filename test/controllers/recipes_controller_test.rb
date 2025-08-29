require "test_helper"

class RecipesControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Clear all recipes to avoid interference with fixtures
    Recipe.delete_all

    # Create test recipes
    @recipe1 = Recipe.create!(
      title: "Chocolate Cake",
      ingredients: [ "flour", "chocolate", "eggs", "sugar" ],
      cook_time: 45,
      prep_time: 20,
      ratings: 4.5,
      category: "Dessert",
      author: "Test Chef"
    )

    @recipe2 = Recipe.create!(
      title: "Vanilla Cookies",
      ingredients: [ "flour", "vanilla", "butter", "sugar" ],
      cook_time: 25,
      prep_time: 15,
      ratings: 4.2,
      category: "Cookies",
      author: "Baker"
    )

    @recipe3 = Recipe.create!(
      title: "Beef Stew",
      ingredients: [ "beef", "carrots", "potatoes", "onions" ],
      cook_time: 120,
      prep_time: 30,
      ratings: 4.8,
      category: "Main Course",
      author: "Chef John"
    )
  end

  test "should search recipes by single ingredient" do
    get search_recipes_path, params: { ingredients: [ "flour" ] }

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["results"].present?
    assert json_response["search_metadata"].present?

    # Should find recipes with flour
    titles = json_response["results"].map { |r| r["title"] }
    assert_includes titles, "Chocolate Cake"
    assert_includes titles, "Vanilla Cookies"
    assert_not_includes titles, "Beef Stew"

    # Check metadata
    metadata = json_response["search_metadata"]
    assert_equal [ "flour" ], metadata["query_ingredients"]
    assert metadata["search_time_ms"].present?
    assert_equal 2, metadata["total_results"]
  end

  test "should search recipes by multiple ingredients" do
    get search_recipes_path, params: { ingredients: [ "flour", "sugar" ] }

    assert_response :success

    json_response = JSON.parse(response.body)
    titles = json_response["results"].map { |r| r["title"] }

    # Should find recipes that contain flour OR sugar
    assert_includes titles, "Chocolate Cake"
    assert_includes titles, "Vanilla Cookies"
  end

  test "should handle single ingredient as string" do
    get search_recipes_path, params: { ingredients: "chocolate" }

    assert_response :success

    json_response = JSON.parse(response.body)
    titles = json_response["results"].map { |r| r["title"] }

    assert_includes titles, "Chocolate Cake"
    assert_not_includes titles, "Vanilla Cookies"
    assert_not_includes titles, "Beef Stew"
  end

  test "should return error for missing ingredients parameter" do
    get search_recipes_path

    assert_response :bad_request

    json_response = JSON.parse(response.body)
    assert_equal "Ingredients parameter is required", json_response["error"]
  end

  test "should return error for empty ingredients" do
    get search_recipes_path, params: { ingredients: [ "" ] }

    assert_response :bad_request

    json_response = JSON.parse(response.body)
    assert_equal "At least one ingredient is required", json_response["error"]
  end

  test "should limit search results" do
    get search_recipes_path, params: { ingredients: [ "flour" ], limit: 1 }

    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal 1, json_response["results"].length
    assert_equal 1, json_response["search_metadata"]["limit"]
  end

  test "should handle typos in ingredients" do
    get search_recipes_path, params: { ingredients: [ "chocolat" ] } # missing 'e'

    assert_response :success

    json_response = JSON.parse(response.body)

    # Should still find chocolate cake due to trigram search
    titles = json_response["results"].map { |r| r["title"] }
    assert_includes titles, "Chocolate Cake"
  end

  test "should return recipes ordered by rating" do
    get search_recipes_path, params: { ingredients: [ "flour" ] }

    assert_response :success

    json_response = JSON.parse(response.body)
    ratings = json_response["results"].map { |r| r["ratings"] }

    # Should be ordered by rating descending
    assert_equal ratings.sort.reverse, ratings
  end

  test "should include all recipe fields in response" do
    get search_recipes_path, params: { ingredients: [ "chocolate" ] }

    assert_response :success

    json_response = JSON.parse(response.body)
    recipe = json_response["results"].first

    assert recipe["id"].present?
    assert recipe["title"].present?
    assert recipe["cook_time"].present?
    assert recipe["prep_time"].present?
    assert recipe["ingredients"].present?
    assert recipe["ratings"].present?
    assert recipe["category"].present?
    assert recipe["author"].present?
  end
end
