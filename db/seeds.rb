# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require 'json'

puts "Starting to seed recipes data..."

# Load recipes from JSON file
recipes_file = Rails.root.join('data', 'recipes-en.json')

unless File.exist?(recipes_file)
  puts "Error: #{recipes_file} not found!"
  exit 1
end

puts "Loading recipes from #{recipes_file}..."
recipes_data = JSON.parse(File.read(recipes_file))

puts "Found #{recipes_data.length} recipes to process"

# Clear existing recipes
puts "Clearing existing recipes..."
Recipe.delete_all

# Batch process for better performance
batch_size = 1000
total_batches = (recipes_data.length.to_f / batch_size).ceil
processed = 0
failed = 0

puts "Processing in batches of #{batch_size}..."

recipes_data.each_slice(batch_size).with_index do |batch, batch_index|
  puts "Processing batch #{batch_index + 1}/#{total_batches} (records #{processed + 1}-#{[processed + batch_size, recipes_data.length].min})"

  recipes_to_insert = []

  batch.each do |recipe_data|
    begin
      # Validate required fields
      next if recipe_data['title'].blank? || recipe_data['ingredients'].blank?

      recipes_to_insert << {
        title: recipe_data['title'],
        cook_time: recipe_data['cook_time'],
        prep_time: recipe_data['prep_time'],
        ingredients: recipe_data['ingredients'].to_json, # Store as JSON string
        ratings: recipe_data['ratings'],
        cuisine: recipe_data['cuisine'],
        category: recipe_data['category'],
        author: recipe_data['author'],
        image: recipe_data['image'],
        created_at: Time.current,
        updated_at: Time.current
      }
    rescue => e
      puts "  Failed to process recipe: #{recipe_data['title']} - #{e.message}"
      failed += 1
    end
  end

  # Bulk insert the batch
  if recipes_to_insert.any?
    Recipe.insert_all(recipes_to_insert)
    processed += recipes_to_insert.length
  end

  # Show progress
  progress = ((batch_index + 1).to_f / total_batches * 100).round(1)
  puts "  Progress: #{progress}% (#{processed} processed, #{failed} failed)"
end

puts "\nSeeding completed!"
puts "Successfully processed: #{processed} recipes"
puts "Failed: #{failed} recipes"
puts "Total recipes in database: #{Recipe.count}"

# Show some sample data
puts "\nSample recipes:"
Recipe.limit(3).each do |recipe|
  puts "- #{recipe.title} (#{recipe.category}) - Rating: #{recipe.ratings}"
end
