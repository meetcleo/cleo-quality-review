# frozen_string_literal: true

source "https://rubygems.org"

gemspec

if ENV['RUBY_VERSION']
  ruby ENV['RUBY_VERSION']
else
  ruby file: "./.ruby-version"
end

group :development, :test do
  gem "debug", "~> 1.11"
  gem "dotenv", "~> 2.7"
  gem "guard", "~> 2.20"
  gem "guard-minitest", "~> 3.0"
  gem "minitest", "~> 6"
  gem "minitest-rg", "5.4.0"
  gem "rake", "~> 13.0"
  gem "simplecov", "~> 0.22.0"
end
