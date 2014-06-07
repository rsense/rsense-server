source 'https://rubygems.org'

# Specify your gem's dependencies in rsense.gemspec
gemspec

gem 'puma', :path => File.join(File.dirname(__FILE__), './vendor/gems/puma-2.8.2-java')

group :linux do
  gem 'libnotify'
end

group :darwin do
  gem 'terminal-notifier-guard'
end
