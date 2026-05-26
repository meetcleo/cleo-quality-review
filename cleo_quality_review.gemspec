# frozen_string_literal: true

require_relative "lib/cleo_quality_review/version"

Gem::Specification.new do |spec|
  spec.name = "cleo_quality_review"
  spec.version = CleoQualityReview::VERSION
  spec.authors = ["Gavin Morrice"]
  spec.email = ["gavin@gavinmorrice.com"]

  spec.summary = "Local Cleo code quality checks"
  spec.description = "Runs local quality checks and summarizes their output for humans, agents, or GitHub."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files =
    Dir.glob("{#{File.basename(__FILE__)},config/**/*,exe/**/*,lib/**/*,prompts/**/*}", File::FNM_DOTMATCH).select do |path|
      File.file?(path) && !File.symlink?(path)
    end

  spec.bindir = "exe"
  spec.executables = ["check_quality"]
  spec.require_paths = ["lib"]

  spec.add_dependency "debride"
  spec.add_dependency "fasterer"
  spec.add_dependency "flog"
  spec.add_dependency "reek"
end
