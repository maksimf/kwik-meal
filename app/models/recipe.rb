class Recipe < ApplicationRecord
  include PgSearch::Model

  # Serialize ingredients as JSON array
  serialize :ingredients, coder: JSON

  # Exact and prefix search (fast, for correct spellings)
  pg_search_scope :search_by_ingredients_exact,
    against: :ingredients,
    using: {
      tsearch: {
        prefix: true,
        any_word: true,
        dictionary: "english"
      }
    }

  # Fuzzy search (slower, for typos)
  pg_search_scope :search_by_ingredients_fuzzy,
    against: :ingredients,
    using: {
      trigram: {
        threshold: 0.3
      }
    }

  # Combined search for title, ingredients, and category
  pg_search_scope :search_all,
    against: [:title, :ingredients, :category],
    using: {
      tsearch: {
        prefix: true,
        any_word: true,
        dictionary: "english"
      },
      trigram: {
        threshold: 0.3
      }
    }

  validates :title, presence: true
  validates :ingredients, presence: true

  # Custom method to find recipes by ingredient list with improved typo handling
  def self.find_by_ingredients(ingredient_list)
    return [] if ingredient_list.blank?

    # Convert ingredients to lowercase for better matching
    search_terms = ingredient_list.map(&:strip).map(&:downcase)

    all_results = []

    search_terms.each do |term|
      # First try exact substring search in the ingredients JSON
      exact_results = where("LOWER(ingredients) LIKE ?", "%#{term}%")
      all_results.concat(exact_results.to_a)

      # For better typo handling, let's try different variations
      # This handles common typos by checking character similarity
      if exact_results.count < 5
        # Try fuzzy matching with common substitutions and character removal
        fuzzy_patterns = generate_fuzzy_patterns(term)

        fuzzy_patterns.each do |pattern|
          fuzzy_results = where("LOWER(ingredients) LIKE ?", "%#{pattern}%").limit(20)
          all_results.concat(fuzzy_results.to_a)
        end
      end
    end

    # Remove duplicates and order by rating
    unique_recipes = all_results.uniq(&:id)
    unique_recipes.sort_by { |r| -r.ratings.to_f }
  end

  # Generate fuzzy search patterns for typo handling
  def self.generate_fuzzy_patterns(term)
    patterns = []

    # Handle common typos:
    # 1. Missing characters (choclat -> chocolate)
    if term.length > 5
      (0...term.length).each do |i|
        pattern = term.dup
        pattern.insert(i, '_') # Use _ as single character wildcard
        patterns << pattern.gsub('_', '%')
      end
    end

    # 2. Extra characters (chocolaate -> chocolate)
    if term.length > 4
      (0...term.length).each do |i|
        pattern = term.dup
        pattern[i] = '%' # Replace character with wildcard
        patterns << pattern
      end
    end

    # 3. Transposed characters (choclate -> chocolate)
    (0...term.length-1).each do |i|
      pattern = term.dup
      pattern[i], pattern[i+1] = pattern[i+1], pattern[i]
      patterns << pattern
    end

    patterns.uniq
  end

  # Get ingredients as an array of strings (cleaned up)
  def ingredient_list
    return [] unless ingredients.is_a?(Array)

    ingredients.map do |ingredient|
      # Remove quantities and units, keep just the ingredient name
      # This regex removes numbers, fractions, measurements at the beginning
      cleaned = ingredient.gsub(/^[\d\u{00BC}-\u{00BE}\u{2153}-\u{215E}\/\s]*\s*[\w\s]*\s+/, "").strip
      cleaned.empty? ? ingredient.strip : cleaned
    end
  end
end
