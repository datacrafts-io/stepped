lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "stepped/version"

Gem::Specification.new do |gem|
  gem.name          = "stepped"
  gem.version       = Stepped::VERSION
  gem.authors       = ["Datacrafts", "Alexey Melnikov"]
  gem.email         = ["alexbeat96@gmail.com"]

  gem.summary       = "Make your services stepped"
  gem.description   = <<~TEXT
    Adds ability to use steps in services with error handling,
    logging and easy testing.
  TEXT

  gem.homepage      = "https://github.com/datacrafts-io/stepped"
  gem.license       = "MIT"
  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)

  gem.required_ruby_version = ">= 2.5"
  gem.require_paths = %w[lib]

  gem.add_development_dependency "bundler", ">= 1.16"
  gem.add_development_dependency "pry"
  gem.add_development_dependency "rake", ">= 10.0"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rubocop"
end
