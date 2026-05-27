# frozen_string_literal: true

require_relative "git_diff_base"

module CleoQualityReview
  ##
  # Builds the complete LLM prompt from run data and artifacts
  class PromptBuilder
    ##
    # @param [Run] run the quality review run
    # @param [String] prompt base prompt template
    # @param [RunArtifacts] artifacts run artifacts containing diffs and outputs
    def initialize(run:, prompt:, artifacts:)
      @run = run
      @prompt = prompt
      @artifacts = artifacts
    end

    ##
    # Build the complete prompt with all sections
    # @return [String]
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
      target_files = run.target_files
      <<~MARKDOWN
        ## Run metadata

        Review ID: #{run.review_id}
        Timestamp: #{run.timestamp}
        Checks: #{run.checks.join(", ")}
        Target files: #{target_files.empty? ? "(none)" : target_files.join(", ")}
      MARKDOWN
    end

    def diff_section
      fenced("Git diff against #{run.base_ref || GitDiffBase::DEFAULT_BASE_REF}", "diff", artifacts.changes_diff)
    end

    def check_outputs_section
      artifacts.raw_check_output_records.map do |record|
        fenced("Raw #{raw_output_title(record)} output", language_for(record.path), record.raw_output)
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

    def raw_output_title(record)
      [record.tool_type, record.check_name].compact.join("/")
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
