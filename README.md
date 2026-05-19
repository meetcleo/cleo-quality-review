# Cleo Quality Review

Local quality checks for Cleo repositories.

## Usage

```bash
bundle exec check_quality --format agent --checks reek --files vendor/cleo_quality_review/lib
bundle exec check_quality --format github --checks fasterer --files app/services/my_area
OPEN_AI_API_KEY=... bundle exec check_quality --format human --files app/models/example.rb
```

`--files` accepts files or directories. Directories are expanded recursively, then filtered by the active config. When `--files` is omitted, `check_quality` targets changed files from `origin/main...HEAD` that match the active config.

## Checks

The gem embeds Ruby check adapters for Reek, Flog, and Fasterer. Each run writes raw tool artifacts to `tmp/quality_checks/<epoch>/<check>/raw_output.*` and also normalizes findings for machine-readable output.

`agent` output prints one JSON document containing run metadata, the git diff, all raw tool outputs, format instructions, and normalized findings.

`github` output prints GitHub workflow annotation commands for normalized findings, followed by a notice summarizing the top actionable issues when findings are present. Configure the summary count with `CLEO_QUALITY_REVIEW_GITHUB_SUMMARY_LIMIT`.

## Prompts

Prompts are format-specific:

- `human`
- `agent`
- `github`

Local overrides are loaded first from `.cleo_quality_review/prompts/<format>.md`, then `.cleo_quality_review/<format>.md`. For backwards compatibility, `human` also supports `.cleo_quality_review/prompt.md`. If no local prompt exists, the gem uses `vendor/cleo_quality_review/prompts/<format>.md`.

## File Configuration

Target files are configured with YAML. The gem always loads its default config, then optionally loads `.cleo_quality_review.yaml` from the repository root.

```yaml
inherit_from:
  - ~/.config/cleo_quality_review.yml

AllTools:
  Include:
    - "**/*.rb"
    - "**/*.rake"
  Exclude:
    - "vendor/**/*"
    - "db/schema.rb"
```

`inherit_from` accepts a string or list of config files. Relative paths are resolved from the config file that declares them, and `~` can be used for user-level preferences. The special values `default` and `gem:default` point at the gem's bundled default config.

## LLM Configuration

Human output uses a configurable LLM provider.

### OpenAI Provider (Default)

OpenAI uses the Responses API through a direct HTTPS request. By default the gem reads `OPEN_AI_API_KEY` and uses `gpt-5.5`.

Override the API key env var name with `CLEO_QUALITY_REVIEW_OPENAI_API_KEY_ENV`.
Override the model with `CLEO_QUALITY_REVIEW_OPENAI_MODEL`.

### Custom Providers

Register custom LLM providers in your application:

```ruby
# In your application setup
require "cleo_quality_review"

CleoQualityReview::LlmProviderRegistry.register(:my_provider, MyCustomProvider.new)
```

Then set `CLEO_QUALITY_REVIEW_LLM_PROVIDER=my_provider`.

Your provider class must implement:
- `validate_config(config)` - raises `MissingLlmConfigurationError` if misconfigured
- `build_client(config:, command_runner:)` - returns an object with `generate_review(prompt)`
