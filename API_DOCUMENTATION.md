# Kwik Meal Recipe API

A Ruby on Rails API that helps users find recipes based on ingredients they have at home.

## Features

- **Ingredient-based search**: Find recipes using one or more ingredients
- **Advanced typo tolerance**: Handles common spelling mistakes using pattern matching
- **Performance optimized**: Fast search through 10,000+ recipes
- **Rating-based ordering**: Results sorted by recipe ratings (highest first)
- **JSON API**: RESTful endpoints with structured responses

## Tech Stack

- Ruby on Rails 8.0
- PostgreSQL with pg_search gem
- Full-text search with trigram matching

## API Endpoints

### Search Recipes by Ingredients

```
GET /recipes/search?ingredients[]=flour&ingredients[]=eggs&limit=10
```

**Parameters:**

- `ingredients[]` (required): Array of ingredient names (at least 1)
- `limit` (optional): Number of results to return (default: 10, max: 50)

**Example Request:**

```bash
curl "http://localhost:3000/recipes/search?ingredients[]=chocolate&ingredients[]=flour&limit=5"
```

**Example Response:**

```json
{
  "results": [
    {
      "id": 1,
      "title": "Chocolate Chip Cookies",
      "cook_time": 25,
      "prep_time": 15,
      "ingredients": ["flour", "chocolate chips", "butter", "sugar", "eggs"],
      "ratings": 4.8,
      "cuisine": "American",
      "category": "Cookies",
      "author": "Chef John",
      "image": "https://example.com/image.jpg"
    }
  ],
  "search_metadata": {
    "query_ingredients": ["chocolate", "flour"],
    "total_results": 1,
    "search_time_ms": 12.34,
    "limit": 5
  }
}
```

### List All Recipes (Paginated)

```
GET /recipes?page=1&per_page=10
```

**Parameters:**

- `page` (optional): Page number (default: 1)
- `per_page` (optional): Results per page (default: 10, max: 20)

**Example Response:**

```json
{
  "results": [...],
  "pagination": {
    "current_page": 1,
    "per_page": 10,
    "total_pages": 1001,
    "total_count": 10013
  }
}
```

## Setup Instructions

1. **Install dependencies:**

   ```bash
   bundle install
   ```

2. **Create and setup database:**

   ```bash
   rails db:create db:migrate
   ```

3. **Load recipe data:**

   ```bash
   rails db:seed
   ```

   This will load 10,013 recipes from `data/recipes-en.json`

4. **Start the server:**
   ```bash
   rails server
   ```

## Testing

Run the test suite:

```bash
rails test
```

Run performance benchmarks:

```bash
ruby script/benchmark_search.rb
```

## Performance

- **Average search time**: ~250ms across 10,000+ recipes
- **Advanced typo handling**: Handles missing characters, transposed letters, and extra characters
  - `choclat` → finds chocolate recipes (20+ results)
  - `chocolte` → finds chocolate recipes (40+ results)
  - `chcolate` → finds chocolate recipes (20+ results)
- **Database**: Optimized with indexes and pattern matching
- **Memory efficient**: Uses batch processing for data loading

## Data

The application includes a sample dataset of over 10,000 recipes with:

- Recipe titles
- Cooking and preparation times
- Ingredient lists
- Ratings
- Categories and cuisine types
- Author information
- Recipe images

## Example Searches

- **Basic ingredient**: `/recipes/search?ingredients[]=chicken`
- **Multiple ingredients**: `/recipes/search?ingredients[]=flour&ingredients[]=eggs`
- **Typo handling**: `/recipes/search?ingredients[]=choclat` (finds "chocolate" recipes)
- **Limited results**: `/recipes/search?ingredients[]=beef&limit=5`
