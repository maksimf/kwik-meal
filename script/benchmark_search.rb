#!/usr/bin/env ruby
require_relative '../config/environment'
require 'benchmark'

puts "=== Recipe Search Performance Benchmark ==="
puts "Total recipes in database: #{Recipe.count}"
puts "Using pg_search with tsearch and trigram"
puts "=" * 60
puts ""

# Helper method to run benchmark
def benchmark_search(description, search_query, limit = 50)
  times = []
  result_counts = []

  # Warm up query cache
  Recipe.search_by_ingredients(search_query).limit(limit).to_a

  # Run benchmark 10 times
  10.times do
    time = Benchmark.realtime do
      results = Recipe.search_by_ingredients(search_query)
                      .order(ratings: :desc)
                      .limit(limit)
                      .to_a
      result_counts << results.length
    end
    times << (time * 1000).round(2) # Convert to milliseconds
  end

  {
    description: description,
    query: search_query,
    times: times,
    avg_time: (times.sum / times.length).round(2),
    min_time: times.min,
    max_time: times.max,
    median_time: times.sort[times.length / 2],
    result_count: result_counts.first
  }
end

# Test cases for 1-4 ingredients
test_cases = [
  # Single ingredient tests
  { name: "1 ingredient (common)", ingredients: ["flour"] },
  { name: "1 ingredient (specific)", ingredients: ["chocolate"] },
  { name: "1 ingredient (rare)", ingredients: ["saffron"] },
  { name: "1 ingredient (typo)", ingredients: ["chocolat"] },

  # Two ingredients tests
  { name: "2 ingredients (common)", ingredients: ["flour", "sugar"] },
  { name: "2 ingredients (mixed)", ingredients: ["chicken", "rice"] },
  { name: "2 ingredients (specific)", ingredients: ["chocolate", "butter"] },

  # Three ingredients tests
  { name: "3 ingredients (baking)", ingredients: ["flour", "eggs", "sugar"] },
  { name: "3 ingredients (savory)", ingredients: ["beef", "onions", "garlic"] },
  { name: "3 ingredients (mixed)", ingredients: ["chicken", "lemon", "herbs"] },

  # Four ingredients tests
  { name: "4 ingredients (complex)", ingredients: ["flour", "eggs", "milk", "butter"] },
  { name: "4 ingredients (dinner)", ingredients: ["pasta", "tomatoes", "garlic", "basil"] },
  { name: "4 ingredients (specific)", ingredients: ["chocolate", "cream", "vanilla", "sugar"] }
]

results = []

test_cases.each do |test_case|
  search_query = test_case[:ingredients].join(" ")
  result = benchmark_search(test_case[:name], search_query)
  results << result

  puts "📊 #{test_case[:name]}"
  puts "   Query: \"#{search_query}\""
  puts "   Results found: #{result[:result_count]}"
  puts "   Avg time: #{result[:avg_time]}ms"
  puts "   Min/Max: #{result[:min_time]}ms / #{result[:max_time]}ms"
  puts "   Median: #{result[:median_time]}ms"
  puts ""
end

# Summary by number of ingredients
puts "=" * 60
puts "📈 PERFORMANCE SUMMARY BY NUMBER OF INGREDIENTS"
puts "=" * 60
puts ""

[1, 2, 3, 4].each do |num_ingredients|
  ingredient_results = results.select { |r| r[:query].split.length == num_ingredients }

  if ingredient_results.any?
    avg_times = ingredient_results.map { |r| r[:avg_time] }
    overall_avg = (avg_times.sum / avg_times.length).round(2)

    puts "#{num_ingredients} Ingredient(s):"
    ingredient_results.each do |r|
      puts "  • #{r[:description]}: #{r[:avg_time]}ms (#{r[:result_count]} results)"
    end
    puts "  📊 Average across all #{num_ingredients}-ingredient searches: #{overall_avg}ms"
    puts ""
  end
end

# Overall statistics
puts "=" * 60
puts "🎯 OVERALL STATISTICS"
puts "=" * 60
all_times = results.map { |r| r[:avg_time] }
puts "• Total searches benchmarked: #{results.length}"
puts "• Overall average time: #{(all_times.sum / all_times.length).round(2)}ms"
puts "• Fastest search: #{all_times.min}ms"
puts "• Slowest search: #{all_times.max}ms"
puts "• Database size: #{Recipe.count} recipes"
puts ""

# Performance assessment
avg_time = (all_times.sum / all_times.length).round(2)
if avg_time < 50
  puts "✅ Excellent performance! Average search time under 50ms"
elsif avg_time < 100
  puts "✅ Good performance! Average search time under 100ms"
elsif avg_time < 200
  puts "⚠️  Acceptable performance. Consider optimization for larger datasets"
else
  puts "⚠️  Slow performance. Optimization recommended"
end

puts ""
puts "💡 Notes:"
puts "• pg_search uses PostgreSQL's full-text search (tsearch) with prefix matching"
puts "• Trigram search (with threshold 0.2) handles typos and fuzzy matching"
puts "• Results are ordered by rating (descending)"
puts "• Each search was run 10 times after a warm-up query"
