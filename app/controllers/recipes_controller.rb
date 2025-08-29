class RecipesController < ApplicationController
  INGREDIENTS_LIMIT = 50

  def search
    ingredients = validate_and_normalize_ingredients
    return if performed?

    limit = params[:limit] ? params[:limit].to_i : INGREDIENTS_LIMIT
    recipes, search_time = perform_recipe_search(ingredients, limit)

    render json: {
      results: recipes.map { |recipe| serialize_recipe(recipe) },
      search_metadata: {
        query_ingredients: ingredients,
        total_results: recipes.length,
        search_time_ms: search_time,
        limit: limit
      }
    }
  end

  private

  def validate_and_normalize_ingredients
    ingredients = params[:ingredients]

    if ingredients.blank?
      render json: { error: "Ingredients parameter is required" }, status: :bad_request
      return nil
    end

    ingredients = [ ingredients ] unless ingredients.is_a?(Array)

    ingredients = ingredients.compact.reject(&:blank?)

    if ingredients.empty?
      render json: { error: "At least one ingredient is required" }, status: :bad_request
      return nil
    end

    ingredients
  end

  def perform_recipe_search(ingredients, limit = INGREDIENTS_LIMIT)
    start_time = Time.current
    search_query = ingredients.join(" ")
    recipes = Recipe.search_by_ingredients(search_query)
                    .order(ratings: :desc)
                    .limit(limit)
    search_time = ((Time.current - start_time) * 1000).round(2)

    [ recipes, search_time ]
  end

  def serialize_recipe(recipe)
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
end
