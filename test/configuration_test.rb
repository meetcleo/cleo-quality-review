# frozen_string_literal: true

require_relative "test_helper"
require "cleo_quality_review/configuration"

module CleoQualityReview
  class ConfigurationTest < Minitest::Test
    def test_loads_gem_default_config
      in_tmpdir do
        config = Configuration.load

        assert config.target_file?("app/models/user.rb")
        refute config.target_file?("README.md")
        refute config.target_file?("vendor/cleo_quality_review/lib/example.rb")
      end
    end

    def test_local_config_merges_with_default_config
      in_tmpdir do
        File.write(
          ".cleo_quality_review.yaml",
          <<~YAML,
            AllCops:
              Include:
                - "**/*.rake"
              Exclude:
                - "app/generated/**/*"
          YAML
        )

        config = Configuration.load

        assert config.target_file?("app/models/user.rb")
        assert config.target_file?("lib/tasks/import.rake")
        refute config.target_file?("app/generated/user.rb")
      end
    end

    def test_local_config_can_inherit_from_relative_config
      in_tmpdir do
        FileUtils.mkdir_p("config")
        File.write(
          "config/user.yml",
          <<~YAML,
            AllCops:
              Exclude:
                - "app/private/**/*"
          YAML
        )
        File.write(
          ".cleo_quality_review.yaml",
          <<~YAML,
            inherit_from: config/user.yml

            AllCops:
              Include:
                - "**/*.rake"
          YAML
        )

        config = Configuration.load

        assert config.target_file?("app/models/user.rb")
        assert config.target_file?("lib/tasks/import.rake")
        refute config.target_file?("app/private/token.rb")
      end
    end

    def test_inherit_from_expands_user_home_paths
      original_home = ENV.fetch("HOME", nil)

      in_tmpdir do |dir|
        home = File.join(dir, "home")
        FileUtils.mkdir_p(File.join(home, ".config"))
        File.write(
          File.join(home, ".config", "cleo_quality_review.yml"),
          <<~YAML,
            AllCops:
              Exclude:
                - "app/local/**/*"
          YAML
        )
        File.write(
          ".cleo_quality_review.yaml",
          <<~YAML,
            inherit_from: ~/.config/cleo_quality_review.yml
          YAML
        )

        ENV["HOME"] = home
        config = Configuration.load

        refute config.target_file?("app/local/user.rb")
      end
    ensure
      ENV["HOME"] = original_home
    end

    def test_invalid_config_file_fails
      in_tmpdir do
        File.write(".cleo_quality_review.yaml", "- not-a-mapping\n")

        error = assert_raises(ArgumentError) { Configuration.load }

        assert_includes error.message, "Config file must contain a YAML mapping"
      end
    end

    def test_missing_inherited_config_fails
      in_tmpdir do
        File.write(".cleo_quality_review.yaml", "inherit_from: missing.yml\n")

        error = assert_raises(ArgumentError) { Configuration.load }

        assert_includes error.message, "Config file not found"
      end
    end
  end
end
