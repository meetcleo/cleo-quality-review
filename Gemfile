# frozen_string_literal: true

source "https://rubygems.org"

gemspec

if ENV['RUBY_VERSION']
  ruby ENV['RUBY_VERSION']
else
  ruby file: "./.ruby-version"
end

group :development, :test do
  gem "dotenv", "~> 2.7"
  gem "minitest", "~> 6"
  gem "rake", "~> 13.0"
end

gem "debug", "~> 1.11"
