class RecipesController < ApplicationController
  before_action :set_default_response_format

  # GET /recipes/search
  # Search recipes by ingredients
  # Parameters:
  #   ingredients: array of ingredient names (required)
  #   limit: number of results to return (optional, default: 10)
  def search
    ingredients = validate_and_normalize_ingredients
    return if performed? # Early return if validation failed and response was already rendered

    limit = parse_limit_param
    recipes, search_time = perform_recipe_search(ingredients, limit)

    render json: build_search_response(recipes, ingredients, search_time, limit)
  end



  private

  def validate_and_normalize_ingredients
    ingredients = params[:ingredients]

    if ingredients.blank?
      render json: { error: "Ingredients parameter is required" }, status: :bad_request
      return nil
    end

    # Ensure ingredients is an array
    ingredients = [ ingredients ] unless ingredients.is_a?(Array)

    # Remove empty strings and normalize
    ingredients = ingredients.compact.reject(&:blank?)

    if ingredients.empty?
      render json: { error: "At least one ingredient is required" }, status: :bad_request
      return nil
    end

    ingredients
  end

  def parse_limit_param
    limit = [ params[:limit].to_i, 50 ].min # Cap at 50 results
    limit = 10 if limit <= 0 # Default to 10
    limit
  end

  def perform_recipe_search(ingredients, limit)
    start_time = Time.current
    all_recipes = Recipe.find_by_ingredients(ingredients)
    recipes = all_recipes.first(limit) # Since find_by_ingredients returns Array, use first() instead of limit()
    search_time = ((Time.current - start_time) * 1000).round(2) # Convert to milliseconds

    [ recipes, search_time ]
  end

  def build_search_response(recipes, ingredients, search_time, limit)
    results = recipes.map do |recipe|
      {
        id: recipe.id,
        title: recipe.title,
        cook_time: recipe.cook_time,
        prep_time: recipe.prep_time,
        ingredients: recipe.ingredients,
        ratings: recipe.ratings,
        cuisine: recipe.cuisine,
        category: recipe.category,
        author: recipe.author,
        image: recipe.image
      }
    end

    {
      results: results,
      search_metadata: {
        query_ingredients: ingredients,
        total_results: results.length,
        search_time_ms: search_time,
        limit: limit
      }
    }
  end

  def set_default_response_format
    request.format = :json
  end
end
