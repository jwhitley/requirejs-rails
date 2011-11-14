$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "requirejs/rails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "requirejs-rails"
  s.version     = Requirejs::Rails::VERSION
  s.authors     = ["John Whitley"]
  s.email       = ["whitley@bangpath.org"]
  s.homepage    = "http://github.com/jwhitley/requirejs-rails"
  s.summary     = "Use RequireJS with the Rails 3 Asset Pipeline"
  s.description = "This gem provides RequireJS and r.js compilation support for your Rails 3 application."

  git_files = `git ls-files`.split("\n").partition { |f| f =~ /^test/ }
  s.test_files = git_files[0]
  s.files = git_files[1]
  s.require_path = 'lib'  

  s.add_dependency "rails", "~> 3.1.1"

  s.add_development_dependency "sqlite3"
end
