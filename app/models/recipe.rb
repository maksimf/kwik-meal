class Recipe < ApplicationRecord
  include PgSearch::Model

  serialize :ingredients, coder: JSON

  pg_search_scope :search_by_ingredients,
    against: [ :ingredients ],
    using: {
      tsearch: {
        prefix: true,
        any_word: true,
        dictionary: "english"
      },
      trigram: {
        threshold: 0.2,
        word_similarity: true
      }
    }

  validates :title, presence: true
  validates :ingredients, presence: true

    def ingredient_match_count(search_ingredients)
    return 0 if search_ingredients.blank? || ingredients.blank?

    search_terms = search_ingredients.map(&:downcase)

    # Handle both String and Array formats for ingredients
    recipe_ingredients_text = if ingredients.is_a?(Array)
      ingredients.join(' ').downcase
    else
      ingredients.to_s.downcase
    end

    search_terms.count do |term|
      recipe_ingredients_text.include?(term)
    end
  end

end
