class RecipesController < ApplicationController
  before_action :set_default_response_format

  # GET /recipes/search
  # Search recipes by ingredients
  # Parameters:
  #   ingredients: array of ingredient names (required)
  #   limit: number of results to return (optional, default: 10)
  def search
    ingredients = params[:ingredients]

    if ingredients.blank?
      render json: { error: "Ingredients parameter is required" }, status: :bad_request
      return
    end

    # Ensure ingredients is an array
    ingredients = [ingredients] unless ingredients.is_a?(Array)

    # Remove empty strings and normalize
    ingredients = ingredients.compact.reject(&:blank?)

    if ingredients.empty?
      render json: { error: "At least one ingredient is required" }, status: :bad_request
      return
    end

    limit = [params[:limit].to_i, 50].min # Cap at 50 results
    limit = 10 if limit <= 0 # Default to 10

    # Perform the search
    start_time = Time.current
    all_recipes = Recipe.find_by_ingredients(ingredients)
    recipes = all_recipes.first(limit) # Since find_by_ingredients returns Array, use first() instead of limit()
    search_time = ((Time.current - start_time) * 1000).round(2) # Convert to milliseconds

    # Format response
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

    render json: {
      results: results,
      search_metadata: {
        query_ingredients: ingredients,
        total_results: results.length,
        search_time_ms: search_time,
        limit: limit
      }
    }
  end

  # GET /recipes
  # List all recipes with pagination
  def index
    page = [params[:page].to_i, 1].max
    per_page = [params[:per_page].to_i, 20].min
    per_page = 10 if per_page <= 0

    recipes = Recipe.order(:title).limit(per_page).offset((page - 1) * per_page)
    total_count = Recipe.count

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

    render json: {
      results: results,
      pagination: {
        current_page: page,
        per_page: per_page,
        total_pages: (total_count.to_f / per_page).ceil,
        total_count: total_count
      }
    }
  end

  private

  def set_default_response_format
    request.format = :json
  end
end
