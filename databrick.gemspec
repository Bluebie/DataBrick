Gem::Specification.new do |s|
  s.name = 'databrick'
  s.version = '0.2.4'
  s.require_path = '.'
  s.date = '2010-07-25'
  s.summary = "A tiny binary ORM, to save you from pack and unpack heck!"
  s.email = "a@creativepony.com"
  s.homepage = "http://github.com/Bluebie/DataBrick"
  s.description = "Not all things in this world may be blessed with lovely ascii art, json, yaml, and other funky formats. Sometimes you need to get your arms dirty with some raw unadulterated binary! Binary needn't scar you for life though - so here's my little ORM for bits of binary."
  s.author = 'Bluebie'
  s.files = Dir['*.rb'] + ['README']
  s.test_file = 'test.rb'
end
