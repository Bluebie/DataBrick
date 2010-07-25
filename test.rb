#!/usr/bin/ruby
require 'DataBrick'

class CatPeople < DataBrick
  define_piece :next, :pointer
  define_piece :friend, :string
  define_piece :cat, :string
end

# And here's how you'd use that to make a little database:
people = ["Bluebie", "Radar",     "Judofyr's Sister", "Steve K.", "Steve K.", "Elliott"]
pets   = ["Phoenix", "Mr. Purrr", "Sibelius",         "Scuzzy",   "Lady",     "Tucker (actually a dog)"]
database = File.open('cats.db', 'w+')
database.sync = true

last = false; # make this variable stay out here so it lasts forever!
people.each_with_index do |person, index|
  database.seek 0, File::SEEK_END # go to end of file to add new catperson
  cat = CatPeople.create({
          :friend => person,
          :cat => pets[index]
        }, database)
  last.next = cat if last # link it up!
  last = cat
end

# So that program put all your cat people in to the file, now in
# another program we can read it like this!
catman = CatPeople.new(open('cats.db'))
until catman == nil
  puts "#{catman.friend} has a cat: #{catman.cat}."
  catman = catman.next
end

