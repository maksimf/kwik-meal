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

end
