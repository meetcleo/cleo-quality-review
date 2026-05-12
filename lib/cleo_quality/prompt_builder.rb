# frozen_string_literal: true

require_relative "target_resolver"

module CleoQuality
  class PromptBuilder
    def initialize(run:, prompt:, artifacts:)
      @run = run
      @prompt = prompt
      @artifacts = artifacts
    end

    def build
      [
        prompt,
        metadata_section,
        diff_section,
        check_outputs_section,
        target_files_section,
      ].join("\n\n")
    end

    private

    attr_reader :run, :prompt, :artifacts

    def metadata_section
      <<~MARKDOWN
        ## Run metadata

        Timestamp: #{run.timestamp}
        Checks: #{run.checks.join(", ")}
        Target files: #{run.target_files.empty? ? "(none)" : run.target_files.join(", ")}
      MARKDOWN
    end

    def diff_section
      fenced("Git diff against #{TargetResolver::BASE_REF}", "diff", artifacts.changes_diff)
    end

    def check_outputs_section
      artifacts.raw_check_outputs.map do |check_name, output|
        fenced("Raw #{check_name} output", language_for("raw_output"), output)
      end.join("\n\n")
    end

    def target_files_section
      run.target_files.map do |path|
        fenced("File: #{path}", language_for(path), file_content(path))
      end.join("\n\n")
    end

    def file_content(path)
      File.read(path, invalid: :replace, undef: :replace)
    rescue Errno::ENOENT
      "(file not found)"
    end

    def language_for(path)
      case File.extname(path)
      when ".json"
        "json"
      when ".rb"
        "ruby"
      else
        "text"
      end
    end

    def fenced(title, language, content)
      <<~MARKDOWN
        ## #{title}

        ```#{language}
        #{content}
        ```
      MARKDOWN
    end
  end
end
